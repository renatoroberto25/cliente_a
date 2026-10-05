#!/usr/bin/env python3
"""Gera o one-page manual de hardening a partir do STATUS BASELINES XLSX."""

from __future__ import annotations

import argparse
import html
import re
from collections import Counter
from datetime import datetime
from pathlib import Path
from xml.etree import ElementTree as ET
from zipfile import BadZipFile, ZipFile


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
TEAM_NAMES = {
    "CLARO-TI": "Claro TI",
    "BCC": "BCC",
    "STAR-ONE": "StarOne",
    "ENG-VIDEO": "Engenharia Vídeo",
}
STATUS_ALIASES = {
    "criado": "Criado",
    "em andamento": "Em andamento",
    "não criado": "Não criado",
    "nao criado": "Não criado",
    "não avaliado": "Não avaliado",
    "nao avaliado": "Não avaliado",
    "não aplicável": "Não aplicável",
    "nao aplicavel": "Não aplicável",
}


def clean(value: object) -> str:
    return " ".join(str(value or "").strip().split())


def as_int(value: object) -> int:
    try:
        return int(float(clean(value).replace(",", ".")))
    except ValueError:
        return 0


def number(value: int) -> str:
    return f"{value:,}".replace(",", ".")


def percent(value: int, total: int) -> str:
    return f"{(100 * value / total if total else 0):.1f}%".replace(".", ",")


def status_of(row: dict[str, str]) -> str:
    raw = clean(row.get("status", ""))
    return STATUS_ALIASES.get(raw.casefold(), raw or "Não avaliado")


def column_index(reference: str) -> int:
    match = re.match(r"[A-Z]+", reference.upper())
    if not match:
        raise ValueError(f"Referência de célula inválida: {reference}")
    result = 0
    for char in match.group(0):
        result = result * 26 + ord(char) - 64
    return result - 1


def shared_strings(archive: ZipFile) -> list[str]:
    try:
        root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    except KeyError:
        return []
    return [
        "".join(node.text or "" for node in item.iter(f"{{{MAIN_NS}}}t"))
        for item in root.findall(f"{{{MAIN_NS}}}si")
    ]


def cell_value(cell: ET.Element, strings: list[str]) -> str:
    if cell.get("t") == "inlineStr":
        return "".join(node.text or "" for node in cell.iter(f"{{{MAIN_NS}}}t"))
    value = cell.find(f"{{{MAIN_NS}}}v")
    raw = "" if value is None else value.text or ""
    if cell.get("t") == "s" and raw:
        return strings[int(raw)]
    return raw


def read_workbook(path: Path) -> list[dict[str, str]]:
    """Lê todas as abas de equipe usando somente a biblioteca padrão."""
    try:
        with ZipFile(path) as archive:
            strings = shared_strings(archive)
            workbook = ET.fromstring(archive.read("xl/workbook.xml"))
            relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
            relation_paths = {
                node.get("Id"): node.get("Target", "")
                for node in relationships.findall(f"{{{PKG_REL_NS}}}Relationship")
            }
            sheets = workbook.findall(f".//{{{MAIN_NS}}}sheet")
            selected = [sheet for sheet in sheets if sheet.get("name") in TEAM_NAMES]
            if not selected:
                raise ValueError("Nenhuma aba de equipe reconhecida foi encontrada")

            result: list[dict[str, str]] = []
            for sheet in selected:
                sheet_name = sheet.get("name", "")
                relation_id = sheet.get(f"{{{REL_NS}}}id")
                target = relation_paths.get(relation_id, "")
                target = target.lstrip("/") if target.startswith("/") else "xl/" + target.removeprefix("../")
                root = ET.fromstring(archive.read(target))
                table: list[list[str]] = []
                for row in root.findall(f".//{{{MAIN_NS}}}sheetData/{{{MAIN_NS}}}row"):
                    values: dict[int, str] = {}
                    for cell in row.findall(f"{{{MAIN_NS}}}c"):
                        values[column_index(cell.get("r", "A1"))] = clean(cell_value(cell, strings))
                    if values:
                        table.append([values.get(i, "") for i in range(max(values) + 1)])
                if not table:
                    continue
                headers = [clean(value) for value in table[0]]
                required = {"dominio", "perfil", "ativos", "em_uso", "producao", "status"}
                missing = required - set(headers)
                if missing:
                    raise ValueError(
                        f"Aba {sheet_name}: colunas ausentes: {', '.join(sorted(missing))}"
                    )
                for values in table[1:]:
                    row = {
                        header: clean(values[index] if index < len(values) else "")
                        for index, header in enumerate(headers)
                        if header
                    }
                    if any(row.values()):
                        row["_equipe"] = TEAM_NAMES[sheet_name]
                        result.append(row)
            return result
    except (BadZipFile, KeyError, ET.ParseError) as error:
        raise ValueError(f"XLSX inválido ou incompleto: {error}") from error


