#!/usr/bin/env python3
"""Gera dashboard executivo de hardening a partir do export host-audits.

O arquivo inteiro e lido em streaming. Somente auditorias com audit_name no
formato ``ID, nome, criticidade`` entram nos indicadores; o restante aparece
na prestacao de contas de qualidade. O HTML gerado e autocontido e permite
alternar entre Consolidado, Claro TI, Engenharia de Video, BCC, Star One e
Outras equipes.
"""

from __future__ import annotations

import argparse
import base64
from collections import Counter, defaultdict
import csv
from datetime import datetime
import html
import json
from pathlib import Path
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile


HERE = Path(__file__).resolve().parent
AUDIT_RE = re.compile(
    r"^\s*(\d+)\s*,\s*(.+?)\s*,\s*"
    r"(critica|crítica|critical|alta|high|media|média|medium|baixa|low)\s*$",
    re.IGNORECASE,
)
TEAM_ORDER = ("Claro TI", "Engenharia de Vídeo", "BCC", "Star One", "Outras equipes")
SEVERITY_ORDER = {"Alta": 0, "Média": 1, "Baixa": 2}
XML_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"


def clean(value: object) -> str:
    return " ".join(str(value or "").strip().split())


def fold(value: object) -> str:
    text = unicodedata.normalize("NFKD", clean(value))
    return "".join(c for c in text if not unicodedata.combining(c)).casefold()


def status(value: object) -> str:
    value = fold(value).replace("_", " ").replace("-", " ")
    if value in {"passed", "pass", "compliant", "conforme", "ok", "true"}:
        return "PASSED"
    if value in {"failed", "fail", "non compliant", "nao conforme", "nok", "false"}:
        return "FAILED"
    return "UNKNOWN"


def severity(value: str) -> str:
    value = fold(value)
    if value in {"critica", "critical", "alta", "high"}:
        return "Alta"
    if value in {"media", "medium"}:
        return "Média"
    return "Baixa"


def parse_tags(raw: str) -> tuple[list[tuple[str, str]], bool]:
    try:
        data = json.loads(raw or "[]")
        if not isinstance(data, list):
            return [], False
        return [(clean(x.get("category")), clean(x.get("value"))) for x in data if isinstance(x, dict)], True
    except (TypeError, ValueError, json.JSONDecodeError):
        return [], False


def classify_team(tags: list[tuple[str, str]]) -> str:
    """Classifica uma linha com precedencia para tags de equipes especificas."""
    terms = {fold(c) for c, _ in tags} | {fold(v) for _, v in tags}
    joined = " | ".join(f"{fold(c)}={fold(v)}" for c, v in tags)
    if any("engenharia" in x and "video" in x for x in terms) or "engenharia video" in joined:
        return "Engenharia de Vídeo"
    if any(x == "bcc" or x.startswith("bcc_") or "bcc" in x.split() for x in terms):
        return "BCC"
    if any("star one" in x or "starone" in x or "star_one" in x for x in terms):
        return "Star One"
    if "linux_claro_ti" in terms or any(c == "ti" and v in {"agents", "int_claro", "int_dc-campinas"} for c, v in ((fold(a), fold(b)) for a, b in tags)):
        return "Claro TI"
    return "Outras equipes"


def os_family(value: object) -> str:
    value = fold(value)
    if "windows" in value or "microsoft" in value:
        return "Windows"
    if any(term in value for term in ("linux", "red hat", "ubuntu", "debian", "centos", "oracle", "suse", "unix")):
        return "Linux"
    return "Outro/indefinido"


def read_csv(path: Path):
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
        reader = csv.DictReader(source, dialect=dialect)
        required = {"asset.host_name", "asset.tags", "compliance.audit_name", "compliance_result"}
        missing = required.difference(reader.fieldnames or [])
        if missing:
            raise ValueError("Colunas obrigatórias ausentes: " + ", ".join(sorted(missing)))
        for row in reader:
            yield row


def timestamp(row: dict[str, str]) -> str:
    return clean(row.get("last_observed") or row.get("first_seen"))


