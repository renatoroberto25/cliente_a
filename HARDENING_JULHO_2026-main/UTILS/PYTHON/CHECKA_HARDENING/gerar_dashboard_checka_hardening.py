#!/usr/bin/env python3
"""Gera dashboard do CHECKA_HARDENING.

Regra principal: controle 999 PASSED confirma hardening pelo log local.
Os controles 1000 e 1001 sao apresentados apenas como evidencias adicionais.
"""

from __future__ import annotations

import argparse
import base64
import csv
from collections import Counter, defaultdict
from datetime import datetime
import html
from pathlib import Path
import re
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
IDS = ("999", "1000", "1001")


def clean(value: object) -> str:
    return " ".join(str(value or "").strip().split())


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def number(value: int) -> str:
    return f"{value:,}".replace(",", ".")


def percent(value: float) -> str:
    return f"{value:.1f}%".replace(".", ",")


def audit_id(row: dict[str, str]) -> str:
    match = re.match(r"\s*(\d+)", row.get("compliance.audit_name", ""))
    return match.group(1) if match else ""


def status(row: dict[str, str] | None) -> str:
    value = clean((row or {}).get("compliance_result")).upper()
    return value if value in {"PASSED", "FAILED"} else "UNKNOWN"


def read_csv(path: Path) -> list[dict[str, str]]:
    raw = path.read_bytes()[:65536]
    try:
        sample, encoding = raw.decode("utf-8-sig"), "utf-8-sig"
    except UnicodeDecodeError:
        sample, encoding = raw.decode("latin-1"), "latin-1"
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=",;\t|")
    except csv.Error:
        dialect = csv.excel
    with path.open(encoding=encoding, newline="") as source:
        rows = [
            {(key or "").lstrip("\ufeff").strip(): value or "" for key, value in row.items()}
            for row in csv.DictReader(source, dialect=dialect)
        ]
    if not rows:
        raise ValueError("CSV sem registros.")
    required = {"asset.host_name", "compliance.audit_name", "compliance_result", "definition.output"}
    missing = required.difference(rows[0])
    if missing:
        raise ValueError("Colunas obrigatorias ausentes: " + ", ".join(sorted(missing)))
    return rows


def pass_payload(output: str) -> str:
    return clean(output.rsplit("PASS |", 1)[-1]) if "PASS |" in output else ""


def parse_log(output: str) -> dict[str, str]:
    payload = pass_payload(output)
    version = re.search(r"(?i)\bv(\d+(?:\.\d+)+)", payload)
    timestamp = re.match(r"(\d{4}-\d{2}-\d{2}T[^ ]+)", payload)
    mode = "FULL" if " - FULL - " in payload else "AUDIT" if " - AUDIT - " in payload else "Nao informado"
    origin = (
        "Tenable" if "VIA TENABLE" in payload
        else "Execucao local shellscript" if "VIA EXECUCAO LOCAL AUTOMACAO SHELLSCRIPT" in payload
        else "Nao informada"
    )
    return {
        "payload": payload or "Log confirmado; conteudo nao interpretado",
        "version": version.group(1) if version else "Nao informada",
        "timestamp": timestamp.group(1) if timestamp else "Nao informado",
        "mode": mode,
        "origin": origin,
    }


def os_family(value: str) -> str:
    text = value.casefold()
    if "red hat" in text:
        match = re.search(r"(?:release|linux(?: server)?)\s+(\d+)", text)
        return "RHEL " + match.group(1) if match else "RHEL"
    if "centos" in text:
        match = re.search(r"centos[^0-9]*(\d+)", text)
        return "CentOS " + match.group(1) if match else "CentOS"
    if "oracle linux" in text:
        return "Oracle Linux"
    return "Outro / nao informado"


def short_evidence(row: dict[str, str] | None) -> str:
    output = (row or {}).get("definition.output", "")
    for marker in ("PASS |", "FAIL |"):
        if marker in output:
            return clean(output.rsplit(marker, 1)[-1])
    return "Sem retorno interpretavel"


