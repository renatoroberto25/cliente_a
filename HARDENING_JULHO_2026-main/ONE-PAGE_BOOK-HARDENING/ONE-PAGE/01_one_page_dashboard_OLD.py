#!/usr/bin/env python3
"""Gera um one-page estilo painel (donuts + cards + tabelas) a partir do
STATUS BASELINES XLSX. Usa apenas biblioteca padrão (zipfile/ElementTree)."""

from __future__ import annotations

import argparse
import html
import math
import re
from collections import Counter, defaultdict
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
STATUS_COLORS = {
    "Criado": "#2e9e4f",
    "Em andamento": "#e8a33d",
    "Não criado": "#d71920",
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
                required = {"dominio", "familia", "versao", "perfil", "ativos", "em_uso", "status"}
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


def donut_svg(segments: list[tuple[str, int, str]], size: int = 150, hole: float = 0.62) -> str:
    """segments: lista de (rotulo, valor, cor). Retorna um <svg> de donut."""
    total = sum(v for _, v, _ in segments) or 1
    radius = size / 2
    center = size / 2
    inner = radius * hole
    positive_segments = [(label, value, color) for label, value, color in segments if value > 0]
    if len(positive_segments) == 1:
        color = positive_segments[0][2]
        ring_radius = (radius + inner) / 2
        ring_width = radius - inner
        return (
            f'<svg viewBox="0 0 {size} {size}" width="{size}" height="{size}">'
            f'<circle cx="{center:.2f}" cy="{center:.2f}" r="{ring_radius:.2f}" '
            f'fill="none" stroke="{color}" stroke-width="{ring_width:.2f}"/>'
            '</svg>'
        )
    cursor = -90.0
    paths = []
    for _label, value, color in segments:
        if value <= 0:
            continue
        sweep = 360 * value / total
        start, end = math.radians(cursor), math.radians(cursor + sweep)
        x1, y1 = center + radius * math.cos(start), center + radius * math.sin(start)
        x2, y2 = center + radius * math.cos(end), center + radius * math.sin(end)
        ix1, iy1 = center + inner * math.cos(end), center + inner * math.sin(end)
        ix2, iy2 = center + inner * math.cos(start), center + inner * math.sin(start)
        large = 1 if sweep > 180 else 0
        d = (
            f"M{x1:.2f},{y1:.2f} A{radius:.2f},{radius:.2f} 0 {large} 1 {x2:.2f},{y2:.2f} "
            f"L{ix1:.2f},{iy1:.2f} A{inner:.2f},{inner:.2f} 0 {large} 0 {ix2:.2f},{iy2:.2f} Z"
        )
        paths.append(f'<path d="{d}" fill="{color}"/>')
        cursor += sweep
    return f'<svg viewBox="0 0 {size} {size}" width="{size}" height="{size}">{"".join(paths)}</svg>'


def bar_row(label: str, value: int, max_value: int, color: str) -> str:
    width = 100 * value / max_value if max_value else 0
    return (
        '<div class="bar-row">'
        f'<span class="bar-label">{html.escape(label)}</span>'
        f'<div class="bar-track"><div class="bar-fill" style="width:{width:.1f}%;background:{color}"></div></div>'
        f'<span class="bar-value">{number(value)}</span>'
        "</div>"
    )


def catalog(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    """Mantém uma única ocorrência de cada baseline, sem replicar por área."""
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        if row.get("dominio") not in {"Linux", "Windows"}:
            continue
        key = row.get("chave") or "|".join(
            row.get(field, "") for field in ("dominio", "familia", "versao")
        )
        result.setdefault(key, row)
    return result


def render(rows: list[dict[str, str]], source: Path) -> str:
    active_rows = [row for row in rows if row.get("dominio") in {"Linux", "Windows"}]
    reportable_rows = [
        row for row in active_rows if status_of(row) in STATUS_COLORS
    ]
    profiles = catalog(reportable_rows)
    reportable_profiles = list(profiles.values())
    status_counts = Counter(status_of(row) for row in reportable_profiles)
    total_perfis = sum(status_counts.values())
    criado = status_counts["Criado"]
    criado_por_so = Counter(
        row.get("dominio") for row in reportable_profiles if status_of(row) == "Criado"
    )

    # O universo do relatório contém somente ativos em uso.
    total_em_uso = sum(as_int(row.get("em_uso")) for row in active_rows)
    total_elegiveis = sum(
        as_int(row.get("em_uso")) for row in reportable_rows if status_of(row) == "Criado"
    )
    total_agent = sum(as_int(row.get("com_agent")) for row in active_rows)

    status_donut = donut_svg(
        [(name, status_counts.get(name, 0), color) for name, color in STATUS_COLORS.items()]
    )
    delivered_donut = donut_svg(
        [
            ("Linux", criado_por_so["Linux"], "#d71920"),
            ("Windows", criado_por_so["Windows"], "#1f2937"),
        ]
    )

    teams = list(TEAM_NAMES.values())
    team_stats: dict[str, Counter] = defaultdict(Counter)
    for row in active_rows:
        team = row.get("_equipe", "")
        team_stats[team]["ativos"] += as_int(row.get("em_uso"))
        team_stats[team]["agent"] += as_int(row.get("com_agent"))
        if status_of(row) == "Criado":
            team_stats[team]["elegiveis"] += as_int(row.get("em_uso"))

    team_rows = "".join(
        "<tr>"
        f"<td><strong>{html.escape(team)}</strong></td>"
        f"<td>{number(team_stats[team]['ativos'])}</td>"
        f"<td>{number(team_stats[team]['elegiveis'])}</td>"
        f"<td class='ok'>{number(team_stats[team]['agent'])}</td>"
        f"<td class='bad'>{number(max(team_stats[team]['elegiveis'] - team_stats[team]['agent'], 0))}</td>"
        f"<td>{percent(team_stats[team]['agent'], team_stats[team]['elegiveis'])}</td>"
        "</tr>"
        for team in teams
    )

    familia_ativos: Counter = Counter()
    for row in active_rows:
        familia_ativos[f"{row.get('dominio')} · {row.get('familia')}"] += as_int(row.get("em_uso"))
    top_familias = familia_ativos.most_common(8)
    max_familia = top_familias[0][1] if top_familias else 1
    familia_bars = "".join(
        bar_row(nome, valor, max_familia, "#d71920") for nome, valor in top_familias
    )

    status_legend = "".join(
        f'<li><span class="dot" style="background:{color}"></span>{html.escape(name)} '
        f"<strong>{status_counts.get(name, 0)}</strong></li>"
        for name, color in STATUS_COLORS.items()
    )
    so_legend = (
        f'<li><span class="dot" style="background:#d71920"></span>Linux '
        f'<strong>{number(criado_por_so["Linux"])}</strong></li>'
        f'<li><span class="dot" style="background:#1f2937"></span>Windows '
        f'<strong>{number(criado_por_so["Windows"])}</strong></li>'
    )

    generated = datetime.now().astimezone().strftime("%d/%m/%Y %H:%M")
    return f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Painel Hardening · CMDB manual</title><style>
:root{{--red:#d71920;--dark:#242424;--line:#e2e2e2;--muted:#6b6b6b}}
*{{box-sizing:border-box}}body{{margin:0;background:#f5f5f5;color:var(--dark);font:14px/1.4 Arial,sans-serif}}
main{{width:min(1180px,95vw);margin:24px auto;background:#fff;border-top:7px solid var(--red);padding:26px 30px;box-shadow:0 2px 10px #00000018}}
h1{{margin:0;color:var(--dark);font-size:28px}}.sub{{color:var(--muted);margin:5px 0 22px}}
h2{{font-size:17px;color:var(--dark);margin:25px 0 9px}}
.grid{{display:grid;grid-template-columns:1fr 1fr 1.4fr;gap:16px}}
.panel{{border:1px solid var(--line);border-radius:8px;padding:16px;display:flex;flex-direction:column;align-items:center;text-align:center}}
.panel-title{{font-size:12px;color:var(--muted);text-transform:uppercase;margin-bottom:10px}}
.donut-wrap{{position:relative;width:150px;height:150px}}.donut-center{{position:absolute;inset:0;display:grid;place-items:center;font-size:25px;font-weight:bold}}
.legend{{list-style:none;padding:0;margin:12px 0 0;text-align:left;width:100%}}
.legend li{{display:flex;align-items:center;gap:8px;padding:3px 0;font-size:13px}}
.legend li strong{{margin-left:auto}}
.dot{{width:10px;height:10px;border-radius:50%;display:inline-block}}
.cards{{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:16px}}
.card{{border:1px solid var(--line);border-radius:7px;padding:15px}}
.card span{{display:block;color:var(--muted);font-size:12px}}.card strong{{display:block;font-size:27px;margin-top:3px}}
.highlight{{background:#fff4f4;border-color:var(--red)}}.highlight strong{{color:var(--red)}}
table{{border-collapse:collapse;width:100%}}th,td{{padding:9px;border-bottom:1px solid var(--line);text-align:right}}
th{{background:#f3f3f3;border-top:2px solid var(--red);font-size:11px;text-transform:uppercase}}
th:first-child,td:first-child{{text-align:left}}.ok{{color:#2e9e4f}}.bad{{color:var(--red)}}
.bar-row{{display:grid;grid-template-columns:180px 1fr 60px;align-items:center;gap:8px;margin:6px 0;font-size:13px}}
.bar-track{{background:#f0f0f0;border-radius:4px;height:10px;overflow:hidden}}
.bar-fill{{height:100%;border-radius:4px}}
.bar-value{{text-align:right;color:var(--muted)}}
.note{{margin-top:18px;padding:11px 13px;background:#fff7f7;color:#4e4e4e;border-left:4px solid var(--red)}}
footer{{color:var(--muted);font-size:11px;margin-top:18px}}
@media(max-width:820px){{.grid{{grid-template-columns:1fr}}.cards{{grid-template-columns:1fr 1fr}}}}
</style></head><body><main>
<h1>Hardening · painel executivo</h1><p class="sub">Visão dos perfis e assets informados pelas áreas · fonte manual/Jira</p>

<div class="grid">
  <div class="panel">
    <span class="panel-title">Baselines entregues por S/O</span>
    <div class="donut-wrap">{delivered_donut}<strong class="donut-center">{number(criado)}</strong></div>
    <ul class="legend">{so_legend}</ul>
  </div>
  <div class="panel">
    <span class="panel-title">Perfis por status</span>
    {status_donut}
    <ul class="legend">{status_legend}</ul>
  </div>
  <div class="panel" style="align-items:stretch;text-align:left">
    <span class="panel-title" style="text-align:center">Top famílias por ativos</span>
    {familia_bars}
  </div>
</div>

<section class="cards">
<div class="card"><span>Ativos totais</span><strong>{number(total_em_uso)}</strong></div>
<div class="card"><span>Elegíveis</span><strong>{number(total_elegiveis)}</strong></div>
<div class="card highlight"><span>Ativos com agent</span><strong>{number(total_agent)}</strong></div>
</section>

<h2>Cobertura por área</h2>
<table><thead><tr><th>Área</th><th>Ativos</th><th>Elegíveis</th><th>Com agent</th><th>Sem agent</th><th>% agent x elegíveis</th></tr></thead>
<tbody>{team_rows}</tbody></table>

<div class="note"><strong>Leitura executiva:</strong> {number(criado)} baselines foram entregues ({number(criado_por_so['Linux'])} Linux e {number(criado_por_so['Windows'])} Windows). Dos {number(total_em_uso)} ativos considerados, {number(total_elegiveis)} são elegíveis e {number(total_agent)} estão com agent ({percent(total_agent, total_elegiveis)} dos elegíveis).</div>
<footer>Fonte: {html.escape(source.name)} · gerado em {generated} · valores de não conformidade (Critical/High/Medium/Low) não constam na planilha de origem</footer>
</main></body></html>"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gera painel one-page (donuts+cards+tabela) a partir do STATUS BASELINES."
    )
    parser.add_argument("planilha", type=Path, help="XLSX manual/Jira")
    parser.add_argument(
        "-o", "--saida", type=Path, default=Path("one_page_dashboard.html"),
        help="HTML de saída (padrão: one_page_dashboard.html)",
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
    print(f"{args.saida}: painel gerado com {len(rows)} linhas de {len(TEAM_NAMES)} equipes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
