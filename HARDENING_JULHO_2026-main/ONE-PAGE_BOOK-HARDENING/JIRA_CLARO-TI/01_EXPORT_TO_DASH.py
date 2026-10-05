#!/usr/bin/env python3
"""Gera um dashboard de gestão de baselines a partir do CSV/XLSX do Jira."""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import unicodedata
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path

@dataclass(frozen=True)
class Classification:
    dominio: str
    familia: str
    versao_principal: str
    versao_detectada: str


@dataclass(frozen=True)
class Profile:
    chave: str
    dominio: str
    familia: str
    versao_principal: str
    perfil: str
    ativos: int
    em_uso: int
    producao: int
    sox: int
    sem_versao: int
    descricoes_unicas: int
    descricoes: tuple[str, ...]


LINUX_FAMILY_PATTERNS = (
    ("Oracle Linux", re.compile(r"\boracle(?:\s+linux)?\b", re.I)),
    ("RHEL", re.compile(r"\b(?:red hat enterprise linux|rhel|linux rhel)\b", re.I)),
    ("CentOS", re.compile(r"\bcentos\b", re.I)),
    ("Rocky Linux", re.compile(r"\brocky(?:\s+linux)?\b", re.I)),
    ("AlmaLinux", re.compile(r"\balma(?:linux)?\b", re.I)),
    ("Amazon Linux", re.compile(r"\bamazon linux\b", re.I)),
    ("Debian", re.compile(r"\bdebian\b", re.I)),
    ("Ubuntu", re.compile(r"\bubuntu\b", re.I)),
    ("SUSE", re.compile(r"\b(?:suse|sles)\b", re.I)),
    ("Kali", re.compile(r"\bkali\b", re.I)),
    (
        "Enterprise Linux (indefinido)",
        re.compile(r"\benterprise linux enterprise linux\b", re.I),
    ),
    ("Linux genérico", re.compile(r"\b(?:other linux|gnu/linux|linux)\b", re.I)),
)