def build_model(rows: list[dict[str, str]]) -> dict:
    unique: dict[tuple[str, str], dict[str, str]] = {}
    duplicates = ignored = 0
    for row in rows:
        host = clean(row.get("asset.host_name") or row.get("asset.name"))
        control = audit_id(row)
        if not host or control not in IDS:
            ignored += 1
            continue
        key = (host.casefold(), control)
        duplicates += int(key in unique)
        unique[key] = row

    grouped: dict[str, dict[str, dict[str, str]]] = defaultdict(dict)
    for (host_key, control), row in unique.items():
        grouped[host_key][control] = row

    hosts = []
    for controls in grouped.values():
        representative = next(iter(controls.values()))
        states = {control: status(controls.get(control)) for control in IDS}
        confirmed = states["999"] == "PASSED"
        log = parse_log(controls.get("999", {}).get("definition.output", "")) if confirmed else {
            "payload": short_evidence(controls.get("999")), "version": "—", "timestamp": "—",
            "mode": "—", "origin": "—",
        }
        hosts.append({
            "host": clean(representative.get("asset.host_name") or representative.get("asset.name")),
            "ip": clean(representative.get("asset.ip_addresses")) or "—",
            "os": clean(representative.get("asset.operating_systems")) or "—",
            "os_family": os_family(representative.get("asset.operating_systems", "")),
            "confirmed": confirmed,
            "states": states,
            "log": log,
            "evidence_1000": short_evidence(controls.get("1000")),
            "evidence_1001": short_evidence(controls.get("1001")),
        })

    hosts.sort(key=lambda item: (item["confirmed"], item["host"].casefold()))
    total = len(hosts)
    confirmed = sum(item["confirmed"] for item in hosts)
    versions = Counter(item["log"]["version"] for item in hosts if item["confirmed"])
    modes = Counter(item["log"]["mode"] for item in hosts if item["confirmed"])
    origins = Counter(item["log"]["origin"] for item in hosts if item["confirmed"])
    evidence = {control: sum(item["states"][control] == "PASSED" for item in hosts) for control in IDS}
    secondary_without_log = sum(
        not item["confirmed"] and (item["states"]["1000"] == "PASSED" or item["states"]["1001"] == "PASSED")
        for item in hosts
    )
    return {
        "hosts": hosts, "total": total, "confirmed": confirmed, "without_log": total - confirmed,
        "versions": versions, "modes": modes, "origins": origins, "evidence": evidence,
        "secondary_without_log": secondary_without_log, "os": Counter(item["os_family"] for item in hosts),
        "duplicates": duplicates, "ignored": ignored,
    }


def logo_data() -> str:
    path = SCRIPT_DIR / "Claro.png"
    if not path.is_file():
        raise ValueError(f"Logo nao encontrada no diretorio do script: {path}")
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def bars(values: Counter, total: int) -> str:
    colors = ("#F00000", "#6D28D9", "#2563EB", "#D97706", "#059669")
    return "".join(
        f'<div class="bar"><div><span>{esc(label)}</span><strong>{number(value)}</strong></div>'
        f'<div class="track"><i style="width:{value * 100 / max(total, 1):.3f}%;background:{colors[index % len(colors)]}"></i></div></div>'
        for index, (label, value) in enumerate(values.most_common())
    ) or '<p class="muted">Sem dados.</p>'


def mark(value: str) -> str:
    css = "yes" if value == "PASSED" else "no" if value == "FAILED" else "unknown"
    label = "PASS" if value == "PASSED" else "FAIL" if value == "FAILED" else "N/D"
    return f'<span class="mark {css}">{label}</span>'