def load(path: Path, excluded: set[str]) -> tuple[dict, dict]:
    quality = Counter()
    unique: dict[tuple[str, str, str], dict] = {}
    all_hosts: set[str] = set()
    tag_pairs: Counter = Counter()
    invalid_examples: Counter = Counter()
    invalid_groups: dict[tuple, dict] = {}
    for row in read_csv(path):
        quality["rows"] += 1
        host = clean(row.get("asset.host_name") or row.get("asset.name"))
        if host:
            all_hosts.add(host.casefold())
        tags, tags_ok = parse_tags(row.get("asset.tags", ""))
        if not tags_ok:
            quality["bad_tags"] += 1
        tag_pairs.update(tags)
        team = classify_team(tags)
        platform = os_family(row.get("asset.operating_systems"))
        audit_name_raw = clean(row.get("compliance.audit_name"))
        leading_id = re.match(r"^\s*(\d+)\s*,", audit_name_raw)
        if leading_id and int(leading_id.group(1)) > 999:
            quality["utility_rows"] += 1
            continue
        match = AUDIT_RE.fullmatch(audit_name_raw)
        if not match:
            quality["outside_pattern"] += 1
            audit_name = clean(row.get("compliance.audit_name")) or "(vazio)"
            audit_file = clean(row.get("compliance.audit_file")) or "(sem arquivo)"
            invalid_examples[audit_name] += 1
            bad_key = (platform, team, audit_name, audit_file, status(row.get("compliance_result")))
            group = invalid_groups.setdefault(bad_key, {
                "platform": platform, "team": team, "name": audit_name, "file": audit_file,
                "status": status(row.get("compliance_result")), "rows": 0, "hosts": set(),
                "sampleHost": host or "—", "sampleOutput": clean(row.get("definition.output"))[:300],
            })
            group["rows"] += 1
            if host:
                group["hosts"].add(host.casefold())
            continue
        control_id, control_name, risk = match.groups()
        if control_id in excluded:
            quality["excluded"] += 1
            continue
        if not host:
            quality["without_host"] += 1
            continue
        key = (team, host.casefold(), control_id)
        item = {
            "team": team, "host": host, "ip": clean(row.get("asset.ip_addresses")),
            "os": clean(row.get("asset.operating_systems")), "platform": platform, "id": control_id,
            "name": clean(control_name), "severity": severity(risk),
            "status": status(row.get("compliance_result")), "observed": timestamp(row),
        }
        previous = unique.get(key)
        if previous is not None:
            quality["duplicates"] += 1
        if previous is None or item["observed"] >= previous["observed"]:
            unique[key] = item
    quality["valid_rows"] = quality["rows"] - quality["outside_pattern"] - quality["utility_rows"]
    quality["source_hosts"] = len(all_hosts)
    quality["records_used"] = len(unique)
    metadata = {
        "quality": dict(quality),
        "tag_pairs": [{"category": a, "value": b, "rows": n} for (a, b), n in tag_pairs.most_common()],
        "invalid_examples": [{"name": name, "rows": n} for name, n in invalid_examples.most_common(12)],
        "invalid_groups": [
            {**{k: v for k, v in group.items() if k != "hosts"}, "hostCount": len(group["hosts"])}
            for group in sorted(invalid_groups.values(), key=lambda x: (-x["rows"], x["platform"], x["name"]))
        ],
    }
    return unique, metadata


