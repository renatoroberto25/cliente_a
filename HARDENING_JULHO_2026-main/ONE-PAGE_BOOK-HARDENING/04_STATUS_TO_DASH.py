#!/usr/bin/env python3
"""Gera um dashboard executivo a partir do status dos baselines."""

from __future__ import annotations

import argparse
import csv
import html
import re
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from xml.etree import ElementTree
from zoneinfo import ZoneInfo
from zipfile import BadZipFile, ZipFile, is_zipfile


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


STATUS_COLORS = {
    "Criado": "#27753c",
    "Em andamento": "#b37a00",
    "Não criado": "#b34b1f",
    "Não avaliado": "#77838f",
    "Não aplicável": "#526579",
    "Revisar CMDB": "#79528e",
}
STATUS_ORDER = (
    "Criado",
    "Em andamento",
    "Não criado",
    "Não avaliado",
    "Revisar CMDB",
    "Não aplicável",
)
APPLICABLE_STATUS_ORDER = tuple(
    status for status in STATUS_ORDER if status != "Não aplicável"
)
STATUS_ALIASES = {
    "": "Não avaliado",
    "criado": "Criado",
    "em andamento": "Em andamento",
    "não criado": "Não criado",
    "nao criado": "Não criado",
    "não avaliado": "Não avaliado",
    "nao avaliado": "Não avaliado",
    "não aplicável": "Não aplicável",
    "nao aplicavel": "Não aplicável",
    "revisar cmdb": "Revisar CMDB",
}


def format_number(value: int) -> str:
    return f"{value:,}".replace(",", ".")