def host_rows(hosts: list[dict]) -> str:
    result = []
    for item in hosts:
        state = "confirmed" if item["confirmed"] else "without"
        result.append(f"""
        <tr data-state="{state}" data-search="{esc((item['host'] + ' ' + item['ip'] + ' ' + item['os'] + ' ' + item['log']['version']).casefold())}">
          <td data-label="Host / IP"><strong>{esc(item['host'])}</strong><small>{esc(item['ip'])}</small></td>
          <td data-label="Sistema operacional" class="os">{esc(item['os'])}</td>
          <td data-label="999" title="{esc(item['log']['payload'])}">{mark(item['states']['999'])}</td>
          <td data-label="Versao">{esc(item['log']['version'])}</td>
          <td data-label="Registro">{esc(item['log']['mode'])}<small>{esc(item['log']['origin'])}</small></td>
          <td data-label="1000" title="{esc(item['evidence_1000'])}">{mark(item['states']['1000'])}</td>
          <td data-label="1001" title="{esc(item['evidence_1001'])}">{mark(item['states']['1001'])}</td>
          <td data-label="Leitura"><span class="status {state}">{'Hardening comprovado' if item['confirmed'] else 'Sem log de hardening'}</span></td>
        </tr>""")
    return "".join(result)


HTML = r"""<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Check de Hardening · Claro TI</title><style>
:root{--red:#F00000;--ink:#172033;--muted:#64748B;--line:#E2E8F0;--soft:#F8FAFC;--green:#15803D;--amber:#B45309;--shadow:0 10px 28px rgba(15,23,42,.08)}*{box-sizing:border-box}body{margin:0;background:#F1F5F9;color:var(--ink);font:14px/1.45 Inter,Segoe UI,Arial,sans-serif}.header{background:linear-gradient(120deg,#F00000,#B60000);color:#fff}.header-inner{max-width:1500px;min-height:122px;margin:auto;padding:22px 30px;display:grid;grid-template-columns:92px 1fr auto;gap:24px;align-items:center}.logo{width:80px;height:80px;object-fit:contain}.header h1{font-size:clamp(25px,3vw,38px);margin:0}.header p{margin:5px 0 0;opacity:.9}.report{text-align:right}.report small,.report strong{display:block}main{max-width:1500px;margin:auto;padding:22px 30px 48px}.context{display:flex;justify-content:space-between;gap:15px;color:var(--muted);font-size:12px;margin-bottom:18px}.grid{display:grid;gap:18px}.hero{grid-template-columns:minmax(0,1.45fr) minmax(350px,.75fr)}.card{background:#fff;border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow);overflow:hidden}.pad{padding:24px}.eyebrow{color:var(--red);font-size:11px;font-weight:900;letter-spacing:.1em;text-transform:uppercase}.story h2{font-size:clamp(26px,3.5vw,44px);line-height:1.08;margin:12px 0}.story p{color:var(--muted);font-size:15px}.callout{padding:14px 17px;border-left:5px solid var(--red);background:#FFF7F7;border-radius:8px;margin-top:18px}.coverage{display:flex;align-items:center;gap:25px}.ring{--p:0;width:165px;aspect-ratio:1;border-radius:50%;background:conic-gradient(var(--red) calc(var(--p)*1%),#E8EDF3 0);display:grid;place-items:center;position:relative;flex:none}.ring:after{content:"";position:absolute;inset:17px;border-radius:50%;background:#fff}.ring div{position:relative;z-index:1;text-align:center}.ring strong{display:block;font-size:31px}.ring small{color:var(--muted)}.legend{display:grid;gap:14px;width:100%}.legend div{display:flex;justify-content:space-between;gap:14px}.legend span{color:var(--muted)}.kpis{grid-template-columns:repeat(4,1fr)}.kpi{padding:19px;border-top:5px solid var(--line)}.kpi strong{display:block;font-size:33px}.kpi span{color:var(--muted)}.kpi.ok{border-color:var(--green)}.kpi.bad{border-color:var(--red)}.kpi.info{border-color:#6D28D9}.split{grid-template-columns:1fr 1fr}.head{padding:17px 21px;border-bottom:1px solid var(--line)}.head h3{font-size:16px;margin:0}.head p{font-size:12px;color:var(--muted);margin:4px 0 0}.evidence{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.ev{border:1px solid var(--line);border-radius:10px;padding:15px}.ev strong{display:block;font-size:27px}.ev span,.ev small{display:block}.ev span{font-weight:800}.ev small{color:var(--muted);margin-top:4px}.bar{margin:14px 0}.bar>div:first-child{display:flex;justify-content:space-between;margin-bottom:5px}.track{height:10px;background:#EDF2F7;border-radius:99px;overflow:hidden}.track i{display:block;height:100%;border-radius:99px}.note{font-size:12px;color:var(--muted)}.note code{background:#E2E8F0;color:#334155;padding:2px 5px;border-radius:4px}.section-head{padding:16px 20px;border-bottom:1px solid var(--line);display:flex;justify-content:space-between;gap:16px;align-items:center}.section-head h3{margin:0}.section-head p{color:var(--muted);font-size:12px;margin:3px 0 0}.tools{display:flex;gap:9px;align-items:center}.tools input,.tools select{border:1px solid var(--line);border-radius:8px;padding:9px 11px;background:#fff;min-width:210px}.count{font-size:12px;color:var(--muted)}.table-wrap{overflow:auto;max-height:680px}table{border-collapse:collapse;width:100%;min-width:1220px}th{position:sticky;top:0;z-index:2;background:var(--soft);text-align:left;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);font-size:10px;padding:11px 13px}td{border-top:1px solid var(--line);padding:11px 13px;vertical-align:middle}td small{display:block;color:var(--muted)}td.os{max-width:330px}.mark,.status{display:inline-block;padding:5px 9px;border-radius:99px;font-size:11px;font-weight:800;white-space:nowrap}.mark.yes,.status.confirmed{background:#DCFCE7;color:#166534}.mark.no,.status.without{background:#FEE2E2;color:#991B1B}.mark.unknown{background:#E2E8F0;color:#475569}.muted{color:var(--muted)}footer{text-align:center;color:var(--muted);font-size:11px;margin-top:20px}
@media(max-width:1000px){.hero,.split{grid-template-columns:1fr}.kpis{grid-template-columns:1fr 1fr}.header-inner{grid-template-columns:75px 1fr}.report{display:none}}@media(max-width:650px){.header-inner{padding:17px;grid-template-columns:56px 1fr}.logo{width:52px;height:52px}.header h1{font-size:21px}main{padding:14px}.context,.section-head{flex-direction:column;align-items:stretch}.kpis,.evidence{grid-template-columns:1fr}.coverage{flex-direction:column}.tools{flex-direction:column;align-items:stretch}.tools input,.tools select{min-width:0;width:100%}.table-wrap{max-height:none;padding:8px}table{min-width:0;display:block}thead{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0)}tbody,tr{display:block}tr{border:1px solid var(--line);border-radius:10px;margin-bottom:10px;overflow:hidden}td{display:grid;grid-template-columns:38% 1fr;gap:10px}td:before{content:attr(data-label);font-size:10px;text-transform:uppercase;font-weight:900;color:var(--muted)}}@media print{body{background:#fff}.card{box-shadow:none}.tools{display:none}.table-wrap{max-height:none}th{position:static}}
</style></head><body><header class="header"><div class="header-inner"><img class="logo" src="__LOGO__" alt="Claro"><div><h1>Check de Hardening</h1><p>Agents Unix · Claro TI</p></div><div class="report"><small>Data da coleta</small><strong>__COLLECTION__</strong></div></div></header><main><div class="context"><span><strong>Fonte:</strong> __SOURCE__</span><span>Gerado em __GENERATED__</span></div><div class="grid">
<section class="grid hero"><article class="card pad story"><span class="eyebrow">Leitura principal · controle 999</span><h2>__CONFIRMED__ de __TOTAL__ agents têm hardening comprovado pelo log local.</h2><p>O controle 999 é o indicador principal desta leitura. Os demais controles complementam a evidência, mas não anulam um log confirmado.</p><div class="callout"><strong>__WITHOUT__ agents sem log de hardening.</strong> Entre eles, __SECONDARY_WITHOUT__ apresentaram alguma evidência complementar nos controles 1000 ou 1001.</div></article><article class="card pad coverage"><div class="ring" style="--p:__COVERAGE_RAW__"><div><strong>__COVERAGE__</strong><small>com log</small></div></div><div class="legend"><div><span>Hardening comprovado</span><strong>__CONFIRMED__</strong></div><div><span>Sem log de hardening</span><strong>__WITHOUT__</strong></div><div><span>Total avaliado</span><strong>__TOTAL__</strong></div></div></article></section>
<section class="grid kpis"><article class="card kpi"><strong>__TOTAL__</strong><span>agents avaliados</span></article><article class="card kpi ok"><strong>__CONFIRMED__</strong><span>999 PASSED · log confirmado</span></article><article class="card kpi bad"><strong>__WITHOUT__</strong><span>999 FAILED · sem log</span></article><article class="card kpi info"><strong>__SECONDARY_WITHOUT__</strong><span>sem log, mas com evidência complementar</span></article></section>
<section class="grid split"><article class="card"><div class="head"><h3>O que os outputs dos logs informam</h3><p>Distribuição descritiva; não é classificação de atual ou antigo</p></div><div class="pad"><div class="evidence">__LOG_CARDS__</div><div style="margin-top:20px">__VERSION_BARS__</div></div></article><article class="card"><div class="head"><h3>Evidências do audit</h3><p>PASSED por controle; os grupos podem se sobrepor</p></div><div class="pad evidence">__EVIDENCE_CARDS__</div></article></section>
<section class="grid split"><article class="card"><div class="head"><h3>Sistemas operacionais</h3><p>Família inferida do inventário do agent</p></div><div class="pad">__OS_BARS__</div></article><article class="card pad note"><strong>Como ler o resultado</strong><p><code>999 PASSED</code> confirma hardening pelo conteúdo de <code>/var/log/hitss-hardening.log</code>. <code>1000</code> procura arquivos exatos gerenciados pela automação. <code>1001</code> procura vestígios com sufixos exclusivos dos remediadores antigos.</p><p>Um FAIL no 1000 ou 1001 não invalida o 999. Um PASS secundário sem PASS no 999 deve ser tratado como evidência complementar, não como log confirmado.</p></article></section>
<article class="card"><div class="section-head"><div><h3>Inventário e rastreabilidade</h3><p>Passe o mouse sobre os resultados para consultar o retorno resumido</p></div><div class="tools"><input id="search" type="search" placeholder="Buscar host, IP, SO ou versão"><select id="filter"><option value="all">Todos</option><option value="confirmed">Hardening comprovado</option><option value="without">Sem log</option></select><span id="count" class="count"></span></div></div><div class="table-wrap"><table id="inventory"><thead><tr><th>Host / IP</th><th>Sistema operacional</th><th>999</th><th>Versão no log</th><th>Tipo / origem</th><th>1000</th><th>1001</th><th>Leitura</th></tr></thead><tbody>__HOST_ROWS__</tbody></table><p id="empty" class="muted" hidden>Nenhum host encontrado.</p></div></article>
<aside class="card pad note"><strong>Qualidade da base:</strong> chave <code>asset.host_name + controle</code>; última linha prevalece em duplicidade. __DUPLICATES__ duplicados e __IGNORED__ registros ignorados. Reconciliação: __CONFIRMED__ com log + __WITHOUT__ sem log = __TOTAL__ agents.</aside></div><footer>Check de Hardening · Claro TI</footer></main><script>(()=>{const q=document.getElementById('search'),f=document.getElementById('filter'),rows=[...document.querySelectorAll('#inventory tbody tr')],count=document.getElementById('count'),empty=document.getElementById('empty');function apply(){const term=q.value.trim().toLocaleLowerCase('pt-BR');let n=0;rows.forEach(row=>{const show=(!term||row.dataset.search.includes(term))&&(f.value==='all'||row.dataset.state===f.value);row.hidden=!show;n+=show?1:0});count.textContent=`${n} de ${rows.length}`;empty.hidden=n!==0}q.addEventListener('input',apply);f.addEventListener('change',apply);apply()})();</script></body></html>"""