def summarize(rows: list[dict], target: float) -> dict:
    hosts: dict[str, list[dict]] = defaultdict(list)
    controls: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        hosts[row["host"].casefold()].append(row)
        controls[row["id"]].append(row)
    host_items = []
    sev_total = Counter()
    passed = failed = unknown = 0
    for values in hosts.values():
        counts = Counter(x["status"] for x in values)
        failures = Counter(x["severity"] for x in values if x["status"] == "FAILED")
        evaluated = counts["PASSED"] + counts["FAILED"]
        adherence = counts["PASSED"] * 100 / evaluated if evaluated else 0
        host_items.append({
            "host": values[0]["host"], "ip": values[0]["ip"] or "—", "os": values[0]["os"] or "—",
            "passed": counts["PASSED"], "failed": counts["FAILED"], "unknown": counts["UNKNOWN"],
            "high": failures["Alta"], "medium": failures["Média"], "low": failures["Baixa"],
            "adherence": round(adherence, 2), "atTarget": evaluated > 0 and adherence >= target,
        })
        sev_total.update(failures); passed += counts["PASSED"]; failed += counts["FAILED"]; unknown += counts["UNKNOWN"]
    host_items.sort(key=lambda x: (-x["high"], -x["failed"], x["adherence"], x["host"].casefold()))
    control_items = []
    for cid, values in controls.items():
        counts = Counter(x["status"] for x in values)
        evaluated = counts["PASSED"] + counts["FAILED"]
        risk = Counter(x["severity"] for x in values).most_common(1)[0][0]
        control_items.append({
            "id": cid, "name": Counter(x["name"] for x in values).most_common(1)[0][0], "severity": risk,
            "failed": counts["FAILED"], "passed": counts["PASSED"],
            "rate": round(counts["FAILED"] * 100 / evaluated, 2) if evaluated else 0,
        })
    control_items.sort(key=lambda x: (x["failed"] == 0, SEVERITY_ORDER[x["severity"]], -x["failed"], x["id"]))
    evaluated = passed + failed
    return {
        "hosts": host_items, "controls": control_items, "hostCount": len(host_items), "controlCount": len(control_items),
        "passed": passed, "failed": failed, "unknown": unknown, "evaluated": evaluated,
        "adherence": round(passed * 100 / evaluated, 2) if evaluated else 0,
        "atTarget": sum(x["atTarget"] for x in host_items),
        "severity": {x: sev_total[x] for x in ("Alta", "Média", "Baixa")},
        "affected": {
            "Alta": sum(x["high"] > 0 for x in host_items),
            "Média": sum(x["medium"] > 0 for x in host_items),
            "Baixa": sum(x["low"] > 0 for x in host_items),
        },
    }


def build_payload(unique: dict, metadata: dict, target: float) -> dict:
    rows = list(unique.values())
    models = {"Consolidado": summarize(rows, target)}
    for team in TEAM_ORDER:
        models[team] = summarize([x for x in rows if x["team"] == team], target)
    platform_models = {}
    for team in ("Consolidado", *TEAM_ORDER):
        team_rows = rows if team == "Consolidado" else [x for x in rows if x["team"] == team]
        platform_models[team] = {
            platform: summarize(team_rows if platform == "Todos" else [x for x in team_rows if x["platform"] == platform], target)
            for platform in ("Todos", "Linux", "Windows", "Outro/indefinido")
        }
    public_metadata = {key: value for key, value in metadata.items() if key != "invalid_groups"}
    return {"models": models, "platformModels": platform_models, "metadata": public_metadata, "target": target}


def column_index(reference: str) -> int:
    letters = re.match(r"[A-Z]+", reference or "A").group(0)
    number = 0
    for letter in letters:
        number = number * 26 + ord(letter) - 64
    return number - 1


def xlsx_rows(archive: zipfile.ZipFile, sheet_number: int, shared: list[str]):
    with archive.open(f"xl/worksheets/sheet{sheet_number}.xml") as source:
        for _, element in ET.iterparse(source, events=("end",)):
            if element.tag != f"{XML_NS}row":
                continue
            values = [""] * 17
            for cell in element.findall(f"{XML_NS}c"):
                index = column_index(cell.get("r", "A1"))
                if index >= 17:
                    continue
                if cell.get("t") == "inlineStr":
                    node = cell.find(f"{XML_NS}is")
                    value = "" if node is None else "".join(node.itertext())
                else:
                    node = cell.find(f"{XML_NS}v")
                    value = "" if node is None else node.text or ""
                    if cell.get("t") == "s" and value:
                        value = shared[int(value)]
                values[index] = value
            yield values
            element.clear()


def load_asset_context(path: Path | None) -> dict:
    """Lê somente os totais de assets; não importa status/perfis de baseline."""
    teams = {2: "Claro TI", 3: "BCC", 4: "Star One", 5: "Engenharia de Vídeo"}
    metrics = ("inventory", "inUse", "withAgent", "collected", "notCollected")
    result = {team: {} for team in teams.values()}
    if path is None or not path.is_file():
        return {"available": False, "models": {}}
    with zipfile.ZipFile(path) as archive:
        shared = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            shared = ["".join(node.itertext()) for node in root.findall(f"{XML_NS}si")]
        for sheet_number, team in teams.items():
            rows = iter(xlsx_rows(archive, sheet_number, shared))
            headers = {fold(value): i for i, value in enumerate(next(rows, [])) if clean(value)}
            grouped = defaultdict(Counter)
            for row in rows:
                if not clean(row[headers.get("chave", 0)]):
                    continue
                domain = fold(row[headers["dominio"]])
                platform = "Windows" if "windows" in domain else "Linux" if "linux" in domain or "unix" in domain else "Outro/indefinido"
                fields = {"inventory": "ativos", "inUse": "em_uso", "withAgent": "com_agent", "collected": "escaneados", "notCollected": "nao_escaneados"}
                for output, source in fields.items():
                    try:
                        grouped[platform][output] += int(float(row[headers[source]] or 0))
                    except (ValueError, TypeError):
                        pass
            grouped["Todos"] = Counter({key: sum(grouped[p][key] for p in grouped if p != "Todos") for key in metrics})
            result[team] = {name: {key: counter[key] for key in metrics} for name, counter in grouped.items()}
    consolidated = {}
    for platform in ("Todos", "Linux", "Windows", "Outro/indefinido"):
        consolidated[platform] = {key: sum(result[t].get(platform, {}).get(key, 0) for t in result) for key in metrics}
    result["Consolidado"] = consolidated
    return {"available": True, "models": result, "source": path.name}


