#!/usr/bin/env python3
"""Gera dashboard HTML autocontido a partir dos logs do executor."""

from __future__ import annotations

import argparse
import html
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


CONTROL_RE = re.compile(r"^(\d+),([^,]+),(Alta|Média|Baixa),(PASS|FAIL|NA)$")
FILE_RE = re.compile(
    r"audit-(?:(pre|post)-)?(.+)-(\d{8})-(\d{6})\.log$", re.IGNORECASE
)
SEVERITIES = ("Alta", "Média", "Baixa", "Não informada")
WEIGHTS = {"Alta": 3, "Média": 2, "Baixa": 1, "Não informada": 1}


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def pct(value: float) -> str:
    return f"{value:.1f}%".replace(".", ",")


def parse_log(path: Path) -> dict:
    host = ""
    operating_system = "Não informado"
    controls: dict[str, dict[str, str]] = {}
    with path.open(encoding="utf-8", errors="replace") as source:
        for line in source:
            line = line.strip()
            if line.startswith("Host :"):
                host = line.partition(":")[2].strip()
            elif line.startswith("SO   :"):
                operating_system = line.partition(":")[2].strip()
            match = CONTROL_RE.match(line)
            if match:
                control_id, name, severity, result = match.groups()
                controls[control_id] = {
                    "id": control_id,
                    "name": name,
                    "severity": severity,
                    "classification": "Não informada",
                    "result": result,
                }

    match = FILE_RE.match(path.name)
    kind = match.group(1).lower() if match and match.group(1) else "audit"
    stamp = "".join(match.group(3, 4)) if match else ""
    if not host and match:
        host = match.group(2)
    return {
        "path": path,
        "host": host,
        "os": operating_system,
        "kind": kind,
        "stamp": stamp,
        "controls": controls,
    }


def find_logs(source: Path) -> list[Path]:
    if source.is_file():
        return [source]
    if source.is_dir():
        return sorted(source.glob("audit-*.log"))
    raise ValueError(f"Entrada não encontrada: {source}")


def latest_per_host(runs: list[dict]) -> list[dict]:
    latest: dict[str, dict] = {}
    priority = {"pre": 0, "audit": 1, "post": 2}
    for run in runs:
        key = run["host"].casefold()
        current = latest.get(key)
        marker = (run["stamp"], priority[run["kind"]])
        if not current or marker > (current["stamp"], priority[current["kind"]]):
            latest[key] = run
    return list(latest.values())


def load(source: Path, history: bool) -> tuple[list[dict], int]:
    paths = find_logs(source)
    if not paths:
        raise ValueError("Nenhum arquivo audit-*.log encontrado.")
    runs = [parse_log(path) for path in paths]
    invalid = sum(not run["host"] or not run["controls"] for run in runs)
    runs = [run for run in runs if run["host"] and run["controls"]]
    if not runs:
        raise ValueError("Nenhum log contém host e resultados válidos.")
    return (runs if history else latest_per_host(runs)), invalid