def format_percent(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "0%"
    return (
        f"{numerator / denominator * 100:.1f}"
        .replace(".", ",")
        .rstrip("0")
        .rstrip(",")
        + "%"
    )


def as_int(value: str) -> int:
    try:
        return int(value.strip())
    except (AttributeError, ValueError):
        return 0


def status_of(row: dict[str, str]) -> str:
    value = str(row.get("status", "")).strip()
    return STATUS_ALIASES.get(value.casefold(), value or "Não avaliado")


def validate_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    required = {
        "dominio",
        "familia",
        "perfil",
        "ativos",
        "em_uso",
        "producao",
        "status",
    }
    missing = required - set(rows[0] if rows else ())
    if missing:
        raise ValueError(
            f"Coluna(s) obrigatória(s) ausente(s): {', '.join(sorted(missing))}"
        )
    return rows


def read_status_csv(path: Path) -> list[dict[str, str]]:
    raw = path.read_bytes()
    text: str | None = None
    for encoding in ("utf-8-sig", "utf-16", "latin-1"):
        try:
            text = raw.decode(encoding)
            break
        except UnicodeDecodeError:
            continue
    if text is None:
        raise ValueError("Não foi possível identificar a codificação do CSV")

    try:
        dialect = csv.Sniffer().sniff(text[:65536], delimiters=";,")
    except csv.Error:
        dialect = csv.excel
        dialect.delimiter = ";"
    rows = [
        {
            str(key or "").strip(): str(value or "").strip()
            for key, value in row.items()
        }
        for row in csv.DictReader(text.splitlines(), dialect=dialect)
    ]
    return validate_rows(rows)


def column_index(cell_reference: str) -> int:
    letters = re.match(r"[A-Z]+", cell_reference.upper())
    if not letters:
        raise ValueError(f"Referência de célula inválida: {cell_reference}")
    result = 0
    for character in letters.group(0):
        result = result * 26 + ord(character) - ord("A") + 1
    return result - 1


def shared_strings(archive: ZipFile) -> list[str]:
    try:
        root = ElementTree.fromstring(archive.read("xl/sharedStrings.xml"))
    except KeyError:
        return []
    return [
        "".join(node.text or "" for node in item.iter(f"{{{MAIN_NS}}}t"))
        for item in root.findall(f"{{{MAIN_NS}}}si")
    ]


def sheet_path(archive: ZipFile, sheet_name: str | None) -> str:
    workbook = ElementTree.fromstring(archive.read("xl/workbook.xml"))
    sheets = workbook.findall(f".//{{{MAIN_NS}}}sheet")
    if not sheets:
        raise ValueError("O XLSX não possui planilhas")

    relationship_id = None
    if sheet_name is None:
        relationship_id = sheets[0].get(f"{{{REL_NS}}}id")
    else:
        for sheet in sheets:
            if sheet.get("name") == sheet_name:
                relationship_id = sheet.get(f"{{{REL_NS}}}id")
                break
    if not relationship_id:
        available = [sheet.get("name", "") for sheet in sheets]
        raise ValueError(
            f"Planilha '{sheet_name}' não encontrada. Disponíveis: "
            + ", ".join(available)
        )

    relationships = ElementTree.fromstring(
        archive.read("xl/_rels/workbook.xml.rels")
    )
    for relationship in relationships.findall(f"{{{PKG_REL_NS}}}Relationship"):
        if relationship.get("Id") == relationship_id:
            target = relationship.get("Target", "")
            if target.startswith("/"):
                return target.lstrip("/")
            return "xl/" + target.removeprefix("../")
    raise ValueError("Relacionamento da planilha não encontrado no XLSX")


def sheet_names(archive: ZipFile) -> list[str]:
    workbook = ElementTree.fromstring(archive.read("xl/workbook.xml"))
    return [
        sheet.get("name", "")
        for sheet in workbook.findall(f".//{{{MAIN_NS}}}sheet")
        if sheet.get("name")
    ]


def cell_value(cell: ElementTree.Element, strings: list[str]) -> str:
    cell_type = cell.get("t", "")
    if cell_type == "inlineStr":
        return "".join(
            node.text or "" for node in cell.iter(f"{{{MAIN_NS}}}t")
        )
    value = cell.find(f"{{{MAIN_NS}}}v")
    raw = "" if value is None else value.text or ""
    if cell_type == "s" and raw:
        return strings[int(raw)]
    return raw


def read_status_xlsx(
    path: Path, sheet_name: str | None
) -> list[dict[str, str]]:
    try:
        with ZipFile(path) as archive:
            strings = shared_strings(archive)
            selected_sheets = [sheet_name] if sheet_name else sheet_names(archive)
            worksheets = [
                (
                    current_sheet,
                    ElementTree.fromstring(
                        archive.read(sheet_path(archive, current_sheet))
                    ),
                )
                for current_sheet in selected_sheets
            ]
    except (BadZipFile, KeyError, ElementTree.ParseError) as error:
        raise ValueError(f"XLSX inválido ou incompleto: {error}") from error

    rows: list[dict[str, str]] = []
    for current_sheet, worksheet in worksheets:
        table: list[list[str]] = []
        for row in worksheet.findall(
            f".//{{{MAIN_NS}}}sheetData/{{{MAIN_NS}}}row"
        ):
            values: dict[int, str] = {}
            for cell in row.findall(f"{{{MAIN_NS}}}c"):
                values[column_index(cell.get("r", ""))] = cell_value(cell, strings)
            if values:
                table.append(
                    [values.get(index, "") for index in range(max(values) + 1)]
                )
        if not table:
            continue
        headers = [value.strip() for value in table[0]]
        sheet_rows = [
            {
                header: (row[index] if index < len(row) else "").strip()
                for index, header in enumerate(headers)
                if header
            }
            for row in table[1:]
            if any(value.strip() for value in row)
        ]
        validate_rows(sheet_rows)
        for row in sheet_rows:
            row["_equipe"] = current_sheet
        rows.extend(sheet_rows)
    return validate_rows(rows)


def read_status_input(
    path: Path, sheet_name: str | None
) -> list[dict[str, str]]:
    if is_zipfile(path):
        return read_status_xlsx(path, sheet_name)
    if path.suffix.casefold() == ".csv":
        return read_status_csv(path)
    raise ValueError("Formato não suportado. Use CSV ou XLSX")


def exported_at(rows: list[dict[str, str]]) -> str:
    value = next(
        (row.get("exportado_em", "") for row in rows if row.get("exportado_em")),
        "",
    )
    if not value:
        return "Data não informada"
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        local = parsed.astimezone(ZoneInfo("America/Sao_Paulo"))
        return local.strftime("%d/%m/%Y às %H:%M")
    except ValueError:
        return value


def aggregate(
    rows: list[dict[str, str]], fields: tuple[str, ...]
) -> list[dict[str, object]]:
    groups: dict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        key = tuple(row.get(field, "") or "(vazio)" for field in fields)
        groups[key].append(row)

    result = []
    for key, members in groups.items():
        status_counts = Counter(status_of(row) for row in members)
        applicable = [row for row in members if status_of(row) != "Não aplicável"]
        active = sum(as_int(row.get("em_uso", "")) for row in applicable)
        covered = sum(
            as_int(row.get("em_uso", ""))
            for row in applicable
            if status_of(row) == "Criado"
        )
        result.append(
            {
                "key": key,
                "profiles": len(members),
                "created": status_counts["Criado"],
                "in_progress": status_counts["Em andamento"],
                "not_created": status_counts["Não criado"],
                "not_evaluated": status_counts["Não avaliado"],
                "review": status_counts["Revisar CMDB"],
                "not_applicable": status_counts["Não aplicável"],
                "active": active,
                "covered": covered,
                "production": sum(
                    as_int(row.get("producao", "")) for row in members
                ),
            }
        )
    return result


def consolidate_catalog(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    """Consolida o mesmo perfil repetido nas abas das equipes."""
    consolidated: dict[str, dict[str, str]] = {}
    for row in rows:
        key = row.get("chave") or "|".join(
            row.get(field, "") for field in ("dominio", "familia", "perfil")
        )
        if key not in consolidated:
            consolidated[key] = dict(row)
            consolidated[key].pop("_equipe", None)
            continue
        target = consolidated[key]
        for field in ("ativos", "em_uso", "producao", "sox"):
            target[field] = str(as_int(target.get(field, "")) + as_int(row.get(field, "")))
    return list(consolidated.values())


def aggregate_impact(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    """Agrupa por equipe e responsável para medir o gap real de automação.

    O pipeline é: baseline criado -> automação aplica hardening -> requer
    agent instalado no ativo. Por isso o corte aqui não é "sem agent" e
    "sem baseline" pra tanto, é volume de ativos sem agent (o bloqueio que
    a equipe/responsável consegue agir primeiro).
    """
    groups: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        if status_of(row) == "Não aplicável":
            continue
        key = (
            row.get("_equipe", "") or "(sem equipe)",
            row.get("responsavel", "") or "(sem responsável)",
        )
        groups[key].append(row)

    result = []
    for (team, responsible), members in groups.items():
        active = sum(as_int(row.get("em_uso", "")) for row in members)
        with_agent = sum(as_int(row.get("com_agent", "")) for row in members)
        result.append(
            {
                "equipe": team,
                "responsavel": responsible,
                "perfis": len(members),
                "active": active,
                "with_agent": with_agent,
                "without_agent": max(active - with_agent, 0),
            }
        )
    result.sort(key=lambda item: -item["without_agent"])
    return result


def progress_bar(covered: int, total: int, label: str = "") -> str:
    percentage = covered / total * 100 if total else 0
    return (
        '<div class="progress">'
        f'<span style="width:{min(percentage, 100):.2f}%"></span>'
        "</div>"
        f'<small>{html.escape(label or format_percent(covered, total))}</small>'
    )


def render_dashboard(rows: list[dict[str, str]], source: Path) -> str:
    rows = [row for row in rows if row.get("dominio") in {"Linux", "Windows"}]
    catalog = consolidate_catalog(rows)
    applicable = [row for row in catalog if status_of(row) != "Não aplicável"]
    eol_profiles = [row for row in catalog if status_of(row) == "Não aplicável"]
    eol_profiles.sort(
        key=lambda row: (
            row.get("dominio", "").casefold(),
            -as_int(row.get("em_uso", "")),
            row.get("perfil", "").casefold(),
        )
    )
    profile_total = len(applicable)
    profile_created = sum(status_of(row) == "Criado" for row in applicable)
    active_total = sum(as_int(row.get("em_uso", "")) for row in applicable)
    active_covered = sum(
        as_int(row.get("em_uso", ""))
        for row in applicable
        if status_of(row) == "Criado"
    )
    production_total = sum(as_int(row.get("producao", "")) for row in catalog)
    status_counts = Counter(status_of(row) for row in applicable)
    domains = aggregate(applicable, ("dominio",))
    domains.sort(key=lambda item: (0 if item["key"][0] == "Linux" else 1))
    impact = aggregate_impact(rows)[:15]

    status_segments = []
    for status in APPLICABLE_STATUS_ORDER:
        count = status_counts[status]
        if not count:
            continue
        width = count / profile_total * 100 if profile_total else 0
        status_segments.append(
            f'<span title="{html.escape(status)}: {count}" '
            f'style="width:{width:.3f}%;background:{STATUS_COLORS[status]}"></span>'
        )
    legend = "".join(
        f'<span><i style="background:{STATUS_COLORS[status]}"></i>'
        f"{html.escape(status)}: <strong>{status_counts[status]}</strong></span>"
        for status in APPLICABLE_STATUS_ORDER
        if status_counts[status]
    )

    domain_rows = []
    for item in domains:
        domain = str(item["key"][0])
        domain_rows.append(
            "<tr>"
            f"<td><strong>{html.escape(domain)}</strong></td>"
            f'<td class="number">{item["profiles"]}</td>'
            f'<td class="number ok">{item["created"]}</td>'
            f'<td class="number">{item["in_progress"]}</td>'
            f'<td class="number todo">{item["not_created"]}</td>'
            f'<td class="number muted">{item["not_evaluated"]}</td>'
            f'<td class="number">{format_number(int(item["active"]))}</td>'
            f'<td class="coverage-cell">{progress_bar(int(item["covered"]), int(item["active"]))}</td>'
            "</tr>"
        )

    total_status = Counter(status_of(row) for row in applicable)
    domain_rows.append(
        '<tr class="total-row">'
        '<td><strong>Total</strong></td>'
        f'<td class="number"><strong>{profile_total}</strong></td>'
        f'<td class="number ok"><strong>{profile_created}</strong></td>'
        f'<td class="number">{total_status["Em andamento"]}</td>'
        f'<td class="number todo">{total_status["Não criado"]}</td>'
        f'<td class="number muted">{total_status["Não avaliado"]}</td>'
        f'<td class="number"><strong>{format_number(active_total)}</strong></td>'
        f'<td class="coverage-cell">{progress_bar(active_covered, active_total)}</td>'
        '</tr>'
    )

    team_rows = []
    teams = sorted({row.get("_equipe", "") for row in rows if row.get("_equipe")})
    for team in teams:
        team_catalog = [
            row for row in rows
            if row.get("_equipe") == team and status_of(row) != "Não aplicável"
        ]
        team_assets = sum(as_int(row.get("ativos", "")) for row in team_catalog)
        team_active = sum(as_int(row.get("em_uso", "")) for row in team_catalog)
        team_agents = sum(as_int(row.get("com_agent", "")) for row in team_catalog)
        team_scanned = sum(as_int(row.get("escaneados", "")) for row in team_catalog)
        team_not_scanned = sum(
            as_int(row.get("nao_escaneados", "")) for row in team_catalog
        )
        # Elegibilidade: ativos cujo perfil já tem baseline criado (independe de agent).
        team_eligible = sum(
            as_int(row.get("em_uso", ""))
            for row in team_catalog
            if status_of(row) == "Criado"
        )
        team_rows.append(
            "<tr>"
            f"<td><strong>{html.escape(team)}</strong></td>"
            f'<td class="number">{format_number(team_assets)}</td>'
            f'<td class="number">{format_number(team_active)}</td>'
            f'<td class="number">{format_number(team_agents)}</td>'
            f'<td class="number ok">{format_number(team_scanned)}</td>'
            f'<td class="number todo">{format_number(team_not_scanned)}</td>'
            f'<td class="coverage-cell">{progress_bar(team_eligible, team_active)}</td>'
            "</tr>"
        )

    eol_rows = []
    for row in eol_profiles:
        eol_rows.append(
            "<tr>"
            f"<td>{html.escape(row.get('dominio', ''))}</td>"
            f"<td>{html.escape(row.get('familia', ''))}</td>"
            f"<td><strong>{html.escape(row.get('perfil', ''))}</strong></td>"
            f'<td class="number">{format_number(as_int(row.get("ativos", "")))}</td>'
            f'<td class="number">{format_number(as_int(row.get("em_uso", "")))}</td>'
            f'<td class="number">{format_number(as_int(row.get("producao", "")))}</td>'
            '<td><span class="badge" style="color:#526579;border-color:#526579">EOL · Não aplicável</span></td>'
            "</tr>"
        )

    impact_rows = []
    for item in impact:
        impact_rows.append(
            "<tr>"
            f"<td><strong>{html.escape(str(item['equipe']))}</strong></td>"
            f"<td>{html.escape(str(item['responsavel']))}</td>"
            f'<td class="number">{item["perfis"]}</td>'
            f'<td class="number">{format_number(int(item["active"]))}</td>'
            f'<td class="number ok">{format_number(int(item["with_agent"]))}</td>'
            f'<td class="number todo">{format_number(int(item["without_agent"]))}</td>'
            "</tr>"
        )

    return f"""<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Status de baselines</title>
  <style>
    :root {{
      --bg:#f3f5f7;--card:#fff;--text:#17212b;--muted:#687582;
      --line:#d9e0e6;--accent:#185f91;--ok:#27753c;--todo:#b34b1f;
    }}
    *{{box-sizing:border-box}}
    body{{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif}}
    main{{width:min(1320px,95vw);margin:28px auto 50px}}
    h1{{margin:0;font-size:26px}} h2{{margin:0 0 13px;font-size:18px}}
    .subtitle{{margin:4px 0 0;color:var(--muted)}}
    .cards{{display:grid;grid-template-columns:repeat(4,1fr);gap:11px;margin:22px 0}}
    .card,.panel{{background:var(--card);border:1px solid var(--line);border-radius:8px}}
    .card{{padding:16px}} .card span{{display:block;color:var(--muted);font-size:12px}}
    .card strong{{display:block;margin-top:4px;font-size:23px;font-variant-numeric:tabular-nums}}
    .panel{{padding:18px;margin-bottom:15px}}
    .overall{{display:grid;grid-template-columns:180px 1fr;gap:26px;align-items:center}}
    .score{{text-align:center}} .score strong{{display:block;color:var(--accent);font-size:40px;line-height:1}}
    .score span{{display:block;margin-top:7px;color:var(--muted)}}
    .stack{{display:flex;height:14px;overflow:hidden;border-radius:7px;background:#e2e7eb}}
    .stack span{{display:block;height:100%}}
    .legend{{display:flex;flex-wrap:wrap;gap:8px 18px;margin-top:12px;color:var(--muted);font-size:12px}}
    .legend span{{white-space:nowrap}} .legend i{{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:5px}}
    .table-wrap{{overflow:auto}} table{{width:100%;border-collapse:collapse}}
    th,td{{padding:9px 10px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap}}
    th{{color:#43515d;background:#edf1f4;font-size:11px;text-transform:uppercase;letter-spacing:.025em}}
    tr:last-child td{{border-bottom:0}} .number{{text-align:right;font-variant-numeric:tabular-nums}}
    .ok{{color:var(--ok)}} .todo{{color:var(--todo)}} .muted{{color:var(--muted)}}
    .total-row td{{background:#f4f7f9;border-top:2px solid #aeb9c2}}
    .coverage-cell{{min-width:130px}} .progress{{height:7px;overflow:hidden;border-radius:5px;background:#e0e6ea}}
    .progress span{{display:block;height:100%;border-radius:5px;background:var(--ok)}}
    .coverage-cell small{{display:block;margin-top:3px;color:var(--muted);text-align:right}}
    .badge{{display:inline-block;padding:2px 7px;border:1px solid;border-radius:10px;font-size:11px;font-weight:650}}
    details summary{{cursor:pointer;color:var(--accent);font-weight:650}}
    details .table-wrap{{margin-top:14px}}
    footer{{margin-top:17px;color:var(--muted);font-size:12px;text-align:right}}
    @media(max-width:950px){{.cards{{grid-template-columns:repeat(2,1fr)}}.overall{{grid-template-columns:1fr}}}}
    @media(max-width:560px){{.cards{{grid-template-columns:1fr}}}}
  </style>
</head>
<body>
<main>
  <header>
    <h1>Status atual dos baselines</h1>
    <p class="subtitle">Apanhado geral por sistema operacional · posição de {html.escape(exported_at(rows))}</p>
  </header>

  <section class="cards">
    <div class="card"><span>Baselines criados</span><strong>{profile_created}</strong></div>
    <div class="card"><span>Progresso por perfil</span><strong>{format_percent(profile_created, profile_total)}</strong></div>
    <div class="card"><span>Ativos em uso cobertos</span><strong>{format_number(active_covered)}</strong></div>
    <div class="card"><span>Cobertura dos ativos</span><strong>{format_percent(active_covered, active_total)}</strong></div>
  </section>

  <section class="panel overall">
    <div class="score">
      <strong>{format_percent(active_covered, active_total)}</strong>
      <span>{format_number(active_covered)} de {format_number(active_total)} ativos em uso</span>
    </div>
    <div>
      <h2>Distribuição dos {profile_total} perfis aplicáveis</h2>
      <div class="stack">{"".join(status_segments)}</div>
      <div class="legend">{legend}</div>
    </div>
  </section>

  <section class="panel">
    <h2>Progresso Linux e Windows</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Domínio</th><th>Perfis</th><th>Criados</th><th>Em andamento</th><th>Não criados</th><th>Não avaliados</th><th>Ativos em uso</th><th>Cobertura</th></tr></thead>
      <tbody>{"".join(domain_rows)}</tbody>
    </table></div>
  </section>

  <section class="panel">
    <h2>Baselines por equipe</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Equipe</th><th>Inventário</th><th>Em uso</th><th>Com agent</th><th>Escaneado</th><th>Não escaneado</th><th>Elegibilidade (baseline)</th></tr></thead>
      <tbody>{"".join(team_rows)}</tbody>
    </table></div>
  </section>

  <section class="panel">
    <details>
      <summary>Maior impacto pendente · por equipe e responsável</summary>
      <div class="table-wrap"><table>
        <thead><tr><th>Equipe</th><th>Responsável</th><th>Perfis</th><th>Em uso</th><th>Com agent</th><th>Sem agent</th></tr></thead>
        <tbody>{"".join(impact_rows)}</tbody>
      </table></div>
    </details>
  </section>

  <section class="panel">
    <details>
      <summary>PERFIS EOL ({len(eol_profiles)})</summary>
      <div class="table-wrap"><table>
        <thead><tr><th>Domínio</th><th>Família</th><th>Perfil</th><th>Inventário</th><th>Em uso</th><th>Produção</th><th>Tratamento</th></tr></thead>
        <tbody>{"".join(eol_rows)}</tbody>
      </table></div>
    </details>
  </section>

  <footer>
    Fonte: {html.escape(source.name)} · {format_number(production_total)} registros associados a produção
  </footer>
</main>
</body>
</html>
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gera um dashboard executivo do status dos baselines."
    )
    parser.add_argument(
        "arquivo",
        type=Path,
        help="CSV ou XLSX exportado pelo dashboard de gestão de baselines",
    )
    parser.add_argument(
        "-o",
        "--saida",
        type=Path,
        default=Path("dashboard_status_baselines.html"),
        help="HTML de saída (padrão: dashboard_status_baselines.html)",
    )
    parser.add_argument(
        "-s",
        "--planilha",
        help="planilha usada quando a entrada for XLSX (padrão: primeira)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.arquivo.is_file():
        raise SystemExit(f"Arquivo não encontrado: {args.arquivo}")
    try:
        rows = read_status_input(args.arquivo, args.planilha)
    except (ValueError, csv.Error) as error:
        raise SystemExit(f"Erro: {error}") from error
    args.saida.write_text(
        render_dashboard(rows, args.arquivo),
        encoding="utf-8",
    )
    catalog = consolidate_catalog(
        [row for row in rows if row.get("dominio") in {"Linux", "Windows"}]
    )
    applicable = [row for row in catalog if status_of(row) != "Não aplicável"]
    print(
        f"{args.saida}: {len(applicable)} perfis aplicáveis, "
        f"{sum(status_of(row) == 'Criado' for row in applicable)} criados"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
