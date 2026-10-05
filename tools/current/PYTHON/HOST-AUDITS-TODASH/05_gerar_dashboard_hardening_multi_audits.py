#!/usr/bin/env python3
"""Dashboard multi-equipe e multi-perfil orientado por compliance.audit_file.

Aceita um mega CSV ou varios exports na mesma execucao. O nome fisico do arquivo
nao classifica os dados; a taxonomia interna do audit e a fonte da verdade.
"""

from __future__ import annotations

import argparse
import base64
from collections import Counter, defaultdict
import csv
from dataclasses import dataclass
from datetime import datetime
import html
import importlib.util
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET
import zipfile


HERE = Path(__file__).resolve().parent
BASE_PATH = HERE / "02_gerar_dashboard_hardening_equipe.py"
AUDIT_RE = re.compile(
    r"^(?P<kind>[^_]+)_(?P<team>[^_]+)_(?P<profile>.+)_(?P<stamp>\d{12})(?:\.audit)?$",
    re.IGNORECASE,
)
VERSION_RE = re.compile(r"^(?P<family>.+?)[_-](?P<version>V\d+(?:\.\d+)*(?:[-._][A-Z0-9]+)?)$", re.I)
SUPPORTED = {".csv", ".tsv", ".xlsx"}


def load_base():
    spec = importlib.util.spec_from_file_location("hardening_base_02", BASE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Nao foi possivel carregar {BASE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


BASE = load_base()


@dataclass(frozen=True)
class Taxonomy:
    audit_file: str
    kind: str
    team: str
    profile: str
    profile_family: str
    version: str
    published: datetime

    @property
    def series_key(self) -> tuple[str, str, str]:
        return self.kind.casefold(), self.team.casefold(), self.profile_family.casefold()


def clean(value: object) -> str:
    return BASE.CORE.clean(value)


def taxonomy(value: object) -> Taxonomy | None:
    raw = clean(value)
    match = AUDIT_RE.fullmatch(raw)
    if not match:
        return None
    try:
        published = datetime.strptime(match.group("stamp"), "%d%m%Y%H%M")
    except ValueError:
        return None
    profile = match.group("profile")
    version_match = VERSION_RE.fullmatch(profile)
    family = version_match.group("family") if version_match else profile
    version = version_match.group("version") if version_match else "—"
    return Taxonomy(raw, match.group("kind"), match.group("team"), profile, family, version, published)


def expand_inputs(entries: list[Path]) -> list[Path]:
    paths: list[Path] = []
    for entry in entries:
        entry = entry.expanduser().resolve()
        if entry.is_dir():
            paths.extend(sorted(p for p in entry.iterdir() if p.is_file() and p.suffix.casefold() in SUPPORTED))
        elif entry.is_file() and entry.suffix.casefold() in SUPPORTED:
            paths.append(entry)
        else:
            raise ValueError(f"Entrada nao encontrada ou nao suportada: {entry}")
    unique = list(dict.fromkeys(paths))
    if not unique:
        raise ValueError("Nenhum CSV, TSV ou XLSX foi informado.")
    return unique


def observed(row: dict) -> str:
    return clean(row.get("last_observed") or row.get("first_seen"))


def load_all(paths: list[Path], excluded: set[str]):
    audits: dict[str, Taxonomy] = {}
    unique: dict[tuple[str, str, str], dict] = {}
    quality = Counter(files=len(paths))
    invalid_files = Counter()
    for path in paths:
        try:
            records = BASE.CORE.load_records(path)
            for row in records:
                quality["rows"] += 1
                tax = taxonomy(row.get("compliance.audit_file"))
                if tax is None:
                    quality["outside_taxonomy"] += 1
                    invalid_files[clean(row.get("compliance.audit_file")) or "(vazio)"] += 1
                    continue
                audits.setdefault(tax.audit_file.casefold(), tax)
                host = clean(row.get("asset.host_name") or row.get("asset.name"))
                control_id = BASE.CORE.normalize_id(row.get("compliance.audit_ID"))
                if control_id in excluded or (control_id.isdigit() and int(control_id) > 999):
                    quality["excluded"] += 1
                    continue
                if not host or not control_id:
                    quality["ignored"] += 1
                    continue
                item = {
                    "audit": tax.audit_file.casefold(), "host": host,
                    "ip": clean(row.get("asset.ip_addresses")),
                    "os": clean(row.get("asset.operating_systems")),
                    "id": control_id, "name": clean(row.get("compliance.audit_name")),
                    "severity": BASE.CORE.normalize_severity(row.get("compliance.audit_criticidade")),
                    "status": BASE.CORE.normalize_status(row.get("compliance_result")),
                    "observed": observed(row), "source": path.name,
                }
                key = (item["audit"], host.casefold(), control_id)
                previous = unique.get(key)
                if previous is not None:
                    quality["duplicates"] += 1
                if previous is None or (item["observed"], item["source"]) >= (previous["observed"], previous["source"]):
                    unique[key] = item
        except (OSError, UnicodeError, ValueError, csv.Error, zipfile.BadZipFile, ET.ParseError) as error:
            raise ValueError(f"Falha ao ler {path.name}: {error}") from error
    quality["audits"] = len(audits)
    quality["records"] = len(unique)
    return audits, unique, dict(quality), invalid_files


def model_for(rows: list[dict], target: float) -> dict:
    normalized = ({
        "asset.host_name": r["host"], "asset.ip_addresses": r["ip"],
        "asset.operating_systems": r["os"], "compliance.audit_ID": r["id"],
        "compliance.audit_name": r["name"], "compliance.audit_criticidade": r["severity"],
        "compliance_result": r["status"],
    } for r in rows)
    return BASE.CORE.build_model(normalized, set(), target)


def public_model(model: dict) -> dict:
    return {
        "hostCount": model["server_count"], "controlCount": model["control_count"],
        "passed": model["passed"], "failed": model["failed"], "unknown": model["unknown"],
        "evaluated": model["evaluated"], "adherence": round(model["average"], 2),
        "atTarget": model["at_target"], "highHosts": model["high_affected_hosts"],
        "severity": dict(model["severity_failures"]),
        "hosts": [{
            "host": x["host"], "ip": x["ip"], "os": x["os"], "passed": x["passed"],
            "failed": x["failed"], "unknown": x["unknown"], "high": x["high"],
            "medium": x["medium"], "low": x["low"], "adherence": round(x["adherence"], 2),
            "atTarget": x["at_target"],
        } for x in model["servers"]],
        "controls": [{
            "id": x["id"], "name": x["name"], "severity": x["severity"],
            "failed": x["failed"], "passed": x["passed"], "total": x["total"],
            "failureRate": round(x["failure_rate"], 2),
        } for x in model["controls"]],
    }


def build_payload(audits, unique, quality, invalid_files, target: float) -> dict:
    rows_by_audit = defaultdict(list)
    for row in unique.values():
        rows_by_audit[row["audit"]].append(row)
    snapshots = []
    for key, tax in audits.items():
        rows = rows_by_audit[key]
        if not rows:
            continue
        observation_values = [x["observed"] for x in rows if x["observed"]]
        snapshots.append({
            "id": tax.audit_file, "kind": tax.kind.upper(), "team": tax.team.upper(),
            "profile": tax.profile.upper(), "profileFamily": tax.profile_family.upper(),
            "version": tax.version.upper(), "published": tax.published.isoformat(),
            "publishedLabel": tax.published.strftime("%d/%m/%Y %H:%M"),
            "observedFrom": min(observation_values, default="—"),
            "observedTo": max(observation_values, default="—"),
            "model": public_model(model_for(rows, target)),
        })
    snapshots.sort(key=lambda x: (x["team"], x["profileFamily"], x["published"]))
    series = defaultdict(list)
    for item in snapshots:
        series[(item["kind"], item["team"], item["profileFamily"])].append(item["id"])
    latest_ids = {ids[-1] for ids in series.values()}
    latest_rows = [row for row in unique.values() if audits[row["audit"]].audit_file in latest_ids]
    overview = public_model(model_for(latest_rows, target)) if latest_rows else public_model(model_for([], target))
    return {
        "target": target, "overview": overview, "snapshots": snapshots,
        "series": [{"kind": k[0], "team": k[1], "profile": k[2], "audits": ids} for k, ids in series.items()],
        "quality": quality,
        "invalidAudits": [{"name": name, "rows": count} for name, count in invalid_files.most_common(20)],
    }


HTML = r'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Compliance · Multi-audits</title><style>
:root{--red:#e30613;--dark:#161b22;--muted:#667085;--line:#e5e7eb;--bg:#f5f6f8;--ok:#168447;--warn:#d97706;--bad:#c81e1e}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--dark);font:14px/1.45 Segoe UI,Arial,sans-serif}header{background:var(--red);color:#fff;padding:20px 4%;display:flex;align-items:center;gap:20px}header img{width:70px;height:70px;object-fit:contain}header h1{margin:0;font-size:26px}header p{margin:4px 0 0}main{max-width:1500px;margin:auto;padding:24px}.notice{background:#fff8db;border-left:4px solid var(--warn);padding:12px 16px;margin-bottom:18px;border-radius:8px}.filters,.cards,.grid{display:grid;gap:14px}.filters{grid-template-columns:repeat(3,minmax(180px,1fr));background:#fff;padding:16px;border:1px solid var(--line);border-radius:12px}.filters label{font-size:12px;font-weight:700;color:var(--muted)}select,input{width:100%;margin-top:5px;padding:9px;border:1px solid #cfd4dc;border-radius:7px;background:#fff}.cards{grid-template-columns:repeat(6,1fr);margin:16px 0}.metric,.panel{background:#fff;border:1px solid var(--line);border-radius:12px}.metric{padding:15px;border-top:4px solid var(--red)}.metric strong{font-size:25px;display:block}.metric span{color:var(--muted);font-size:12px}.panel{margin:16px 0;overflow:hidden}.panel h2{font-size:14px;text-transform:uppercase;letter-spacing:.04em;margin:0;padding:14px 16px;border-bottom:1px solid var(--line);background:#fafafa}.body{padding:16px}.identity{font-family:ui-monospace,monospace;overflow-wrap:anywhere}.meta{color:var(--muted);margin-top:6px}.history{display:flex;align-items:end;gap:12px;min-height:210px;padding:18px 10px 0;border-bottom:1px solid var(--line);overflow-x:auto}.point{min-width:105px;text-align:center}.bar{height:140px;display:flex;align-items:end;justify-content:center}.bar i{display:block;width:44px;background:var(--red);border-radius:6px 6px 0 0;min-height:2px}.point strong,.point small{display:block}.point small{color:var(--muted)}.tables{display:grid;grid-template-columns:1fr 1fr;gap:16px}table{width:100%;border-collapse:collapse}th,td{padding:9px 10px;border-bottom:1px solid var(--line);text-align:left}th{font-size:11px;text-transform:uppercase;color:var(--muted);position:sticky;top:0;background:#fff}.scroll{max-height:520px;overflow:auto}.num{text-align:right}.risk{font-weight:700}.Alta{color:var(--bad)}.Média{color:var(--warn)}.Baixa{color:#687400}.quality{color:var(--muted);font-size:12px}footer{text-align:center;color:var(--muted);padding:22px}@media(max-width:1000px){.cards{grid-template-columns:repeat(3,1fr)}.tables{grid-template-columns:1fr}}@media(max-width:650px){.filters,.cards{grid-template-columns:1fr 1fr}main{padding:12px}header{padding:15px}.tables{display:block}}
button.metric{text-align:left;cursor:pointer;color:inherit}button.metric:hover{border-color:var(--red);background:#fff8f8}
</style></head><body><header><img src="__LOGO__" alt="Claro"><div><h1>Compliance · Multi-audits</h1><p>Equipes, perfis, snapshots de baseline e evolução histórica</p></div></header><main>
<div class="notice"><strong>Prévia:</strong> a data da série vem da taxonomia de <code>compliance.audit_file</code>. <code>first_seen</code> e <code>last_observed</code> são usados para rastreabilidade e desempate.</div>
<section class="panel"><h2>Mapa encontrado — todas as equipes</h2><div class="body cards" id="teamMap"></div></section>
<section class="filters"><label>Equipe<select id="team"></select></label><label>Perfil / série<select id="series"></select></label><label>Snapshot do audit<select id="audit"></select></label></section>
<section class="cards" id="cards"></section>
<section class="panel"><h2>Identidade do snapshot</h2><div class="body" id="identity"></div></section>
<section class="panel"><h2>Série histórica do perfil</h2><div class="body"><div class="history" id="history"></div></div></section>
<section class="tables"><article class="panel"><h2>Hosts prioritários</h2><div class="scroll"><table><thead><tr><th>Host</th><th class="num">Alta</th><th class="num">Falhas</th><th class="num">Aderência</th></tr></thead><tbody id="hosts"></tbody></table></div></article><article class="panel"><h2>Controles prioritários</h2><div class="scroll"><table><thead><tr><th>ID / controle</th><th>Risco</th><th class="num">Falhas</th><th class="num">Taxa</th></tr></thead><tbody id="controls"></tbody></table></div></article></section>
<section class="panel"><h2>Qualidade e rastreabilidade</h2><div class="body quality" id="quality"></div></section>
</main><footer>Dashboard autocontido · gerado em __GENERATED__</footer><script>const DATA=__DATA__,byId=Object.fromEntries(DATA.snapshots.map(x=>[x.id,x])),team=document.querySelector('#team'),series=document.querySelector('#series'),audit=document.querySelector('#audit'),fmt=n=>Number(n||0).toLocaleString('pt-BR'),pct=n=>Number(n||0).toLocaleString('pt-BR',{minimumFractionDigits:1,maximumFractionDigits:1})+'%',esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const teams=[...new Set(DATA.series.map(x=>x.team))].sort((a,b)=>DATA.snapshots.filter(x=>x.team===b).length-DATA.snapshots.filter(x=>x.team===a).length||a.localeCompare(b));team.innerHTML=teams.map(x=>`<option>${esc(x)}</option>`).join('');document.querySelector('#teamMap').innerHTML=teams.map(x=>{const ss=DATA.series.filter(s=>s.team===x),aa=DATA.snapshots.filter(a=>a.team===x);return `<button class="metric" data-team="${esc(x)}"><strong>${fmt(aa.length)}</strong><span>${esc(x)}<br>${fmt(ss.length)} séries</span></button>`}).join('');document.querySelector('#teamMap').onclick=e=>{const b=e.target.closest('[data-team]');if(b){team.value=b.dataset.team;fillSeries()}};function fillSeries(){const xs=DATA.series.filter(x=>x.team===team.value);series.innerHTML=xs.map((x,i)=>`<option value="${i}">${esc(x.kind+' · '+x.profile)}</option>`).join('');series._items=xs;fillAudits()}function currentSeries(){return series._items[+series.value]}function fillAudits(){const s=currentSeries();audit.innerHTML=(s?.audits||[]).map(id=>{const x=byId[id];return `<option value="${esc(id)}">${esc(x.publishedLabel+' · '+x.profile)}</option>`}).join('');audit.selectedIndex=Math.max(0,audit.options.length-1);draw()}function draw(){const x=byId[audit.value];if(!x)return;const m=x.model,sev=m.severity;document.querySelector('#cards').innerHTML=[['Aderência',pct(m.adherence)],['Hosts',fmt(m.hostCount)],['Controles',fmt(m.controlCount)],['Reprovados',fmt(m.failed)],['Alta',fmt(sev.Alta)],['Na meta',fmt(m.atTarget)+' / '+fmt(m.hostCount)]].map(([a,b])=>`<div class="metric"><strong>${b}</strong><span>${a}</span></div>`).join('');document.querySelector('#identity').innerHTML=`<strong class="identity">${esc(x.id)}</strong><div class="meta">Tipo: ${esc(x.kind)} · Equipe: ${esc(x.team)} · Perfil: ${esc(x.profile)} · Versão: ${esc(x.version)} · Publicação: ${esc(x.publishedLabel)}<br>Observações encontradas: ${esc(x.observedFrom)} até ${esc(x.observedTo)}</div>`;drawHistory();document.querySelector('#hosts').innerHTML=m.hosts.map(h=>`<tr><td><strong>${esc(h.host)}</strong><small>${esc(h.ip)} · ${esc(h.os)}</small></td><td class="num Alta">${fmt(h.high)}</td><td class="num">${fmt(h.failed)}</td><td class="num">${pct(h.adherence)}</td></tr>`).join('');document.querySelector('#controls').innerHTML=m.controls.map(c=>`<tr><td><strong>${esc(c.id)}</strong><small>${esc(c.name)}</small></td><td class="risk ${esc(c.severity)}">${esc(c.severity)}</td><td class="num">${fmt(c.failed)}</td><td class="num">${pct(c.failureRate)}</td></tr>`).join('')}
function drawHistory(){const s=currentSeries(),xs=s.audits.map(id=>byId[id]),max=Math.max(100,...xs.map(x=>x.model.adherence));document.querySelector('#history').innerHTML=xs.map(x=>`<div class="point"><div class="bar"><i style="height:${x.model.adherence/max*140}px" title="${pct(x.model.adherence)}"></i></div><strong>${pct(x.model.adherence)}</strong><small>${esc(x.publishedLabel.slice(0,10))}</small><small>${fmt(x.model.hostCount)} hosts · ${fmt(x.model.controlCount)} controles</small></div>`).join('')}
team.onchange=fillSeries;series.onchange=fillAudits;audit.onchange=draw;const q=DATA.quality;document.querySelector('#quality').innerHTML=`${fmt(q.files)} arquivos · ${fmt(q.rows)} linhas lidas · ${fmt(q.audits)} audits válidos · ${fmt(q.records)} combinações únicas audit+host+controle · ${fmt(q.duplicates)} duplicidades consolidadas · ${fmt(q.outside_taxonomy)} linhas fora da taxonomia · ${fmt(q.excluded)} IDs excluídos · ${fmt(q.ignored)} linhas ignoradas.`;fillSeries();</script></body></html>'''


def render(payload: dict, output: Path) -> None:
    logo = HERE / "Claro.png"
    logo_data = "data:image/png;base64," + base64.b64encode(logo.read_bytes()).decode("ascii") if logo.is_file() else ""
    document = HTML.replace("__LOGO__", logo_data)
    document = document.replace("__GENERATED__", datetime.now().astimezone().strftime("%d/%m/%Y %H:%M %Z"))
    document = document.replace("__DATA__", json.dumps(payload, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/"))
    output.write_text(document, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard universal pela taxonomia de compliance.audit_file.")
    parser.add_argument("entradas", nargs="+", type=Path, help="Mega CSV, varios arquivos ou diretorios")
    parser.add_argument("-o", "--saida", type=Path, default=Path("dashboard_hardening_multi_audits.html"))
    parser.add_argument("--meta", type=float, default=80.0)
    parser.add_argument("--excluir-ids", default="999")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if not 0 < args.meta <= 100:
            raise ValueError("A meta deve estar entre 0 e 100.")
        paths = expand_inputs(args.entradas)
        excluded = {clean(x) for x in args.excluir_ids.split(",") if clean(x)}
        audits, unique, quality, invalid = load_all(paths, excluded)
        if not audits or not unique:
            raise ValueError("Nenhum registro valido com a taxonomia esperada foi encontrado.")
        payload = build_payload(audits, unique, quality, invalid, args.meta)
        output = args.saida.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        render(payload, output)
        print(f"Dashboard multi-audits gerado: {output}")
        print(f"Fontes: {len(paths)} | linhas: {quality['rows']} | audits: {quality['audits']} | registros unicos: {quality['records']}")
        print("Equipes: " + ", ".join(sorted({x['team'] for x in payload['snapshots']})))
        print("Series: " + str(len(payload["series"])))
        return 0
    except (OSError, UnicodeError, ValueError, RuntimeError, csv.Error, zipfile.BadZipFile, ET.ParseError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