def build_model(runs: list[dict], target: float) -> dict:
    hosts = []
    control_stats: dict[tuple[str, str], dict] = defaultdict(
        lambda: {"fails": 0, "passes": 0, "hosts": set()}
    )
    totals = Counter()

    for run in runs:
        counts = Counter(item["result"] for item in run["controls"].values())
        severity = Counter(
            item["severity"] for item in run["controls"].values() if item["result"] == "FAIL"
        )
        high_applicable = sum(
            item["result"] in {"PASS", "FAIL"} and item["severity"] == "Alta"
            for item in run["controls"].values()
        )
        high_pass = sum(
            item["result"] == "PASS" and item["severity"] == "Alta"
            for item in run["controls"].values()
        )
        applicable = counts["PASS"] + counts["FAIL"]
        adherence = counts["PASS"] * 100 / applicable if applicable else 0
        high_adherence = high_pass * 100 / high_applicable if high_applicable else 100
        earned = sum(
            WEIGHTS[item["severity"]]
            for item in run["controls"].values()
            if item["result"] == "PASS"
        )
        possible = sum(
            WEIGHTS[item["severity"]]
            for item in run["controls"].values()
            if item["result"] in {"PASS", "FAIL"}
        )
        quality = earned * 100 / possible if possible else 0
        hosts.append(
            {
                **run,
                "pass": counts["PASS"], "fail": counts["FAIL"], "na": counts["NA"],
                "high_fail": severity["Alta"], "medium_fail": severity["Média"],
                "adherence": adherence, "high_adherence": high_adherence,
                "quality": quality, "status": "Na meta" if adherence >= target else "Abaixo",
            }
        )
        totals.update(counts)
        for item in run["controls"].values():
            if item["result"] not in {"PASS", "FAIL"}:
                continue
            stat = control_stats[(item["id"], item["name"])]
            stat["severity"] = item["severity"]
            stat["hosts"].add(run["host"])
            stat["fails" if item["result"] == "FAIL" else "passes"] += 1

    hosts.sort(key=lambda row: (
        row["high_fail"], row["fail"], row["medium_fail"], -row["adherence"]
    ), reverse=True)
    controls = []
    for (control_id, name), stat in control_stats.items():
        evaluated = stat["fails"] + stat["passes"]
        controls.append({
            "id": control_id, "name": name, **stat,
            "evaluated": evaluated,
            "rate": stat["fails"] * 100 / evaluated if evaluated else 0,
        })
    controls.sort(key=lambda row: (
        -WEIGHTS[row["severity"]], -row["fails"], -row["rate"], row["id"]
    ))
    applicable = totals["PASS"] + totals["FAIL"]
    high_items = [item for run in runs for item in run["controls"].values()
                  if item["severity"] == "Alta" and item["result"] in {"PASS", "FAIL"}]
    high_pass = sum(item["result"] == "PASS" for item in high_items)
    weighted_possible = sum(WEIGHTS[item["severity"]] for run in runs
                            for item in run["controls"].values()
                            if item["result"] in {"PASS", "FAIL"})
    weighted_pass = sum(WEIGHTS[item["severity"]] for run in runs
                        for item in run["controls"].values() if item["result"] == "PASS")
    return {
        "hosts": hosts, "controls": controls, "totals": totals,
        "adherence": totals["PASS"] * 100 / applicable if applicable else 0,
        "high_adherence": high_pass * 100 / len(high_items) if high_items else 100,
        "quality": weighted_pass * 100 / weighted_possible if weighted_possible else 0,
        "at_target": sum(row["adherence"] >= target for row in hosts),
        "high_affected": sum(row["high_fail"] > 0 for row in hosts),
    }


STYLE = """
:root{--red:#d71920;--deep:#62070b;--ink:#202124;--muted:#70757a;--line:#e6e7e9;--bg:#f5f6f8}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.45 Arial,sans-serif}
.top{height:6px;background:linear-gradient(90deg,var(--deep),var(--red))}.head,.page{max-width:1450px;margin:auto;padding:22px 28px}
.head{display:flex;justify-content:space-between;align-items:center;background:#fff}.head h1{margin:0;font-size:22px}.print{border:0;border-radius:8px;background:#202124;color:#fff;padding:10px 14px;cursor:pointer}
header{background:#fff;border-bottom:1px solid var(--line)}.hero{background:linear-gradient(120deg,#72080c,#dc2027);color:#fff;border-radius:15px;padding:27px 30px}.hero h2{font-size:28px;margin:0 0 8px}.hero p{margin:0;color:#ffe7e8}
.kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:14px;margin:18px 0}.kpi,.card{background:#fff;border:1px solid var(--line);border-radius:12px;box-shadow:0 8px 24px #2021240d}.kpi{padding:17px;border-left:4px solid var(--red)}.kpi span{color:var(--muted);font-size:11px;text-transform:uppercase;font-weight:bold}.kpi strong{display:block;font-size:27px;margin:7px 0}.kpi small{color:var(--muted)}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}.card{margin-top:18px;overflow:hidden}.card h3{margin:0;padding:18px 20px 4px}.card>p{margin:0;padding:0 20px 15px;color:var(--muted);font-size:12px}.table{overflow:auto;max-height:620px;border-top:1px solid var(--line)}table{width:100%;border-collapse:collapse;min-width:850px}th{position:sticky;top:0;background:#f0f1f3;text-align:left;font-size:10px;text-transform:uppercase;padding:11px}td{padding:10px 11px;border-bottom:1px solid #eee}tr:hover td{background:#fff8f8}.num{text-align:right}.fail{color:var(--red);font-weight:bold}.badge{border-radius:20px;padding:4px 8px;font-size:10px;font-weight:bold;background:#eee}.alta{background:#ffe0e1;color:#900}.media{background:#fff0f0;color:#bd171d}.ok{color:#333}.below{color:var(--red);font-weight:bold}
.filters{display:flex;gap:10px;padding:0 20px 15px}.filters input,.filters select{padding:9px;border:1px solid #ccd0d4;border-radius:8px}.method{padding:17px 20px}.method code{color:#a70d13}.footer{text-align:center;color:var(--muted);padding:24px}
@media(max-width:1050px){.kpis{grid-template-columns:repeat(3,1fr)}.grid{grid-template-columns:1fr}}@media(max-width:650px){.page,.head{padding:16px}.kpis{grid-template-columns:1fr 1fr}}@media print{.print,.filters{display:none}.card,.kpi{box-shadow:none}.table{max-height:none}th{position:static}}
"""