HTML = r'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Auditorias de Hardening — Visão Consolidada</title><style>
:root{--red:#ef241c;--navy:#09243d;--green:#00a878;--orange:#ff7900;--yellow:#ffba00;--lime:#84bd00;--ink:#162636;--muted:#71808d;--line:#dfe5e9;--panel:#f4f6f7;--dark:#5b5757}*{box-sizing:border-box}body{margin:0;font-family:Segoe UI,Arial,sans-serif;color:var(--ink);background:white}.top{min-height:106px;padding:20px 34px;display:flex;align-items:center;gap:22px;border-bottom:1px solid var(--line)}.logo{width:64px;height:64px;object-fit:contain}.top h1{margin:0;font-size:clamp(24px,3vw,42px);color:#050505}.top p{margin:6px 0 0;color:var(--muted)}.stamp{margin-left:auto;text-align:right;color:var(--muted);font-size:13px}.nav{padding:14px 34px;background:#fafafa;display:flex;align-items:center;gap:14px;border-bottom:1px solid var(--line);position:sticky;top:0;z-index:5}.nav label{font-weight:700}.nav select,.search{padding:9px 12px;border:1px solid #ccd5db;border-radius:4px;background:#fff}.scope{margin-left:auto;font-size:13px;color:var(--muted)}main{padding:26px 34px;max-width:1550px;margin:auto}.grid{display:grid;grid-template-columns:1.05fr 2.2fr 1fr;gap:12px}.box{border:1px solid var(--line);background:#fff;min-width:0}.head{background:var(--dark);color:#fff;text-align:center;padding:6px 10px;font-size:13px;font-weight:700}.body{padding:14px}.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:9px}.kpi{padding:13px;border:1px solid var(--line);border-left:5px solid var(--red);min-height:80px}.kpi.orange{border-left-color:var(--orange)}.kpi.yellow{border-left-color:var(--yellow)}.kpi.green{border-left-color:var(--lime)}.kpi strong{display:block;font-size:26px}.kpi small{color:var(--muted)}.ringrow{display:flex;align-items:center;justify-content:center;gap:24px;min-height:175px}.ring{--v:0;--c:var(--green);width:128px;height:128px;border-radius:50%;background:conic-gradient(var(--c) calc(var(--v)*1%),#e8ecef 0);display:grid;place-items:center}.ring:after{content:"";width:86px;height:86px;background:#fff;border-radius:50%}.ringtext{position:absolute;text-align:center}.ringtext strong{display:block;font-size:25px}.legend{font-size:13px;line-height:2}.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:6px}.teams{display:grid;grid-template-columns:repeat(5,1fr);gap:8px}.teamcard{border:1px solid var(--line);padding:10px;cursor:pointer;background:#fff;text-align:left}.teamcard:hover{border-color:var(--red)}.teamcard strong{display:block;font-size:19px}.teamcard span{font-size:12px;color:var(--muted)}.section{margin-top:12px}.twocol{display:grid;grid-template-columns:1.45fr 1fr;gap:12px}.bars{display:grid;gap:8px}.bar{display:grid;grid-template-columns:160px 1fr 62px;gap:8px;align-items:center;font-size:12px}.bar label{overflow:hidden;text-overflow:ellipsis}.track{height:18px;background:#edf0f2;display:flex}.a{background:var(--red)}.m{background:var(--orange)}.b{background:var(--yellow)}.tablewrap{max-height:430px;overflow:auto}table{border-collapse:collapse;width:100%;font-size:12px}th{position:sticky;top:0;background:#eceeef;text-align:left;padding:7px;border-bottom:2px solid #cbd2d7}td{padding:7px;border-bottom:1px solid var(--line)}.num{text-align:right}.risk{color:white;padding:3px 7px;border-radius:3px}.Alta{background:var(--red)}.Média{background:var(--orange)}.Baixa{background:var(--lime)}.quality{background:#f7f8f9;border-left:4px solid var(--navy);padding:13px;font-size:12px;color:#536270}.filters{display:flex;gap:8px;margin:10px 0}.empty{text-align:center;color:var(--muted);padding:30px}.foot{text-align:center;color:var(--muted);font-size:12px;padding:20px}@media(max-width:950px){.grid,.twocol{grid-template-columns:1fr}.kpis,.teams{grid-template-columns:repeat(2,1fr)}.nav{position:static;flex-wrap:wrap}.scope{width:100%;margin:0}main{padding:15px}.top{padding:15px}.stamp{display:none}}@media(max-width:520px){.kpis,.teams{grid-template-columns:1fr}.bar{grid-template-columns:100px 1fr 45px}}
.teams{grid-template-columns:repeat(6,1fr)}@media(max-width:1100px){.teams{grid-template-columns:repeat(3,1fr)}}@media(max-width:950px){.teams{grid-template-columns:repeat(2,1fr)}}@media(max-width:520px){.teams{grid-template-columns:1fr}}
.platform-options{display:flex;border:1px solid #ccd5db;border-radius:5px;overflow:hidden}.platform-options button{padding:8px 15px;border:0;border-right:1px solid #ccd5db;background:#fff;color:var(--ink);cursor:pointer}.platform-options button:last-child{border-right:0}.platform-options button.active{background:var(--navy);color:#fff;font-weight:700}
</style></head><body>
<header class="top"><img class="logo" src="__LOGO__" alt="Claro"><div><h1>Auditorias de Hardening</h1><p>Todos os hosts auditados · visão consolidada dos últimos 15 dias</p></div><div class="stamp">Fonte<br><strong>__SOURCE__</strong><br>Gerado em __DATE__</div></header>
<nav class="nav"><strong>Sistema</strong><div class="platform-options" id="platformOptions"><button class="active" data-platform="Todos">Todos</button><button data-platform="Linux">Linux</button><button data-platform="Windows">Windows</button></div><span><strong>Visão:</strong> <span id="currentTeam">Consolidado</span></span><span class="scope">Somente audits no padrão <strong>ID, nome, criticidade</strong></span></nav>
<main><div class="grid">
 <section class="box"><div class="head">% Aderência</div><div class="body ringrow"><div style="position:relative"><div class="ring" id="ring"></div><div class="ringtext"><strong id="adherence">0%</strong><small>aprovados</small></div></div></div></section>
 <section class="box"><div class="head">Não conformidades por criticidade</div><div class="body kpis"><div class="kpi"><strong id="high">0</strong><small>Alta · <b id="highHosts">0</b> assets afetados</small></div><div class="kpi orange"><strong id="medium">0</strong><small>Média · <b id="mediumHosts">0</b> assets afetados</small></div><div class="kpi yellow"><strong id="low">0</strong><small>Baixa · <b id="lowHosts">0</b> assets afetados</small></div><div class="kpi green"><strong id="failed">0</strong><small>Total reprovados</small></div></div></section>
 <section class="box"><div class="head">Assets</div><div class="body"><div class="kpi green"><strong id="hosts">0</strong><small>hosts auditados</small></div><div class="kpi orange" style="margin-top:9px"><strong id="controls">0</strong><small>controles distintos</small></div></div></section>
</div>
<section class="box section"><div class="head">Assets — contexto de inventário</div><div class="body kpis"><div class="kpi green"><strong id="collected">—</strong><small>Coletados (escaneados)</small></div><div class="kpi orange"><strong id="notCollected">—</strong><small>Não coletados</small></div><div class="kpi"><strong id="inventory">—</strong><small>Inventário (ativos)</small></div><div class="kpi yellow"><strong id="withAgent">—</strong><small>Com agent</small></div></div><div class="quality" id="assetContextNote"></div></section>
<section class="box section"><div class="head">Visão geral e equipes identificadas por tags — clique para filtrar</div><div class="body teams" id="teams"></div></section>
<div class="twocol section"><section class="box"><div class="head">Hosts prioritários</div><div class="body"><div class="legend"><i class="dot" style="background:var(--red)"></i>Alta &nbsp;<i class="dot" style="background:var(--orange)"></i>Média &nbsp;<i class="dot" style="background:var(--yellow)"></i>Baixa</div><div class="bars" id="bars"></div></div></section><section class="box"><div class="head">Não conformidades recorrentes</div><div class="tablewrap"><table><thead><tr><th>ID / Controle</th><th>Risco</th><th class="num">Falhas</th><th class="num">Taxa</th></tr></thead><tbody id="controlTop"></tbody></table></div></section></div>
<section class="box section"><div class="head">Hosts</div><div class="body"><div class="filters"><input class="search" id="search" placeholder="Buscar hostname, IP ou SO"><span id="count"></span></div><div class="tablewrap"><table><thead><tr><th>Host / IP</th><th>Sistema operacional</th><th class="num">Alta</th><th class="num">Média</th><th class="num">Baixa</th><th class="num">Falhas</th><th class="num">Aderência</th><th>Status</th></tr></thead><tbody id="hostRows"></tbody></table></div></div></section>
<section class="box section"><div class="head">Backlog completo por controle</div><div class="tablewrap"><table><thead><tr><th>ID</th><th>Controle</th><th>Criticidade</th><th class="num">Reprovados</th><th class="num">Aprovados</th><th class="num">Taxa de reprovação</th></tr></thead><tbody id="controlRows"></tbody></table></div></section>
<aside class="quality section" id="quality"></aside></main><footer class="foot">Dashboard autocontido · Indicadores de Hardening Unix · Claro</footer>
<script>const DATA=__DATA__;const fmt=n=>Number(n||0).toLocaleString('pt-BR'),pct=n=>Number(n||0).toLocaleString('pt-BR',{minimumFractionDigits:1,maximumFractionDigits:1})+'%';const $=id=>document.getElementById(id);let current='Consolidado',platform='Todos';const model=()=>DATA.platformModels[current][platform];
function badge(r){return `<span class="risk ${r}">${r}</span>`}function draw(){const m=model(),ctx=DATA.assetContext,assets=ctx.available&&ctx.models[current]&&ctx.models[current][platform];$('currentTeam').textContent=current;$('adherence').textContent=pct(m.adherence);$('ring').style.setProperty('--v',m.adherence);$('high').textContent=fmt(m.severity.Alta);$('medium').textContent=fmt(m.severity.Média);$('low').textContent=fmt(m.severity.Baixa);$('highHosts').textContent=fmt(m.affected.Alta);$('mediumHosts').textContent=fmt(m.affected.Média);$('lowHosts').textContent=fmt(m.affected.Baixa);$('failed').textContent=fmt(m.failed);$('hosts').textContent=fmt(m.hostCount);$('controls').textContent=fmt(m.controlCount);for(const [id,key] of [['collected','collected'],['notCollected','notCollected'],['inventory','inventory'],['withAgent','withAgent']])$(id).textContent=assets?fmt(assets[key]):'—';$('assetContextNote').innerHTML=ctx.available?`Fonte de inventário: <strong>${ctx.source}</strong>. “Coletados” = escaneados; “Não coletados” = nao_escaneados. End of Life não é exibido porque não existe campo confiável na fonte.`:'Contexto de inventário indisponível.';const max=Math.max(1,...m.hosts.slice(0,10).map(x=>x.failed));$('bars').innerHTML=m.hosts.slice(0,10).map(x=>`<div class="bar"><label title="${x.host}"><b>${x.host}</b><br>${x.ip}</label><div class="track"><i class="a" style="width:${x.high/max*100}%"></i><i class="m" style="width:${x.medium/max*100}%"></i><i class="b" style="width:${x.low/max*100}%"></i></div><b>${fmt(x.failed)}</b></div>`).join('')||`<div class="empty">Sem audits válidos para ${current} · ${platform}.</div>`;$('controlTop').innerHTML=controlHtml(m.controls.filter(x=>x.failed).slice(0,10));$('controlRows').innerHTML=controlHtml(m.controls,true);drawHosts()}
function controlHtml(rows,full=false){return rows.map(x=>full?`<tr><td><b>${x.id}</b></td><td>${x.name}</td><td>${badge(x.severity)}</td><td class="num">${fmt(x.failed)}</td><td class="num">${fmt(x.passed)}</td><td class="num">${pct(x.rate)}</td></tr>`:`<tr><td><b>${x.id}</b> · ${x.name}</td><td>${badge(x.severity)}</td><td class="num">${fmt(x.failed)}</td><td class="num">${pct(x.rate)}</td></tr>`).join('')}
function drawHosts(){const q=$('search').value.toLocaleLowerCase('pt-BR'),m=model(),rows=m.hosts.filter(x=>(x.host+' '+x.ip+' '+x.os).toLocaleLowerCase('pt-BR').includes(q));$('count').textContent=`${fmt(rows.length)} de ${fmt(m.hostCount)} hosts`;$('hostRows').innerHTML=rows.map(x=>`<tr><td><b>${x.host}</b><br><small>${x.ip}</small></td><td>${x.os}</td><td class="num">${fmt(x.high)}</td><td class="num">${fmt(x.medium)}</td><td class="num">${fmt(x.low)}</td><td class="num"><b>${fmt(x.failed)}</b></td><td class="num">${pct(x.adherence)}</td><td>${x.atTarget?'Na meta':'Abaixo da meta'}</td></tr>`).join('')}
const names=Object.keys(DATA.models);$('teams').innerHTML=names.map(x=>{const m=DATA.models[x];return `<button class="teamcard" data-team="${x}"><strong>${fmt(m.hostCount)}</strong><span>${x}<br>${pct(m.adherence)} aderência</span></button>`}).join('');$('platformOptions').onclick=e=>{const b=e.target.closest('button');if(b){platform=b.dataset.platform;document.querySelectorAll('#platformOptions button').forEach(x=>x.classList.toggle('active',x===b));draw()}};$('teams').onclick=e=>{const b=e.target.closest('button');if(b){current=b.dataset.team;draw()}};$('search').oninput=drawHosts;const q=DATA.metadata.quality;$('quality').innerHTML=`<strong>Qualidade e rastreabilidade:</strong> ${fmt(q.rows)} linhas lidas e ${fmt(q.source_hosts)} hosts encontrados na fonte; ${fmt(q.records_used)} combinações únicas host+controle usadas. ${fmt(q.outside_pattern)} linhas fora do padrão foram encaminhadas ao relatório separado; ${fmt(q.utility_rows)} linhas de IDs utilitários acima de 999 foram ignoradas; ${fmt(q.duplicates)} duplicidades foram consolidadas pela observação mais recente; ${fmt(q.bad_tags)} tags JSON inválidas.`;draw();</script></body></html>'''


def render(payload: dict, source: Path, output: Path) -> None:
    logo = HERE / "Claro.png"
    logo_data = "data:image/png;base64," + base64.b64encode(logo.read_bytes()).decode() if logo.is_file() else ""
    data = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    document = (HTML.replace("__LOGO__", html.escape(logo_data, quote=True))
                .replace("__SOURCE__", html.escape(source.name))
                .replace("__DATE__", datetime.now().astimezone().strftime("%d/%m/%Y %H:%M %Z"))
                .replace("__DATA__", data))
    output.write_text(document, encoding="utf-8")


INVALID_HTML = r'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Audits para mapear e corrigir</title><style>
body{font-family:Segoe UI,Arial,sans-serif;margin:0;color:#182634}header{background:#ef241c;color:white;padding:24px 32px}header h1{margin:0 0 6px}main{padding:24px 32px}.note{padding:14px;background:#fff4d6;border-left:5px solid #ffba00;margin-bottom:18px}.filters{display:flex;gap:10px;margin-bottom:12px;flex-wrap:wrap}input,select{padding:9px;border:1px solid #ccd5db}table{border-collapse:collapse;width:100%;font-size:13px}th{background:#575454;color:#fff;text-align:left;padding:8px;position:sticky;top:0}td{padding:8px;border-bottom:1px solid #dfe5e9;vertical-align:top}.num{text-align:right}.wrap{max-height:70vh;overflow:auto}small{color:#687784}@media(max-width:700px){main{padding:12px}.wrap{overflow:auto}table{min-width:1000px}}</style></head><body>
<header><h1>Audits para mapear e corrigir</h1><div>Registros fora de <strong>ID, nome, criticidade</strong> · __SOURCE__</div></header><main><div class="note"><strong>Arquivo auxiliar:</strong> estes registros não participam dos indicadores oficiais. IDs numéricos maiores que 999 foram ignorados como utilitários e não aparecem aqui.</div><div class="filters"><select id="system"><option>Todos</option><option>Linux</option><option>Windows</option><option>Outro/indefinido</option></select><input id="search" placeholder="Buscar audit, arquivo, equipe ou host"><span id="count"></span></div><div class="wrap"><table><thead><tr><th>Sistema</th><th>Equipe</th><th>Audit name</th><th>Audit file</th><th>Status</th><th class="num">Linhas</th><th class="num">Hosts</th><th>Exemplo</th></tr></thead><tbody id="rows"></tbody></table></div></main><script>
const DATA=__DATA__,fmt=n=>Number(n||0).toLocaleString('pt-BR'),$=x=>document.getElementById(x);function draw(){const sys=$('system').value,q=$('search').value.toLocaleLowerCase('pt-BR'),rows=DATA.filter(x=>(sys==='Todos'||x.platform===sys)&&(x.platform+' '+x.team+' '+x.name+' '+x.file+' '+x.sampleHost).toLocaleLowerCase('pt-BR').includes(q));$('count').textContent=`${fmt(rows.length)} grupos · ${fmt(rows.reduce((n,x)=>n+x.rows,0))} linhas`;$('rows').innerHTML=rows.map(x=>`<tr><td><b>${x.platform}</b></td><td>${x.team}</td><td>${x.name}</td><td>${x.file}</td><td>${x.status}</td><td class="num">${fmt(x.rows)}</td><td class="num">${fmt(x.hostCount)}</td><td><b>${x.sampleHost}</b><br><small>${x.sampleOutput||'—'}</small></td></tr>`).join('')}$('system').onchange=draw;$('search').oninput=draw;draw();</script></body></html>'''


def render_invalid(metadata: dict, source: Path, output: Path) -> None:
    data = json.dumps(metadata["invalid_groups"], ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    document = INVALID_HTML.replace("__SOURCE__", html.escape(source.name)).replace("__DATA__", data)
    output.write_text(document, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard de hardening consolidado do export host-audits.")
    parser.add_argument("entrada", nargs="?", type=Path, default=Path("host-audits-08_27_2026_-13_57_09-gmt-3.csv"))
    parser.add_argument("-o", "--saida", type=Path, default=Path("dashboard_hardening_host_audits.html"))
    parser.add_argument("--saida-audits-fora-padrao", type=Path, default=Path("audits_fora_do_padrao.html"), help="HTML auxiliar para mapeamento e correção")
    parser.add_argument("--contexto-assets-xlsx", type=Path, default=Path("status_baselines_todos_2026-08-27.xlsx"), help="XLSX usado somente nos totais de inventário/assets")
    parser.add_argument("--meta", type=float, default=80.0, help="Meta de aderência por host (padrão: 80)")
    parser.add_argument("--excluir-ids", default="999,1000,1001", help="IDs separados por vírgula")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if not 0 < args.meta <= 100:
            raise ValueError("A meta deve estar entre 0 e 100.")
        source = args.entrada.expanduser().resolve()
        if not source.is_file():
            raise ValueError(f"CSV não encontrado: {source}")
        excluded = {clean(x) for x in args.excluir_ids.split(",") if clean(x)}
        unique, metadata = load(source, excluded)
        payload = build_payload(unique, metadata, args.meta)
        context_path = args.contexto_assets_xlsx.expanduser().resolve() if args.contexto_assets_xlsx else None
        payload["assetContext"] = load_asset_context(context_path)
        output = args.saida.expanduser().resolve()
        invalid_output = args.saida_audits_fora_padrao.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        invalid_output.parent.mkdir(parents=True, exist_ok=True)
        render(payload, source, output)
        render_invalid(metadata, source, invalid_output)
        model = payload["models"]["Consolidado"]
        print(f"Dashboard gerado: {output}")
        print(f"Audits fora do padrão: {invalid_output}")
        print(f"{metadata['quality']['rows']:,} linhas lidas | {model['hostCount']} hosts | {model['failed']:,} reprovados | {model['adherence']:.1f}% aderência")
        for team in TEAM_ORDER:
            item = payload["models"][team]
            print(f"- {team}: {item['hostCount']} hosts | {item['failed']:,} reprovados | {item['adherence']:.1f}%")
        return 0
    except (OSError, UnicodeError, ValueError, csv.Error) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