def collection_date(path: Path) -> str:
    match = re.search(r"_(\d{2})_(\d{2})_(\d{4})(?:_|$)", path.stem)
    return f"{match.group(2)}/{match.group(1)}/{match.group(3)}" if match else "Nao informada"


def render(model: dict, source: Path, output: Path) -> None:
    total, confirmed = model["total"], model["confirmed"]
    coverage = confirmed * 100 / total if total else 0.0
    log_cards = "".join((
        f'<div class="ev"><strong>{number(model["modes"]["AUDIT"])}</strong><span>Registros AUDIT</span><small>{number(model["origins"]["Tenable"])} via Tenable</small></div>',
        f'<div class="ev"><strong>{number(model["modes"]["FULL"])}</strong><span>Registros FULL</span><small>{number(model["origins"]["Execucao local shellscript"])} via execução local</small></div>',
        f'<div class="ev"><strong>{number(len(model["versions"]))}</strong><span>Versões informadas</span><small>Extraídas do conteúdo do log</small></div>',
    ))
    evidence_cards = "".join((
        f'<div class="ev"><strong>{number(model["evidence"]["999"])}</strong><span>999 · logs locais</span><small>Indicador principal</small></div>',
        f'<div class="ev"><strong>{number(model["evidence"]["1000"])}</strong><span>1000 · artefatos</span><small>Evidência complementar</small></div>',
        f'<div class="ev"><strong>{number(model["evidence"]["1001"])}</strong><span>1001 · vestígios</span><small>Evidência complementar</small></div>',
    ))
    replacements = {
        "__LOGO__": logo_data(), "__SOURCE__": esc(source.name), "__COLLECTION__": collection_date(source),
        "__GENERATED__": datetime.now().astimezone().strftime("%d/%m/%Y %H:%M %Z"),
        "__TOTAL__": number(total), "__CONFIRMED__": number(confirmed),
        "__WITHOUT__": number(model["without_log"]), "__SECONDARY_WITHOUT__": number(model["secondary_without_log"]),
        "__COVERAGE__": percent(coverage), "__COVERAGE_RAW__": f"{coverage:.3f}",
        "__LOG_CARDS__": log_cards, "__VERSION_BARS__": bars(model["versions"], confirmed),
        "__EVIDENCE_CARDS__": evidence_cards, "__OS_BARS__": bars(model["os"], total),
        "__HOST_ROWS__": host_rows(model["hosts"]), "__DUPLICATES__": number(model["duplicates"]),
        "__IGNORED__": number(model["ignored"]),
    }
    document = HTML
    for placeholder, value in replacements.items():
        document = document.replace(placeholder, value)
    output.write_text(document, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard do CHECKA_HARDENING.")
    parser.add_argument("entrada", type=Path, help="CSV exportado pelo scan")
    parser.add_argument("-o", "--saida", type=Path, default=SCRIPT_DIR / "dashboard_checka_hardening.html")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if not args.entrada.is_file():
            raise ValueError(f"Arquivo nao encontrado: {args.entrada}")
        model = build_model(read_csv(args.entrada))
        if not model["hosts"]:
            raise ValueError("Nenhum host com os controles 999, 1000 ou 1001.")
        output = args.saida.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        render(model, args.entrada, output)
        print(f"Dashboard gerado: {output}")
        print(
            f"Agents: {model['total']} | 999 PASSED: {model['confirmed']} | 999 FAILED: {model['without_log']} | "
            f"1000 PASSED: {model['evidence']['1000']} | 1001 PASSED: {model['evidence']['1001']}"
        )
        return 0
    except (OSError, UnicodeError, ValueError, csv.Error) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