def catalog(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    """Um baseline por perfil, sem multiplicar pelas equipes."""
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        if row.get("dominio") not in {"Linux", "Windows"}:
            continue
        key = row.get("chave") or "|".join(
            row.get(field, "") for field in ("dominio", "familia", "versao")
        )
        result.setdefault(key, row)
    return result


def summarize_team(
    rows: list[dict[str, str]], team: str, domain: str | None = None
) -> Counter:
    selected = [
        row for row in rows
        if row.get("_equipe") == team
        and row.get("dominio") in {"Linux", "Windows"}
        and (domain is None or row.get("dominio") == domain)
    ]
    result = Counter()
    for row in selected:
        assets = as_int(row.get("ativos"))
        active = as_int(row.get("em_uso"))
        result["inventory"] += assets
        result["active"] += active
        if status_of(row) == "Criado":
            result["eligible"] += active
            result["auditable"] += as_int(row.get("com_agent"))
    return result


def render(rows: list[dict[str, str]], source: Path) -> str:
    profiles = catalog(rows)
    statuses = Counter(status_of(row) for row in profiles.values())
    created = statuses["Criado"]
    created_by_domain = Counter(
        row.get("dominio") for row in profiles.values() if status_of(row) == "Criado"
    )
    linux_created = created_by_domain["Linux"]
    windows_created = created_by_domain["Windows"]
    linux_share = 100 * linux_created / created if created else 0
    teams = list(TEAM_NAMES.values())
    summaries = {team: summarize_team(rows, team) for team in teams}
    total_active = sum(item["active"] for item in summaries.values())
    total_eligible = sum(item["eligible"] for item in summaries.values())
    total_auditable = sum(item["auditable"] for item in summaries.values())
    readiness_gap = max(total_eligible - total_auditable, 0)
    team_rows_parts: list[str] = []
    for index, (team, item) in enumerate(summaries.items()):
        detail_id = f"area-{index}"
        team_rows_parts.append(
        f"<tr class='area-row' tabindex='0' role='button' aria-expanded='false' aria-controls='{detail_id}'>"
        f"<td><span class='chevron' aria-hidden='true'>›</span><strong>{html.escape(team)}</strong></td>"
        f"<td>{number(item['active'])}</td>"
        f"<td>{number(item['eligible'])}</td>"
        f"<td class='ok'>{number(item['auditable'])}</td>"
        f"<td class='bad'>{number(max(item['eligible'] - item['auditable'], 0))}</td>"
        f"<td>{percent(item['auditable'], item['eligible'])}</td>"
        "</tr>"
        )
        for domain in ("Linux", "Windows"):
            detail = summarize_team(rows, team, domain)
            team_rows_parts.append(
                f"<tr id='{detail_id}-{domain.lower()}' class='detail-row' data-parent='{detail_id}'>"
                f"<td><span class='os-label'>{domain}</span></td>"
                f"<td>{number(detail['active'])}</td>"
                f"<td>{number(detail['eligible'])}</td>"
                f"<td class='ok'>{number(detail['auditable'])}</td>"
                f"<td class='bad'>{number(max(detail['eligible'] - detail['auditable'], 0))}</td>"
                f"<td>{percent(detail['auditable'], detail['eligible'])}</td>"
                "</tr>"
            )
    team_rows = "".join(team_rows_parts)
    generated = datetime.now().astimezone().strftime("%d/%m/%Y %H:%M")
    return f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>One-page Hardening · CMDB manual</title><style>
:root{{--red:#d71920;--dark:#242424;--line:#e2e2e2;--muted:#6b6b6b}}
*{{box-sizing:border-box}}body{{margin:0;background:#f5f5f5;color:var(--dark);font:14px/1.4 Arial,sans-serif}}
main{{width:min(1120px,95vw);margin:24px auto;background:#fff;border-top:7px solid var(--red);padding:26px 30px;box-shadow:0 2px 10px #00000018}}
h1{{margin:0;color:var(--dark);font-size:28px}}.sub{{color:var(--muted);margin:5px 0 22px}}
.cards{{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}}.card{{border:1px solid var(--line);border-radius:7px;padding:15px}}
.card span{{display:block;color:var(--muted);font-size:12px}}.card strong{{display:block;font-size:27px;margin-top:3px}}
.baseline-card{{display:flex;align-items:center;gap:14px;padding:11px 15px}}.donut{{width:76px;height:76px;flex:0 0 76px;border-radius:50%;position:relative;background:conic-gradient(#d71920 0 {linux_share:.2f}%,#555 {linux_share:.2f}% 100%)}}
.donut::after{{content:"";position:absolute;inset:13px;background:#fff;border-radius:50%}}.donut-total{{position:absolute;inset:0;z-index:1;display:grid!important;place-items:center;color:var(--dark)!important;font-size:22px!important;font-weight:bold}}
.donut-copy{{min-width:0}}.donut-title{{font-weight:bold;color:var(--dark)!important;margin-bottom:7px}}.legend{{display:flex;flex-direction:column;gap:3px;color:var(--muted);font-size:11px}}.legend i{{display:inline-block;width:8px;height:8px;border-radius:50%;margin-right:5px}}.linux{{background:#d71920}}.windows{{background:#555}}
.highlight{{background:#fff4f4;border-color:var(--red)}}.highlight strong,.ok,.bad{{color:var(--red)}}
h2{{font-size:17px;color:var(--dark);margin:25px 0 9px}}table{{border-collapse:collapse;width:100%}}th,td{{padding:9px;border-bottom:1px solid var(--line);text-align:right}}
th{{background:#f3f3f3;border-top:2px solid var(--red);font-size:11px;text-transform:uppercase}}th:first-child,td:first-child{{text-align:left}}
.area-row{{cursor:pointer}}.area-row:hover,.area-row:focus{{background:#fff7f7;outline:none}}.chevron{{display:inline-block;width:18px;color:var(--red);font-size:20px;line-height:12px;transition:transform .2s}}.area-row[aria-expanded="true"] .chevron{{transform:rotate(90deg)}}
.detail-row{{display:none;background:#fafafa;color:#555}}.detail-row.open{{display:table-row}}.detail-row td{{padding-top:7px;padding-bottom:7px}}.os-label{{padding-left:26px!important;color:#555!important;font-size:12px!important}}
.note{{margin-top:18px;padding:11px 13px;background:#fff7f7;color:#4e4e4e;border-left:4px solid var(--red)}}
footer{{color:var(--muted);font-size:11px;margin-top:18px}}@media(max-width:700px){{.cards{{grid-template-columns:1fr 1fr}}main{{padding:20px 15px}}.baseline-card{{grid-column:span 2}}}}
</style></head><body><main>
<h1>Hardening · capacidade entregue e adoção</h1><p class="sub">Visão executiva dos assets informados pelas equipes · fonte manual/Jira</p>
<section class="cards">
<div class="card baseline-card"><div class="donut" role="img" aria-label="{number(created)} baselines: {number(linux_created)} Linux e {number(windows_created)} Windows"><span class="donut-total">{number(created)}</span></div><div class="donut-copy"><span class="donut-title">Baselines por S/O</span><div class="legend"><span><i class="linux"></i>Linux · {number(linux_created)}</span><span><i class="windows"></i>Windows · {number(windows_created)}</span></div></div></div>
<div class="card"><span>Assets totais</span><strong>{number(total_active)}</strong></div>
<div class="card"><span>Elegíveis para hardening</span><strong>{number(total_eligible)}</strong></div>
<div class="card highlight"><span>Com agent</span><strong>{number(total_auditable)}</strong></div>
</section>
<h2>Cobertura por área</h2><table><thead><tr><th>Área</th><th>Assets por área</th><th>Elegíveis</th><th>Com agent</th><th>Sem agent</th><th>% agent x elegíveis</th></tr></thead><tbody>{team_rows}</tbody></table>
<div class="note"><strong>Leitura executiva:</strong> a capacidade de hardening foi entregue com {number(created)} baselines ({number(linux_created)} Linux e {number(windows_created)} Windows). Dos assets informados, {number(total_eligible)} servidores possuem perfil atendido e {number(total_auditable)} estão com agent ({percent(total_auditable, total_eligible)} dos elegíveis). O próximo foco é a habilitação dos {number(readiness_gap)} servidores sem agent.</div>
<footer>Fonte: {html.escape(source.name)} · gerado em {generated}</footer>
</main><script>
document.querySelectorAll('.area-row').forEach(row => {{
  const toggle = () => {{
    const open = row.getAttribute('aria-expanded') !== 'true';
    row.setAttribute('aria-expanded', String(open));
    document.querySelectorAll(`[data-parent="${{row.getAttribute('aria-controls')}}"]`).forEach(detail => detail.classList.toggle('open', open));
  }};
  row.addEventListener('click', toggle);
  row.addEventListener('keydown', event => {{ if (event.key === 'Enter' || event.key === ' ') {{ event.preventDefault(); toggle(); }} }});
}});
</script></body></html>"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gera o one-page manual usando a planilha STATUS BASELINES."
    )
    parser.add_argument("planilha", type=Path, help="XLSX manual/Jira")
    parser.add_argument(
        "-o", "--saida", type=Path, default=Path("one_page_manual.html"),
        help="HTML de saída (padrão: one_page_manual.html)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.planilha.is_file():
        raise SystemExit(f"Planilha não encontrada: {args.planilha}")
    try:
        rows = read_workbook(args.planilha)
    except ValueError as error:
        raise SystemExit(f"Erro: {error}") from error
    args.saida.write_text(render(rows, args.planilha), encoding="utf-8")
    profiles = catalog(rows)
    created = sum(status_of(row) == "Criado" for row in profiles.values())
    print(f"{args.saida}: {created} baselines criados; {len(TEAM_NAMES)} equipes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