def host_rows(hosts: list[dict]) -> str:
    rows = []
    for pos, row in enumerate(hosts, 1):
        rows.append(f"""<tr data-status="{'ok' if row['status'] == 'Na meta' else 'below'}">
<td>{pos}</td><td><strong>{esc(row['host'])}</strong><br><small>{esc(row['kind'].upper())} · {esc(row['stamp'])}</small></td><td>{esc(row['os'])}</td>
<td class="num fail">{row['high_fail']}</td><td class="num fail">{row['fail']}</td><td class="num">{row['pass']}</td><td class="num">{row['na']}</td>
<td class="num">{pct(row['high_adherence'])}</td><td class="num">{pct(row['adherence'])}</td><td class="num">{pct(row['quality'])}</td><td class="{('ok' if row['status'] == 'Na meta' else 'below')}">{row['status']}</td></tr>""")
    return "".join(rows)


def control_rows(controls: list[dict], limit: int | None = None) -> str:
    rows = []
    for row in controls[:limit]:
        css = "alta" if row["severity"] == "Alta" else "media" if row["severity"] == "Média" else ""
        rows.append(f"""<tr><td>{esc(row['id'])}</td><td>{esc(row['name'])}</td><td><span class="badge {css}">{esc(row['severity'])}</span></td><td class="num fail">{row['fails']}</td><td class="num">{row['evaluated']}</td><td class="num">{pct(row['rate'])}</td></tr>""")
    return "".join(rows)