LINUX_VERSION_PATTERNS = {
    "Oracle Linux": re.compile(
        r"\boracle(?:\s+linux)?(?:\s+server)?(?:\s+release)?\s+"
        r"(?P<version>\d+(?:\.\d+)?(?:/\d+)?)",
        re.I,
    ),
    "RHEL": re.compile(
        r"\b(?:red hat enterprise linux(?:\s+server)?|rhel|linux rhel)"
        r"(?:\s+as)?(?:\s+release)?\s+(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
    "CentOS": re.compile(
        r"\bcentos(?:\s+linux)?(?:\s+release)?\s+"
        r"(?P<version>\d+(?:\.\d+)?(?:/\d+)?)",
        re.I,
    ),
    "Rocky Linux": re.compile(
        r"\brocky(?:\s+linux)?(?:\s+release)?\s+(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
    "AlmaLinux": re.compile(
        r"\balma(?:linux)?(?:\s+release)?\s+(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
    "Amazon Linux": re.compile(r"\bamazon linux\s+(?P<version>\d+(?:\.\d+)?)", re.I),
    "Debian": re.compile(
        r"\bdebian(?:\s+gnu/linux)?(?:\s+release)?\s+"
        r"(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
    "Ubuntu": re.compile(
        r"\bubuntu(?:\s+linux)?(?:\s+release)?\s+"
        r"(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
    "SUSE": re.compile(
        r"\b(?:suse linux enterprise(?:\s+server)?|sles)"
        r"(?:\s+release)?\s+(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
    "Enterprise Linux (indefinido)": re.compile(
        r"\benterprise linux enterprise linux(?:\s+server)?"
        r"(?:\s+release)?\s+(?P<version>\d+(?:\.\d+)?)",
        re.I,
    ),
}


def normalized(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value)
    return "".join(
        character
        for character in decomposed
        if not unicodedata.combining(character)
    ).strip().casefold()


def find_column(headers: list[str], expected: str, required: bool = True) -> str | None:
    expected_normalized = normalized(expected)
    for header in headers:
        if normalized(header) == expected_normalized:
            return header
    if required:
        raise ValueError(f"Coluna obrigatória ausente: {expected}")
    return None


def read_csv_rows(path: Path) -> list[dict[str, str]]:
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
        dialect = csv.Sniffer().sniff(text[:65536], delimiters=",;\t|")
    except csv.Error:
        dialect = csv.excel
    return [
        {
            str(key or "").strip(): str(value or "").strip()
            for key, value in row.items()
        }
        for row in csv.DictReader(text.splitlines(), dialect=dialect)
    ]


def read_xlsx_rows(path: Path, sheet_name: str) -> list[dict[str, str]]:
    try:
        import consolidar_os_cmdb as xlsx_reader
    except ModuleNotFoundError as error:
        raise ValueError(
            "Leitura de XLSX indisponível: módulo consolidar_os_cmdb ausente"
        ) from error
    indexed_rows = xlsx_reader.read_sheet(path, sheet_name)
    if not indexed_rows:
        return []
    headers = indexed_rows[0]
    return [
        {
            header: row.get(index, "")
            for index, header in headers.items()
            if header
        }
        for row in indexed_rows[1:]
    ]


def read_input(path: Path, sheet_name: str) -> list[dict[str, str]]:
    suffix = path.suffix.casefold()
    if suffix == ".csv":
        return read_csv_rows(path)
    if suffix == ".xlsx":
        return read_xlsx_rows(path, sheet_name)
    raise ValueError("Formato não suportado. Use .csv ou .xlsx")


def linux_classification(description: str) -> Classification:
    family = "Linux genérico"
    for candidate, pattern in LINUX_FAMILY_PATTERNS:
        if pattern.search(description):
            family = candidate
            break
    pattern = LINUX_VERSION_PATTERNS.get(family)
    match = pattern.search(description) if pattern else None
    detected = match.group("version") if match else "Não identificada"
    major = detected.split(".", maxsplit=1)[0]
    return Classification("Linux", family, major, detected)


def first_version(description: str, pattern: str) -> tuple[str, str]:
    match = re.search(pattern, description, re.I)
    if not match:
        return "Não identificada", "Não identificada"
    detected = match.group("version")
    return detected.split(".", maxsplit=1)[0], detected


def classify(operating_system: str, description: str) -> Classification:
    os_value = normalized(operating_system)
    text = normalized(description)

    if "windows" in os_value or "windows" in text:
        if "server" in text:
            major, detected = first_version(
                description,
                r"\bwindows server\s+"
                r"(?P<version>2003|2008(?:\s+R2)?|2012(?:\s+R2)?|"
                r"2016|2019|2022|2025)",
            )
            if major != "Não identificada" and "or later" in text:
                major = f"{major}+"
                detected = f"{detected}+"
            return Classification("Windows", "Windows Server", major, detected)
        if re.search(r"\bwindows\s+\d", text):
            major, detected = first_version(
                description, r"\bwindows\s+(?P<version>\d+(?:\.\d+)?)"
            )
            return Classification("Windows", "Windows Desktop", major, detected)
        return Classification(
            "Windows",
            "Windows genérico",
            "Não identificada",
            "Não identificada",
        )

    if os_value == "esxi" or re.search(r"\b(?:esxi|vmware)\b", text):
        major, detected = first_version(
            description, r"\besxi\s+(?P<version>\d+(?:\.\d+)?)"
        )
        return Classification("Virtualização", "VMware ESXi", major, detected)

    linux_hint = any(pattern.search(description) for _, pattern in LINUX_FAMILY_PATTERNS)
    if "linux" in os_value or linux_hint:
        return linux_classification(description)

    if "hpux" in os_value or re.search(r"\bhp-?ux\b", text):
        major, detected = first_version(
            description, r"\b(?:hp-?ux|hpux)\s+(?:b\.)?(?P<version>\d+(?:\.\d+)*)"
        )
        return Classification("Unix", "HP-UX", major, detected)

    if "solaris" in os_value or "sunos" in os_value or re.search(
        r"\b(?:solaris|sunos)\b", text
    ):
        major, detected = first_version(
            description, r"\b(?:oracle\s+)?(?:solaris|sunos)\s+(?P<version>\d+(?:\.\d+)?)"
        )
        return Classification("Unix", "Solaris", major, detected)

    if "aix" in text:
        major, detected = first_version(
            description, r"\baix\s*\(?(?P<version>\d+(?:\.\d+)?)"
        )
        return Classification("Unix", "AIX", major, detected)

    if os_value == "unix":
        return Classification(
            "Unix", "Unix genérico", "Não identificada", "Não identificada"
        )

    if "mainframe" in os_value or re.search(r"\b(?:z/?os|zos)\b", text):
        major, detected = first_version(
            description, r"\b(?:z/?os|zos)\s*(?P<version>\d+(?:\.\d+)?)"
        )
        return Classification("Mainframe", "z/OS", major, detected)

    if "nexus" in os_value or "nexus" in text:
        return Classification(
            "Rede", "Cisco Nexus", "Não identificada", "Não identificada"
        )

    domain = operating_system.strip() or "Não identificado"
    family = operating_system.strip() or "Não identificada"
    return Classification(
        domain, family, "Não identificada", "Não identificada"
    )


def truthy(value: str) -> bool:
    return normalized(value) in {"true", "sim", "yes", "1"}


def consolidate(rows: list[dict[str, str]]) -> list[Profile]:
    if not rows:
        raise ValueError("O arquivo de entrada não possui registros")

    headers = list(rows[0])
    os_column = find_column(headers, "Sistema Operacional")
    version_column = find_column(headers, "Versão Sistema Operacional")
    status_column = find_column(headers, "Status", required=False)
    environment_column = find_column(headers, "Ambiente", required=False)
    sox_column = find_column(headers, "SOX", required=False)

    grouped: dict[tuple[str, str, str], dict[str, object]] = defaultdict(
        lambda: {
            "ativos": 0,
            "em_uso": 0,
            "producao": 0,
            "sox": 0,
            "sem_versao": 0,
            "descricoes": Counter(),
        }
    )
    for row in rows:
        operating_system = row.get(os_column or "", "").strip()
        description = row.get(version_column or "", "").strip() or "(vazio)"
        classification = classify(operating_system, description)
        key = (
            classification.dominio,
            classification.familia,
            classification.versao_principal,
        )
        bucket = grouped[key]
        bucket["ativos"] = int(bucket["ativos"]) + 1
        if status_column and normalized(row.get(status_column, "")) == "em uso":
            bucket["em_uso"] = int(bucket["em_uso"]) + 1
        if environment_column and normalized(
            row.get(environment_column, "")
        ).startswith("producao"):
            bucket["producao"] = int(bucket["producao"]) + 1
        if sox_column and truthy(row.get(sox_column, "")):
            bucket["sox"] = int(bucket["sox"]) + 1
        if (
            description == "(vazio)"
            or classification.versao_principal == "Não identificada"
            or "+" in classification.versao_principal
            or "/" in classification.versao_principal
        ):
            bucket["sem_versao"] = int(bucket["sem_versao"]) + 1
        descriptions = bucket["descricoes"]
        assert isinstance(descriptions, Counter)
        descriptions[description] += 1

    profiles: list[Profile] = []
    for (domain, family, major), bucket in grouped.items():
        descriptions = bucket["descricoes"]
        assert isinstance(descriptions, Counter)
        profile_name = (
            f"{family} {major}"
            if major != "Não identificada"
            else f"{family} / versão não identificada"
        )
        profiles.append(
            Profile(
                chave=f"{domain}|{family}|{major}",
                dominio=domain,
                familia=family,
                versao_principal=major,
                perfil=profile_name,
                ativos=int(bucket["ativos"]),
                em_uso=int(bucket["em_uso"]),
                producao=int(bucket["producao"]),
                sox=int(bucket["sox"]),
                sem_versao=int(bucket["sem_versao"]),
                descricoes_unicas=len(descriptions),
                descricoes=tuple(
                    f"{count} × {description}"
                    for description, count in descriptions.most_common()
                ),
            )
        )

    profiles.sort(
        key=lambda item: (
            item.dominio.casefold(),
            item.familia.casefold(),
            item.versao_principal == "Não identificada",
            item.versao_principal,
        )
    )
    return profiles


def render_html(profiles: list[Profile], source: Path) -> str:
    payload = json.dumps(
        [asdict(profile) for profile in profiles],
        ensure_ascii=False,
        separators=(",", ":"),
    ).replace("</", "<\\/")
    total_assets = sum(profile.ativos for profile in profiles)
    active_assets = sum(profile.em_uso for profile in profiles)
    production_assets = sum(profile.producao for profile in profiles)
    unidentified = sum(profile.sem_versao for profile in profiles)
    format_number = lambda value: f"{value:,}".replace(",", ".")
    source_name = html.escape(source.name)
    return f"""<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Gestão de baselines — CMDB</title>
  <style>
    :root {{
      --bg:#f3f5f7;--card:#fff;--text:#17212b;--muted:#647180;--line:#d7dee5;
      --accent:#175d91;--accent-soft:#e5eff7;--ok:#22713a;--todo:#9a3f16;
      --progress:#815b00;--review:#7c4f90;--na:#66717c;--danger:#a12a2a;
    }}
    *{{box-sizing:border-box}}
    body{{margin:0;background:var(--bg);color:var(--text);font:14px/1.42 system-ui,-apple-system,"Segoe UI",sans-serif}}
    main{{width:min(1750px,97vw);margin:24px auto}}
    h1{{margin:0 0 3px;font-size:24px}} .subtitle,.note{{color:var(--muted)}}
    .cards{{display:grid;grid-template-columns:repeat(6,minmax(140px,1fr));gap:10px;margin:20px 0 14px}}
    .card{{padding:14px;border:1px solid var(--line);border-radius:7px;background:var(--card)}}
    .card span{{display:block;color:var(--muted);font-size:12px}} .card strong{{display:block;margin-top:3px;font-size:21px}}
    .toolbar,.filters{{display:flex;flex-wrap:wrap;gap:8px;padding:12px;border:1px solid var(--line);background:var(--card)}}
    .toolbar{{border-radius:7px 7px 0 0}} .filters{{border-top:0}}
    input,select,button{{min-height:36px;padding:7px 9px;border:1px solid #b5c0ca;border-radius:5px;background:#fff;color:var(--text);font:inherit}}
    input[type="search"]{{min-width:260px;flex:1}} input[type="text"]{{min-width:145px;width:100%}}
    button{{cursor:pointer}} button:hover{{border-color:var(--accent);color:var(--accent)}} button.primary{{background:var(--accent);border-color:var(--accent);color:white}}
    .spacer{{flex:1}} .result{{display:flex;justify-content:space-between;gap:15px;padding:9px 12px;border-inline:1px solid var(--line);background:var(--accent-soft)}}
    .comparison{{display:none;padding:9px 12px;border:1px solid #cbbce0;background:#f3edf8;color:#503864}}
    .table-wrap{{overflow:auto;max-height:67vh;border:1px solid var(--line);border-radius:0 0 7px 7px;background:var(--card)}}
    table{{width:100%;border-collapse:collapse}} th,td{{padding:8px 9px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap;vertical-align:top}}
    th{{position:sticky;top:0;z-index:2;background:#e9eef2;color:#35434f;font-size:11px;text-transform:uppercase;letter-spacing:.025em}}
    td.number{{text-align:right;font-variant-numeric:tabular-nums}} td.edit{{min-width:150px}} td.notes{{min-width:220px}}
    tr.selected{{background:#f0f7fc}} tr.data-quality td.profile{{border-left:3px solid var(--review)}}
    .profile small{{display:block;color:var(--muted);margin-top:2px}} details{{max-width:520px;white-space:normal}}
    summary{{cursor:pointer;color:var(--accent)}} ul{{margin:7px 0;padding-left:18px}} li{{margin:2px 0}}
    .status-select[data-status="Criado"]{{color:var(--ok);font-weight:650}}
    .status-select[data-status="Não criado"]{{color:var(--todo);font-weight:650}}
    .status-select[data-status="Em andamento"]{{color:var(--progress);font-weight:650}}
    .status-select[data-status="Revisar CMDB"]{{color:var(--review);font-weight:650}}
    .delta-up{{color:var(--danger)}} .delta-down{{color:var(--ok)}} .new{{color:var(--accent);font-weight:650}}
    .coverage{{height:5px;margin-top:7px;border-radius:4px;background:#dce3e8;overflow:hidden}} .coverage span{{display:block;height:100%;background:var(--ok)}}
    .note{{font-size:12px}} .empty{{padding:26px;text-align:center;color:var(--muted)}}
    @media(max-width:1100px){{.cards{{grid-template-columns:repeat(3,1fr)}}}}
    @media(max-width:700px){{.cards{{grid-template-columns:repeat(2,1fr)}}.toolbar,.filters{{display:grid;grid-template-columns:1fr}}.spacer{{display:none}}}}
  </style>
</head>
<body>
<main>
  <h1>Gestão de baselines</h1>
  <p class="subtitle">Fonte: {source_name} · inventário atualizado do Jira</p>

  <section class="cards">
    <div class="card"><span>Ativos inventariados</span><strong>{format_number(total_assets)}</strong></div>
    <div class="card"><span>Ativos em uso</span><strong>{format_number(active_assets)}</strong></div>
    <div class="card"><span>Produção</span><strong>{format_number(production_assets)}</strong></div>
    <div class="card"><span>Perfis encontrados</span><strong>{len(profiles)}</strong></div>
    <div class="card"><span>Sem versão confiável</span><strong>{format_number(unidentified)}</strong></div>
    <div class="card"><span>Cobertura em uso</span><strong id="coverage">0%</strong><div class="coverage"><span id="coverageBar"></span></div></div>
  </section>

  <section class="toolbar">
    <button id="selectVisible" type="button">Selecionar visíveis</button>
    <button id="clearSelection" type="button">Limpar seleção</button>
    <select id="bulkStatus">
      <option value="">Alterar status dos selecionados…</option>
      <option>Não avaliado</option><option>Não criado</option><option>Em andamento</option>
      <option>Criado</option><option>Não aplicável</option><option>Revisar CMDB</option>
    </select>
    <span class="spacer"></span>
    <button id="importButton" type="button">Importar status anterior</button>
    <input id="importFile" type="file" accept=".csv" hidden>
    <button id="exportFiltered" type="button">Exportar filtrados</button>
    <button id="exportAll" class="primary" type="button">Exportar todos</button>
  </section>
  <section class="filters">
    <input id="search" type="search" placeholder="Buscar perfil, família ou descrição da CMDB">
    <select id="domain"><option value="">Todos os domínios</option></select>
    <select id="family"><option value="">Todas as famílias</option></select>
    <select id="version"><option value="">Todas as versões</option></select>
    <select id="workflowStatus"><option value="">Todos os status</option></select>
    <button id="clearFilters" type="button">Limpar filtros</button>
  </section>
  <div id="comparison" class="comparison"></div>
  <div class="result"><span id="resultCount"></span><span id="assetCount"></span></div>

  <div class="table-wrap">
    <table>
      <thead><tr>
        <th><input id="toggleVisible" type="checkbox" title="Selecionar visíveis"></th>
        <th>Domínio / perfil</th><th>Status do baseline</th><th>Total</th><th>Em uso</th>
        <th>Produção</th><th>SOX</th><th>Baseline</th><th>Responsável</th>
        <th>Observação</th><th>Descrições da CMDB</th><th>Comparação</th>
      </tr></thead>
      <tbody id="rows"></tbody>
    </table>
  </div>
  <p class="note">
    As edições são salvas localmente neste navegador. “Exportar todos” gera o
    CSV oficial do acompanhamento; importe-o em um dashboard futuro para
    recuperar status e comparar quantidades.
  </p>
</main>
<script>
"use strict";
const profiles={payload};
const workflowStatuses=["Não avaliado","Não criado","Em andamento","Criado","Não aplicável","Revisar CMDB"];
const storageKey="cmdb-baselines-workflow-v2";
const el=Object.fromEntries(["coverage","coverageBar","selectVisible","clearSelection","bulkStatus","importButton","importFile","exportFiltered","exportAll","search","domain","family","version","workflowStatus","clearFilters","comparison","resultCount","assetCount","toggleVisible","rows"].map(id=>[id,document.querySelector("#"+id)]));
const esc=value=>String(value??"").replace(/[&<>"']/g,c=>({{"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}})[c]);
const state=loadState();
const selected=new Set();
let previous=new Map();
let filteredProfiles=[];

function emptyWorkflow(){{return {{status:"Não avaliado",baseline:"",responsavel:"",observacao:""}}}}
function loadState(){{
  try{{const value=JSON.parse(localStorage.getItem(storageKey)||"{{}}");return value&&typeof value==="object"?value:{{}}}}catch{{return {{}}}}
}}
function workflow(key){{
  if(!state[key])state[key]=emptyWorkflow();
  return state[key];
}}
function saveState(){{
  try{{localStorage.setItem(storageKey,JSON.stringify(state))}}catch(error){{console.warn("Persistência local indisponível",error)}}
}}
function setOptions(target,values,label){{
  const current=target.value;
  const unique=[...new Set(values)].sort((a,b)=>a.localeCompare(b,"pt-BR",{{numeric:true}}));
  target.innerHTML=`<option value="">${{label}}</option>`+unique.map(value=>`<option value="${{esc(value)}}">${{esc(value)}}</option>`).join("");
  if(unique.includes(current))target.value=current;
}}
function refreshFilterOptions(){{
  setOptions(el.domain,profiles.map(p=>p.dominio),"Todos os domínios");
  const byDomain=profiles.filter(p=>!el.domain.value||p.dominio===el.domain.value);
  setOptions(el.family,byDomain.map(p=>p.familia),"Todas as famílias");
  const byFamily=byDomain.filter(p=>!el.family.value||p.familia===el.family.value);
  setOptions(el.version,byFamily.map(p=>p.versao_principal),"Todas as versões");
  setOptions(el.workflowStatus,workflowStatuses,"Todos os status");
}}
function currentFiltered(){{
  const query=el.search.value.trim().toLocaleLowerCase("pt-BR");
  return profiles.filter(p=>{{
    const item=workflow(p.chave);
    const searchable=`${{p.dominio}} ${{p.familia}} ${{p.perfil}} ${{p.descricoes.join(" ")}} ${{item.baseline}} ${{item.responsavel}} ${{item.observacao}}`.toLocaleLowerCase("pt-BR");
    return (!query||searchable.includes(query))&&(!el.domain.value||p.dominio===el.domain.value)&&(!el.family.value||p.familia===el.family.value)&&(!el.version.value||p.versao_principal===el.version.value)&&(!el.workflowStatus.value||item.status===el.workflowStatus.value);
  }});
}}
function comparisonText(profile){{
  if(!previous.size)return "—";
  const old=previous.get(profile.chave);
  if(!old)return '<span class="new">Novo perfil</span>';
  const oldAssets=Number(old.ativos||0);
  const delta=profile.ativos-oldAssets;
  const deltaText=delta===0?"Sem alteração":`${{delta>0?"+":""}}${{delta}} ativos`;
  const deltaClass=delta>0?"delta-up":delta<0?"delta-down":"";
  const oldStatus=old.status&&old.status!==workflow(profile.chave).status?` · antes: ${{esc(old.status)}}`:"";
  return `<span class="${{deltaClass}}">${{deltaText}}</span>${{oldStatus}}`;
}}
function render(){{
  filteredProfiles=currentFiltered();
  const activeCovered=profiles.filter(p=>workflow(p.chave).status==="Criado").reduce((sum,p)=>sum+p.em_uso,0);
  const activeTotal=profiles.reduce((sum,p)=>sum+p.em_uso,0);
  const coverage=activeTotal?activeCovered/activeTotal*100:0;
  el.coverage.textContent=coverage.toLocaleString("pt-BR",{{maximumFractionDigits:1}})+"%";
  el.coverageBar.style.width=Math.min(coverage,100)+"%";
  el.resultCount.textContent=`${{filteredProfiles.length.toLocaleString("pt-BR")}} perfis`;
  el.assetCount.textContent=`${{filteredProfiles.reduce((sum,p)=>sum+p.ativos,0).toLocaleString("pt-BR")}} ativos · ${{selected.size}} selecionados`;
  el.toggleVisible.checked=filteredProfiles.length>0&&filteredProfiles.every(p=>selected.has(p.chave));
  el.rows.innerHTML=filteredProfiles.length?filteredProfiles.map(profile=>{{
    const item=workflow(profile.chave);
    const quality=profile.sem_versao>0?"data-quality":"";
    const checked=selected.has(profile.chave)?"checked":"";
    const selectedClass=checked?"selected":"";
    return `<tr class="${{quality}} ${{selectedClass}}">
      <td><input class="row-check" data-key="${{esc(profile.chave)}}" type="checkbox" ${{checked}}></td>
      <td class="profile"><strong>${{esc(profile.perfil)}}</strong><small>${{esc(profile.dominio)}} · ${{profile.sem_versao}} sem versão</small></td>
      <td><select class="status-select" data-field="status" data-key="${{esc(profile.chave)}}" data-status="${{esc(item.status)}}">${{workflowStatuses.map(value=>`<option ${{value===item.status?"selected":""}}>${{esc(value)}}</option>`).join("")}}</select></td>
      <td class="number">${{profile.ativos.toLocaleString("pt-BR")}}</td>
      <td class="number">${{profile.em_uso.toLocaleString("pt-BR")}}</td>
      <td class="number">${{profile.producao.toLocaleString("pt-BR")}}</td>
      <td class="number">${{profile.sox.toLocaleString("pt-BR")}}</td>
      <td class="edit"><input data-field="baseline" data-key="${{esc(profile.chave)}}" type="text" value="${{esc(item.baseline)}}" placeholder="Nome ou referência"></td>
      <td class="edit"><input data-field="responsavel" data-key="${{esc(profile.chave)}}" type="text" value="${{esc(item.responsavel)}}" placeholder="Equipe/pessoa"></td>
      <td class="notes"><input data-field="observacao" data-key="${{esc(profile.chave)}}" type="text" value="${{esc(item.observacao)}}" placeholder="Observação"></td>
      <td><details><summary>${{profile.descricoes_unicas}} descrições</summary><ul>${{profile.descricoes.map(value=>`<li>${{esc(value)}}</li>`).join("")}}</ul></details></td>
      <td>${{comparisonText(profile)}}</td>
    </tr>`;
  }}).join(""):'<tr><td colspan="12" class="empty">Nenhum perfil encontrado.</td></tr>';
}}
function selectVisible(value){{
  filteredProfiles.forEach(profile=>value?selected.add(profile.chave):selected.delete(profile.chave));
  render();
}}
function csvEscape(value){{const text=String(value??"");return /[;"\\n\\r]/.test(text)?'"'+text.replaceAll('"','""')+'"':text}}
function exportCsv(items,suffix){{
  const header=["chave","dominio","familia","versao","perfil","ativos","em_uso","producao","sox","status","baseline","responsavel","observacao","exportado_em"];
  const timestamp=new Date().toISOString();
  const lines=[header.join(";")];
  for(const profile of items){{
    const item=workflow(profile.chave);
    lines.push([profile.chave,profile.dominio,profile.familia,profile.versao_principal,profile.perfil,profile.ativos,profile.em_uso,profile.producao,profile.sox,item.status,item.baseline,item.responsavel,item.observacao,timestamp].map(csvEscape).join(";"));
  }}
  const blob=new Blob(["\\ufeff"+lines.join("\\r\\n")],{{type:"text/csv;charset=utf-8"}});
  const link=document.createElement("a");link.href=URL.createObjectURL(blob);
  link.download=`status_baselines_${{suffix}}_${{new Date().toISOString().slice(0,10)}}.csv`;
  link.click();URL.revokeObjectURL(link.href);
}}
function parseCsv(text){{
  const firstLine=(text.split(/\\r?\\n/,1)[0]||"");
  const delimiter=(firstLine.match(/;/g)||[]).length>=(firstLine.match(/,/g)||[]).length?";":",";
  const rows=[];let row=[],field="",quoted=false;
  for(let index=0;index<text.length;index++){{
    const char=text[index];
    if(quoted){{
      if(char==='"'&&text[index+1]==='"'){{field+='"';index++}}
      else if(char==='"')quoted=false;else field+=char;
    }}else if(char==='"')quoted=true;
    else if(char===delimiter){{row.push(field);field=""}}
    else if(char==="\\n"){{row.push(field.replace(/\\r$/,""));rows.push(row);row=[];field=""}}
    else field+=char;
  }}
  if(field||row.length){{row.push(field.replace(/\\r$/,""));rows.push(row)}}
  const headers=(rows.shift()||[]).map(value=>value.replace(/^\\ufeff/,""));
  return rows.filter(values=>values.some(Boolean)).map(values=>Object.fromEntries(headers.map((header,index)=>[header,values[index]??""])));
}}
async function importPrevious(file){{
  const records=parseCsv(await file.text());
  previous=new Map(records.filter(record=>record.chave).map(record=>[record.chave,record]));
  let restored=0;
  for(const profile of profiles){{
    const old=previous.get(profile.chave);
    if(!old)continue;
    const item=workflow(profile.chave);
    if(item.status==="Não avaliado"&&old.status){{item.status=old.status;item.baseline=old.baseline||"";item.responsavel=old.responsavel||"";item.observacao=old.observacao||"";restored++}}
  }}
  const currentKeys=new Set(profiles.map(profile=>profile.chave));
  const missing=[...previous.keys()].filter(key=>!currentKeys.has(key)).length;
  const newCount=profiles.filter(profile=>!previous.has(profile.chave)).length;
  el.comparison.style.display="block";
  el.comparison.textContent=`Comparação carregada: ${{restored}} status recuperados · ${{newCount}} perfis novos · ${{missing}} perfis anteriores ausentes.`;
  saveState();render();
}}
el.rows.addEventListener("change",event=>{{
  const target=event.target;
  if(target.classList.contains("row-check")){{target.checked?selected.add(target.dataset.key):selected.delete(target.dataset.key);render();return}}
  const key=target.dataset.key,field=target.dataset.field;
  if(key&&field){{workflow(key)[field]=target.value;saveState();render()}}
}});
el.rows.addEventListener("input",event=>{{
  const target=event.target,key=target.dataset.key,field=target.dataset.field;
  if(key&&field&&field!=="status"){{workflow(key)[field]=target.value;saveState()}}
}});
el.search.addEventListener("input",render);
["domain","family","version","workflowStatus"].forEach(id=>el[id].addEventListener("change",()=>{{if(id==="domain"||id==="family")refreshFilterOptions();render()}}));
el.selectVisible.addEventListener("click",()=>selectVisible(true));
el.clearSelection.addEventListener("click",()=>{{selected.clear();render()}});
el.toggleVisible.addEventListener("change",event=>selectVisible(event.target.checked));
el.bulkStatus.addEventListener("change",()=>{{if(!el.bulkStatus.value)return;selected.forEach(key=>workflow(key).status=el.bulkStatus.value);el.bulkStatus.value="";saveState();render()}});
el.clearFilters.addEventListener("click",()=>{{["search","domain","family","version","workflowStatus"].forEach(id=>el[id].value="");refreshFilterOptions();render()}});
el.exportAll.addEventListener("click",()=>exportCsv(profiles,"todos"));
el.exportFiltered.addEventListener("click",()=>exportCsv(filteredProfiles,"filtrados"));
el.importButton.addEventListener("click",()=>el.importFile.click());
el.importFile.addEventListener("change",async()=>{{if(el.importFile.files[0])await importPrevious(el.importFile.files[0]);el.importFile.value=""}});
refreshFilterOptions();render();
</script>
</body>
</html>
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Gera um dashboard HTML de gestão de baselines a partir da "
            "exportação do Jira."
        )
    )
    parser.add_argument("arquivo", type=Path, help="exportação .csv ou .xlsx")
    parser.add_argument(
        "-o",
        "--saida",
        type=Path,
        default=Path("dashboard_baselines.html"),
        help="HTML de saída (padrão: dashboard_baselines.html)",
    )
    parser.add_argument(
        "-s",
        "--planilha",
        default="Planilha2",
        help="planilha usada quando a entrada for XLSX",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.arquivo.is_file():
        raise SystemExit(f"Arquivo não encontrado: {args.arquivo}")
    try:
        rows = read_input(args.arquivo, args.planilha)
        profiles = consolidate(rows)
    except (ValueError, csv.Error) as error:
        raise SystemExit(f"Erro: {error}") from error
    args.saida.write_text(
        render_html(profiles, args.arquivo),
        encoding="utf-8",
    )
    print(
        f"{args.saida}: {len(rows)} ativos, {len(profiles)} perfis, "
        f"{sum(profile.em_uso for profile in profiles)} em uso"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