def render(model: dict, source: Path, output: Path, target: float, client: str,
           invalid: int, history: bool) -> None:
    hosts = model["hosts"]
    totals = model["totals"]
    high_fails = sum(row["high_fail"] for row in hosts)
    document = f"""<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Indicadores de Hardening</title><style>{STYLE}</style></head><body>
<div class="top"></div><header><div class="head"><h1>Indicadores de Hardening — {esc(client)}</h1><button class="print" onclick="print()">Imprimir / PDF</button></div></header>
<main class="page"><section class="hero"><h2>{high_fails} FAILs de criticidade Alta</h2><p>{model['high_affected']} de {len(hosts)} servidores afetados · Aderência crítica {pct(model['high_adherence'])} · Meta geral {target:g}%</p></section>
<section class="kpis">
<article class="kpi"><span>Aderência geral</span><strong>{pct(model['adherence'])}</strong><small>PASS / aplicáveis</small></article>
<article class="kpi"><span>Aderência Alta</span><strong>{pct(model['high_adherence'])}</strong><small>Qualidade crítica</small></article>
<article class="kpi"><span>Índice de qualidade</span><strong>{pct(model['quality'])}</strong><small>Pesos Alta 3 · Média 2 · Baixa 1</small></article>
<article class="kpi"><span>FAILs Alta</span><strong>{high_fails}</strong><small>Prioridade técnica</small></article>
<article class="kpi"><span>Total de FAILs</span><strong>{totals['FAIL']}</strong><small>{totals['PASS']} PASS · {totals['NA']} NA</small></article>
<article class="kpi"><span>Servidores na meta</span><strong>{model['at_target']} / {len(hosts)}</strong><small>Meta individual {target:g}%</small></article>
</section>
<section class="grid"><article class="card"><h3>Controles prioritários</h3><p>Criticidade e recorrência de FAIL</p><div class="table"><table><thead><tr><th>ID</th><th>Controle</th><th>Criticidade</th><th>FAIL</th><th>Avaliados</th><th>Taxa</th></tr></thead><tbody>{control_rows(model['controls'], 15)}</tbody></table></div></article>
<article class="card"><h3>Leitura executiva</h3><p>Qualidade da aderência</p><div class="method"><p><strong>{high_fails}</strong> falhas Altas permanecem abertas em <strong>{model['high_affected']}</strong> servidores.</p><p>A aderência geral é <strong>{pct(model['adherence'])}</strong>, enquanto a aderência dos controles Altos é <strong>{pct(model['high_adherence'])}</strong>.</p><p>O índice ponderado é <strong>{pct(model['quality'])}</strong>; controles Altos têm maior impacto.</p></div></article></section>
<section class="card"><h3>Ranking de servidores</h3><p>Ordenado por FAILs Altos, total de FAILs, FAILs Médios e aderência</p><div class="filters"><input id="search" placeholder="Buscar servidor"><select id="status"><option value="all">Todos</option><option value="below">Abaixo da meta</option><option value="ok">Na meta</option></select></div><div class="table"><table id="hosts"><thead><tr><th>#</th><th>Servidor</th><th>Sistema operacional</th><th>FAIL Alta</th><th>FAIL</th><th>PASS</th><th>NA</th><th>Ader. Alta</th><th>Aderência</th><th>Qualidade</th><th>Status</th></tr></thead><tbody>{host_rows(hosts)}</tbody></table></div></section>
<section class="card"><h3>Todos os controles</h3><p>Prioridade sugerida para remediação</p><div class="table"><table><thead><tr><th>ID</th><th>Controle</th><th>Criticidade</th><th>FAIL</th><th>Avaliados</th><th>Taxa</th></tr></thead><tbody>{control_rows(model['controls'])}</tbody></table></div></section>
<aside class="card method"><strong>Escopo:</strong> {'todas as execuções' if history else 'execução mais recente por servidor'}. Aderência = PASS / (PASS + FAIL). Qualidade = PASS ponderado / aplicáveis ponderados. Fonte: <code>{esc(source)}</code>. Logs inválidos ignorados: {invalid}. Gerado em {datetime.now().astimezone():%d/%m/%Y %H:%M %Z}.</aside>
<footer class="footer">HTML autocontido · sem conexão externa</footer></main>
<script>const q=document.querySelector('#search'),s=document.querySelector('#status'),rs=[...document.querySelectorAll('#hosts tbody tr')];function f(){{let v=q.value.toLowerCase();rs.forEach(r=>r.hidden=!(r.textContent.toLowerCase().includes(v)&&(s.value==='all'||r.dataset.status===s.value)))}}q.oninput=f;s.onchange=f;</script></body></html>"""
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(document, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard HTML a partir dos logs de auditoria.")
    parser.add_argument("entrada", nargs="?", type=Path, default=Path("logs/audit"), help="Log ou diretório (padrão: logs/audit)")
    parser.add_argument("-o", "--saida", type=Path, default=Path("dashboard_logs.html"), help="HTML de saída")
    parser.add_argument("--meta", type=float, default=70, help="Meta percentual (padrão: 70)")
    parser.add_argument("--cliente", default="HITSS", help="Nome exibido no dashboard")
    parser.add_argument("--historico", action="store_true", help="Inclui todas as execuções, não apenas a última por host")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if not 0 < args.meta <= 100:
            raise ValueError("A meta deve estar entre 0 e 100.")
        source = args.entrada.expanduser().resolve()
        runs, invalid = load(source, args.historico)
        model = build_model(runs, args.meta)
        output = args.saida.expanduser().resolve()
        render(model, source, output, args.meta, args.cliente, invalid, args.historico)
        print(f"Dashboard gerado: {output}")
        print(f"Resumo: {len(runs)} execuções | {model['totals']['FAIL']} FAIL | aderência {pct(model['adherence'])}")
        return 0
    except (OSError, ValueError) as error:
        print(f"Erro: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
