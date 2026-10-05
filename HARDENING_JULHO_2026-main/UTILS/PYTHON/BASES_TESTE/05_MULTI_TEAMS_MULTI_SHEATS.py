#!/usr/bin/env python3
"""Gera um dashboard atual e histórico de hardening por equipe.

O painel atual usa a amostra mais recente de cada equipe. O histórico lê a data
MM_DD_AAAA do nome de cada CSV/XLSX e cria um ponto diário de aderência.
"""

from __future__ import annotations

import argparse
import base64
import csv
import html
import re
import sys
import unicodedata
import zipfile
from collections import Counter, defaultdict
from datetime import date, datetime
from pathlib import Path
import xml.etree.ElementTree as ET


XML_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
TARGET = 80.0


def clean(value: object) -> str:
    return " ".join(str(value or "").strip().split())


def fold(value: object) -> str:
    text = unicodedata.normalize("NFKD", clean(value))
    return "".join(char for char in text if not unicodedata.combining(char)).casefold()


def normalize_id(value: object) -> str:
    text = clean(value)
    return text.split(".", 1)[0] if re.fullmatch(r"\d+\.0+", text) else text


def normalize_status(value: object) -> str:
    status = fold(value).replace("_", " ").replace("-", " ")
    if status in {"passed", "pass", "compliant", "conforme", "ok", "true"}:
        return "PASSED"
    if status in {"failed", "fail", "non compliant", "nao conforme", "nok", "false"}:
        return "FAILED"
    return "UNKNOWN"


def normalize_severity(value: object) -> str:
    severity = fold(value)
    if severity in {"critica", "critical", "alta", "high"}:
        return "Alta"
    if severity in {"media", "medium", "moderada", "moderate"}:
        return "Média"
    if severity in {"baixa", "low"}:
        return "Baixa"
    return "Não informada"


def parse_audit_name(record: dict[str, str]) -> None:
    """Extrai ID, nome e criticidade do campo combinado usado nos CSVs atuais."""
    field = clean(record.get("compliance.audit_name"))
    if not field or clean(record.get("compliance.audit_ID")):
        return
    parts = [part.strip() for part in field.split(",", 2)]
    if len(parts) == 3:
        record["compliance.audit_ID"] = parts[0]
        record["compliance.audit_name"] = parts[1]
        record["compliance.audit_criticidade"] = parts[2]
        return
    match = re.fullmatch(r"(\S+)\s+(.+?)\s+(Alta|M[eé]dia|Baixa)", field, re.IGNORECASE)
    if match:
        record["compliance.audit_ID"] = match.group(1)
        record["compliance.audit_name"] = match.group(2)
        record["compliance.audit_criticidade"] = match.group(3)
        return
    record["compliance.audit_ID"] = field


def column_index(reference: str) -> int:
    letters = re.match(r"[A-Z]+", reference or "A")
    number = 0
    for letter in letters.group(0) if letters else "A":
        number = number * 26 + ord(letter) - 64
    return number - 1


def read_xlsx(path: Path) -> list[dict[str, str]]:
    with zipfile.ZipFile(path) as archive:
        names = set(archive.namelist())
        shared: list[str] = []
        if "xl/sharedStrings.xml" in names:
            root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            shared = ["".join(item.itertext()) for item in root.findall(f"{XML_NS}si")]
        sheets = sorted(name for name in names if re.fullmatch(r"xl/worksheets/sheet\d+\.xml", name))
        if not sheets:
            raise ValueError("O XLSX não contém planilhas legíveis.")
        rows: list[list[str]] = []
        with archive.open(sheets[0]) as source:
            for _, element in ET.iterparse(source, events=("end",)):
                if element.tag != f"{XML_NS}row":
                    continue
                values: dict[int, str] = {}
                for cell in element.findall(f"{XML_NS}c"):
                    position = column_index(cell.get("r", "A1"))
                    cell_type = cell.get("t", "")
                    value_node = cell.find(f"{XML_NS}v")
                    if cell_type == "inlineStr":
                        inline = cell.find(f"{XML_NS}is")
                        value = "" if inline is None else "".join(inline.itertext())
                    elif value_node is None:
                        value = ""
                    elif cell_type == "s":
                        value = shared[int(value_node.text or "0")]
                    else:
                        value = value_node.text or ""
                    values[position] = value
                width = max(values, default=-1) + 1
                rows.append([values.get(index, "") for index in range(width)])
                element.clear()
    if not rows:
        return []
    headers = [clean(item).lstrip("\ufeff") for item in rows[0]]
    return [
        {header: row[index] if index < len(row) else "" for index, header in enumerate(headers)}
        for row in rows[1:]
        if any(clean(item) for item in row)
    ]


def read_csv(path: Path) -> list[dict[str, str]]:
    raw = path.read_bytes()
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")
    try:
        dialect = csv.Sniffer().sniff(text[:65536], delimiters=",;\t|")
    except csv.Error:
        dialect = csv.excel
    reader = csv.DictReader(text.splitlines(), dialect=dialect)
    return [
        {(key or "").lstrip("\ufeff").strip(): value or "" for key, value in row.items()}
        for row in reader
    ]


def load_records(path: Path) -> list[dict[str, str]]:
    suffix = path.suffix.casefold()
    if suffix == ".xlsx":
        records = read_xlsx(path)
    elif suffix in {".csv", ".tsv"}:
        records = read_csv(path)
    else:
        raise ValueError("Formato não suportado.")
    if not records:
        raise ValueError("Arquivo sem registros.")
    for record in records:
        parse_audit_name(record)
    required = {"asset.host_name", "compliance.audit_ID", "compliance_result"}
    missing = required.difference(records[0])
    if missing:
        friendly = {
            "compliance.audit_ID": "compliance.audit_name (contendo ID, nome e criticidade)",
        }
        names = [friendly.get(name, name) for name in sorted(missing)]
        raise ValueError("Colunas obrigatórias ausentes: " + ", ".join(names))
    return records


def extract_team_name(path: Path) -> str:
    return clean(path.stem.split("_", 1)[0]).upper() or path.stem.upper()


def extract_result_datetime(path: Path) -> datetime | None:
    """Lê somente MM_DD_AAAA no nome; horário não participa do histórico."""
    if "_" not in path.stem or not clean(path.stem.split("_", 1)[0]):
        return None
    suffix = path.stem.split("_", 1)[1]
    match = re.search(
        r"(?<!\d)(?P<month>0?[1-9]|1[0-2])[_-]"
        r"(?P<day>0?[1-9]|[12]\d|3[01])[_-]"
        r"(?P<year>20\d{2})(?!\d)",
        suffix,
    )
    if not match:
        return None
    try:
        return datetime(
            int(match.group("year")),
            int(match.group("month")),
            int(match.group("day")),
        )
    except ValueError:
        return None


class Core:
    """Facade local para manter o restante do gerador simples e autocontido."""

    clean = staticmethod(clean)
    fold = staticmethod(fold)
    normalize_id = staticmethod(normalize_id)
    normalize_status = staticmethod(normalize_status)
    normalize_severity = staticmethod(normalize_severity)
    read_xlsx = staticmethod(read_xlsx)
    read_csv = staticmethod(read_csv)
    load_records = staticmethod(load_records)
    extract_team_name = staticmethod(extract_team_name)
    extract_result_datetime = staticmethod(extract_result_datetime)


CORE = Core()


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def integer(value: int) -> str:
    return f"{value:,}".replace(",", ".")


def pct(value: float) -> str:
    return f"{value:.1f}%".replace(".", ",")


def parse_pairs(values: list[str], value_name: str) -> dict[str, str]:
    pairs: dict[str, str] = {}
    for item in values:
        if "=" not in item:
            raise ValueError(f"{value_name} inválido: {item!r}. Use EQUIPE=VALOR.")
        team, value = item.split("=", 1)
        team = CORE.clean(team).upper()
        value = value.strip()
        if not team or not value:
            raise ValueError(f"{value_name} inválido: {item!r}. Use EQUIPE=VALOR.")
        pairs[team] = value
    return pairs


def inventory_count(path: Path) -> int:
    if path.suffix.casefold() == ".xlsx":
        records = CORE.read_xlsx(path)
    elif path.suffix.casefold() in {".csv", ".tsv"}:
        records = CORE.read_csv(path)
    else:
        raise ValueError(f"CMDB com formato não suportado: {path.name}")
    if not records:
        return 0
    candidates = (
        "Key", "key", "asset.host_name", "host_name", "hostname", "Host",
        "Name", "name", "Object Hash",
    )
    key = next((name for name in candidates if name in records[0]), None)
    if key:
        unique = {CORE.clean(row.get(key)).casefold() for row in records if CORE.clean(row.get(key))}
        return len(unique)
    return len(records)


def discover_results(directory: Path, explicit: list[Path]) -> tuple[list[tuple[Path, list[dict[str, str]]]], list[str]]:
    candidates = explicit or sorted(
        path for path in directory.iterdir()
        if path.suffix.casefold() in {".csv", ".xlsx", ".tsv"} and not path.name.startswith("~$")
    )
    found: list[tuple[Path, list[dict[str, str]]]] = []
    skipped: list[str] = []
    for path in candidates:
        path = path if path.is_absolute() else directory / path
        try:
            found.append((path, CORE.load_records(path)))
        except (OSError, ValueError, UnicodeError, csv.Error, zipfile.BadZipFile, ET.ParseError):
            if explicit:
                raise ValueError(f"Arquivo de resultado inválido: {path}")
            skipped.append(path.name)
    if not found:
        raise ValueError("Nenhum arquivo de resultado de hardening foi encontrado.")
    return found, skipped


def organize_snapshots(
    files: list[tuple[Path, list[dict[str, str]]]],
) -> tuple[
    list[tuple[Path, list[dict[str, str]]]],
    list[tuple[str, date, Path, list[dict[str, str]]]],
    list[str],
]:
    """Seleciona a última amostra por equipe e uma amostra por equipe/dia."""
    daily: dict[tuple[str, date], tuple[datetime, Path, list[dict[str, str]]]] = {}
    invalid_names: list[str] = []
    for path, rows in files:
        captured_at = CORE.extract_result_datetime(path)
        if captured_at is None:
            invalid_names.append(path.name)
            continue
        team = CORE.extract_team_name(path)
        key = (team, captured_at.date())
        candidate = (captured_at, path, rows)
        current = daily.get(key)
        if current is None or (captured_at, path.name) > (current[0], current[1].name):
            daily[key] = candidate

    if not daily:
        raise ValueError(
            "Nenhum resultado possui nome no formato EQUIPE_...MM_DD_AAAA..."
        )

    ordered = sorted(
        (
            (team, sample_date, value[1], value[2])
            for (team, sample_date), value in daily.items()
        ),
        key=lambda item: (item[1], item[0], item[2].name),
    )
    latest: dict[str, tuple[date, Path, list[dict[str, str]]]] = {}
    for team, sample_date, path, rows in ordered:
        current = latest.get(team)
        if current is None or (sample_date, path.name) > (current[0], current[1].name):
            latest[team] = (sample_date, path, rows)
    latest_files = [(value[1], value[2]) for _, value in sorted(latest.items())]
    return latest_files, ordered, invalid_names


def summarize(files: list[tuple[Path, list[dict[str, str]]]], excluded_ids: set[str], target: float):
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for path, rows in files:
        grouped[CORE.extract_team_name(path)].extend(rows)

    teams: list[dict] = []
    global_controls: Counter = Counter()
    control_meta: dict[tuple[str, str], tuple[str, str]] = {}
    totals = Counter()

    for team_name, records in grouped.items():
        unique: dict[tuple[str, str], dict[str, str]] = {}
        duplicates = excluded = ignored = 0
        for row in records:
            host = CORE.clean(row.get("asset.host_name")) or CORE.clean(row.get("asset.name"))
            control_id = CORE.normalize_id(row.get("compliance.audit_ID"))
            if control_id in excluded_ids:
                excluded += 1
                continue
            if not host or not control_id:
                ignored += 1
                continue
            key = (host.casefold(), control_id)
            duplicates += int(key in unique)
            unique[key] = row

        hosts: dict[str, list[dict[str, str]]] = defaultdict(list)
        for (host, _), row in unique.items():
            hosts[host].append(row)

        data = {
            "team": team_name, "servers": len(hosts), "passed": 0, "failed": 0,
            "unknown": 0, "high": 0, "medium": 0, "low": 0, "uninformed": 0,
            "affected_high": set(), "affected_medium": set(), "affected_low": set(),
            "at_target": 0, "duplicates": duplicates, "excluded": excluded, "ignored": ignored,
        }
        for host, rows in hosts.items():
            statuses = Counter(CORE.normalize_status(row.get("compliance_result")) for row in rows)
            evaluated = statuses["PASSED"] + statuses["FAILED"]
            adherence = statuses["PASSED"] * 100 / evaluated if evaluated else 0.0
            data["at_target"] += int(evaluated > 0 and adherence >= target)
            data["passed"] += statuses["PASSED"]
            data["failed"] += statuses["FAILED"]
            data["unknown"] += statuses["UNKNOWN"]
            for row in rows:
                if CORE.normalize_status(row.get("compliance_result")) != "FAILED":
                    continue
                severity = CORE.normalize_severity(row.get("compliance.audit_criticidade"))
                severity_key = {"Alta": "high", "Média": "medium", "Baixa": "low"}.get(severity, "uninformed")
                data[severity_key] += 1
                if severity_key != "uninformed":
                    data[f"affected_{severity_key}"].add(host)
                control_id = CORE.normalize_id(row.get("compliance.audit_ID"))
                control_name = CORE.clean(row.get("compliance.audit_name")) or "Controle sem nome"
                control_key = (control_id, severity)
                global_controls[control_key] += 1
                control_meta[control_key] = (control_name, severity)
        evaluated = data["passed"] + data["failed"]
        data["adherence"] = data["passed"] * 100 / evaluated if evaluated else 0.0
        data["below_target"] = data["servers"] - data["at_target"]
        teams.append(data)
        for key in ("servers", "passed", "failed", "unknown", "high", "medium", "low", "uninformed",
                    "at_target", "below_target", "duplicates", "excluded", "ignored"):
            totals[key] += data[key]

    teams.sort(key=lambda item: (-item["failed"], item["team"]))
    evaluated = totals["passed"] + totals["failed"]
    totals["adherence"] = totals["passed"] * 100 / evaluated if evaluated else 0.0
    focus = next(
        (
            severity
            for severity in ("Alta", "Média", "Baixa", "Não informada")
            if any(key[1] == severity for key in global_controls)
        ),
        "Não informada",
    )
    prioritized = sorted(
        (
            (key, count)
            for key, count in global_controls.items()
            if key[1] == focus
        ),
        key=lambda item: (-item[1], item[0][0], control_meta[item[0]][0]),
    )[:8]
    controls = [
        {
            "id": key[0],
            "severity": control_meta[key][1],
            "name": control_meta[key][0],
            "fails": count,
        }
        for key, count in prioritized
    ]
    return teams, totals, controls, focus


def build_history(
    snapshots: list[tuple[str, date, Path, list[dict[str, str]]]],
    excluded_ids: set[str],
    target: float,
) -> list[dict]:
    history: list[dict] = []
    for team, sample_date, path, rows in snapshots:
        teams, _, _, _ = summarize([(path, rows)], excluded_ids, target)
        if not teams:
            continue
        summary = teams[0]
        history.append(
            {
                "team": team,
                "date": sample_date,
                "adherence": summary["adherence"],
                "servers": summary["servers"],
                "failed": summary["failed"],
            }
        )
    return history


def donut(value: float, color: str, center: str, label: str, size: int = 140) -> str:
    bounded = max(0.0, min(100.0, value))
    return (
        f'<div class="donut" style="--value:{bounded:.2f};--color:{color};--size:{size}px">'
        f'<svg viewBox="0 0 100 100"><circle class="track" cx="50" cy="50" r="40" pathLength="100"/>'
        f'<circle class="progress" cx="50" cy="50" r="40" pathLength="100" stroke-dasharray="{bounded:.2f} {100 - bounded:.2f}"/></svg>'
        f'<div class="donut-content"><strong>{esc(center)}</strong><small>{esc(label)}</small></div></div>'
    )


def risk_donut(high: int, medium: int, low: int, uninformed: int) -> str:
    total = high + medium + low + uninformed
    if not total:
        return donut(0, "var(--claro-gray)", "0", "FAILs")
    
    high_pct = high * 100 / total
    medium_pct = medium * 100 / total
    low_pct = low * 100 / total
    uninformed_pct = uninformed * 100 / total
    
    return (
        f'<div class="donut risk-donut" style="--size:140px">'
        f'<svg viewBox="0 0 100 100">'
        f'<circle class="track" cx="50" cy="50" r="40" pathLength="100"/>'
        f'<circle class="risk-seg risk-high" cx="50" cy="50" r="40" pathLength="100" '
        f'stroke-dasharray="{high_pct:.2f} {100 - high_pct:.2f}" stroke-dashoffset="0"/>'
        f'<circle class="risk-seg risk-medium" cx="50" cy="50" r="40" pathLength="100" '
        f'stroke-dasharray="{medium_pct:.2f} {100 - medium_pct:.2f}" stroke-dashoffset="-{high_pct:.2f}"/>'
        f'<circle class="risk-seg risk-low" cx="50" cy="50" r="40" pathLength="100" '
        f'stroke-dasharray="{low_pct:.2f} {100 - low_pct:.2f}" stroke-dashoffset="-{high_pct + medium_pct:.2f}"/>'
        f'<circle class="risk-seg risk-unknown" cx="50" cy="50" r="40" pathLength="100" '
        f'stroke-dasharray="{uninformed_pct:.2f} {100 - uninformed_pct:.2f}" stroke-dashoffset="-{high_pct + medium_pct + low_pct:.2f}"/>'
        f'</svg>'
        f'<div class="donut-content"><strong>{integer(total)}</strong><small>FAILs</small></div></div>'
    )


def severity_cards(totals: Counter, teams: list[dict]) -> str:
    specs = (
        ("Alta", "high", "critical", "Exige atenção imediata"),
        ("Média", "medium", "medium", "Prioridade de correção"),
        ("Baixa", "low", "low", "Planejar correção"),
    )
    output = []
    for label, key, css, desc in specs:
        affected = sum(len(team[f"affected_{key}"]) for team in teams)
        output.append(
            f'<article class="severity-card {css}">'
            f'<div class="severity-header"><span class="severity-dot"></span><h3>{label}</h3></div>'
            f'<div class="severity-body">'
            f'<div class="severity-metric"><strong>{integer(totals[key])}</strong><span>não conformidades</span></div>'
            f'<div class="severity-metric"><strong>{integer(affected)}</strong><span>ativos afetados</span></div>'
            f'</div><div class="severity-footer">{desc}</div></article>'
        )
    return "".join(output)


def control_rows(controls: list[dict]) -> str:
    if not controls:
        return '<tr><td colspan="3" class="empty-state">Nenhuma não conformidade encontrada</td></tr>'
    rows = []
    for item in controls:
        severity_class = {
            "Alta": "critical",
            "Média": "medium",
            "Baixa": "low",
        }.get(item["severity"], "neutral")
        rows.append(
            f'<tr><td class="control-id"><code>{esc(item["id"])}</code></td>'
            f'<td class="control-name">{esc(item["name"])}</td>'
            f'<td><span class="badge {severity_class}">{esc(item["severity"])}</span></td>'
            f'<td class="numeric">{integer(item["fails"])}</td></tr>'
        )
    return "".join(rows)


def team_bars(teams: list[dict], target: float) -> str:
    maximum = max((team["failed"] for team in teams), default=1) or 1
    rows = []
    for team in teams:
        high_pct = team["high"] * 100 / maximum
        medium_pct = team["medium"] * 100 / maximum
        low_pct = team["low"] * 100 / maximum
        
        adherence = team["adherence"]
        near_target = max(0.0, target - 10.0)
        adherence_color = (
            "success"
            if adherence >= target
            else "warning"
            if adherence >= near_target
            else "critical"
        )
        
        rows.append(
            f'<div class="team-row">'
            f'<div class="team-info">'
            f'<span class="team-name">{esc(team["team"])}</span>'
            f'<span class="team-servers">{team["servers"]} servidores</span>'
            f'</div>'
            f'<div class="team-bar-container">'
            f'<div class="team-bar">'
            f'<div class="bar-seg critical" style="width:{high_pct:.1f}%"></div>'
            f'<div class="bar-seg medium" style="width:{medium_pct:.1f}%"></div>'
            f'<div class="bar-seg low" style="width:{low_pct:.1f}%"></div>'
            f'</div>'
            f'<div class="team-stats">'
            f'<span class="stat critical">{team["high"]}</span>'
            f'<span class="stat medium">{team["medium"]}</span>'
            f'<span class="stat low">{team["low"]}</span>'
            f'</div></div>'
            f'<div class="team-adherence"><span class="badge {adherence_color}">{pct(adherence)}</span></div>'
            f'</div>'
        )
    return "".join(rows)


def inventory_rows(teams: list[dict], inventories: dict[str, int]) -> str:
    rows = []
    for team in teams:
        known = inventories.get(team["team"])
        if known is None:
            known_text, coverage_text, pending_text, width, state = "—", "—", "—", 0, "unknown"
            status_class = "neutral"
        else:
            coverage = team["servers"] * 100 / known if known else 0.0
            pending = max(0, known - team["servers"])
            known_text, coverage_text, pending_text = integer(known), pct(coverage), integer(pending)
            width = min(coverage, 100)
            state = "known"
            status_class = "success" if coverage >= 90 else "warning" if coverage >= 70 else "critical"
        
        rows.append(
            f'<tr>'
            f'<td><span class="team-badge">{esc(team["team"][:2])}</span><b>{esc(team["team"])}</b></td>'
            f'<td class="numeric">{known_text}</td>'
            f'<td class="numeric">{integer(team["servers"])}</td>'
            f'<td class="numeric">{pending_text}</td>'
            f'<td class="coverage-cell">'
            f'<div class="coverage-bar">'
            f'<div class="coverage-fill {status_class}" style="width:{width:.1f}%"></div>'
            f'</div><span class="coverage-text">{coverage_text}</span></td>'
            f'</tr>'
        )
    return "".join(rows)


def history_chart(history: list[dict], target: float) -> str:
    if not history:
        return '<div class="empty-state">Nenhuma amostra histórica encontrada.</div>'

    width, height = 1100, 390
    left, right, top, bottom = 62, 24, 26, 72
    plot_width, plot_height = width - left - right, height - top - bottom
    dates = sorted({item["date"] for item in history})
    teams = sorted({item["team"] for item in history})
    colors = (
        "#D52B1E", "#2E7BD6", "#27AE60", "#8B5CF6", "#F59E0B",
        "#0891B2", "#DB2777", "#4F46E5", "#65A30D", "#EA580C",
    )

    def x_position(sample_date: date) -> float:
        if len(dates) == 1:
            return left + plot_width / 2
        return left + dates.index(sample_date) * plot_width / (len(dates) - 1)

    def y_position(value: float) -> float:
        return top + (100 - max(0.0, min(100.0, value))) * plot_height / 100

    svg: list[str] = [
        f'<svg class="history-svg" viewBox="0 0 {width} {height}" role="img" '
        'aria-label="Histórico de aderência por equipe">'
    ]
    for value in range(0, 101, 20):
        y = y_position(value)
        svg.append(
            f'<line class="history-grid" x1="{left}" y1="{y:.1f}" x2="{width-right}" y2="{y:.1f}"/>'
            f'<text class="history-axis-label" x="{left-10}" y="{y+4:.1f}" text-anchor="end">{value}%</text>'
        )
    target_y = y_position(target)
    svg.append(
        f'<line class="history-target" x1="{left}" y1="{target_y:.1f}" '
        f'x2="{width-right}" y2="{target_y:.1f}"/>'
        f'<text class="history-target-label" x="{width-right-4}" y="{target_y-7:.1f}" '
        f'text-anchor="end">meta {esc(f"{target:g}")}%</text>'
    )

    label_indexes = set(range(len(dates)))
    if len(dates) > 10:
        step = max(1, (len(dates) - 1) // 8)
        label_indexes = set(range(0, len(dates), step)) | {len(dates) - 1}
    for index, sample_date in enumerate(dates):
        if index not in label_indexes:
            continue
        x = x_position(sample_date)
        svg.append(
            f'<text class="history-axis-label" x="{x:.1f}" y="{height-bottom+28}" '
            f'text-anchor="middle">{sample_date.strftime("%d/%m/%Y")}</text>'
        )

    legend: list[str] = []
    for index, team in enumerate(teams):
        color = colors[index % len(colors)]
        points = sorted(
            (item for item in history if item["team"] == team),
            key=lambda item: item["date"],
        )
        coordinates = " ".join(
            f'{x_position(item["date"]):.1f},{y_position(item["adherence"]):.1f}'
            for item in points
        )
        if len(points) > 1:
            svg.append(
                f'<polyline class="history-line" stroke="{color}" points="{coordinates}"/>'
            )
        for item in points:
            x, y = x_position(item["date"]), y_position(item["adherence"])
            title = (
                f'{team} · {item["date"].strftime("%d/%m/%Y")} · '
                f'{pct(item["adherence"])} · {item["servers"]} ativos · {item["failed"]} FAILs'
            )
            svg.append(
                f'<circle class="history-point" fill="{color}" cx="{x:.1f}" cy="{y:.1f}" r="5">'
                f'<title>{esc(title)}</title></circle>'
            )
        legend.append(
            f'<span class="legend-item"><span class="legend-dot" style="background:{color}"></span>'
            f'{esc(team)}</span>'
        )
    svg.append("</svg>")
    return (
        '<div class="history-chart-wrap">'
        + "".join(svg)
        + '</div><div class="legend history-legend">'
        + "".join(legend)
        + "</div>"
    )


HTML = r"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__PAGE_TITLE__</title>
<style>
:root {
  /* Claro Brand Colors */
  --claro-red: #D52B1E;
  --claro-red-dark: #B51D12;
  --claro-red-light: #FF6B5A;
  
  /* Semantic Colors */
  --critical: #D52B1E;
  --medium: #F59E0B;
  --low: #FACC15;
  --warning: #F59E0B;
  --success: #27AE60;
  --info: #2E7BD6;
  --neutral: #6B7280;
  
  /* Light Theme */
  --bg-primary: #FFFFFF;
  --bg-secondary: #F8F9FA;
  --bg-tertiary: #F3F4F6;
  --surface: #FFFFFF;
  --surface-hover: #F9FAFB;
  
  --text-primary: #111827;
  --text-secondary: #4B5563;
  --text-tertiary: #9CA3AF;
  --text-inverse: #FFFFFF;
  
  --border: #E5E7EB;
  --border-focus: #D52B1E;
  
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  
  --radius-sm: 6px;
  --radius: 10px;
  --radius-lg: 16px;
  --radius-xl: 24px;
  
  --transition: background-color 0.15s ease, border-color 0.15s ease, color 0.15s ease;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
  min-height: 100vh;
}

/* Header */
.header {
  background: #F00000;
  color: var(--text-inverse);
  border-bottom: 1px solid var(--claro-red-dark);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-content {
  max-width: 1600px;
  margin: 0 auto;
  min-height: 118px;
  padding: 1rem 2rem;
  display: grid;
  grid-template-columns: 180px 1fr 180px;
  align-items: center;
  gap: 2rem;
}

.brand {
  display: flex;
  align-items: center;
}

.brand-logo {
  display: block;
  width: 84px;
  height: 84px;
  object-fit: contain;
}

.header-title {
  text-align: center;
}

.header-title h1 {
  font-size: clamp(1.5rem, 2.4vw, 2.35rem);
  font-weight: 800;
  color: var(--text-inverse);
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.header-title p {
  margin-top: 0.35rem;
  font-size: 0.95rem;
  color: var(--text-inverse);
}

.report-date {
  text-align: right;
  color: var(--text-inverse);
  line-height: 1.35;
}

.report-date span {
  display: block;
  font-size: 0.8rem;
  font-weight: 700;
}

.report-date strong {
  display: block;
  margin-top: 0.25rem;
  font-size: 1rem;
}

/* Main Content */
main {
  max-width: 1600px;
  margin: 0 auto;
  padding: 2rem;
}

.context-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding: 0.75rem 1rem;
  background: var(--bg-secondary);
  border-radius: var(--radius);
  font-size: 0.875rem;
  color: var(--text-secondary);
}

/* Dashboard Grid */
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

.overview-section {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 1.5rem;
  align-items: start;
}

.overview-section .left-col {
  grid-row: 1 / span 2;
}

.overview-section .assets-section {
  grid-column: 2;
}

.summary-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.action-section {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 1.5rem;
  align-items: start;
}

/* Cards */
.card {
  background: var(--surface);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border);
  box-shadow: var(--shadow);
  overflow: hidden;
}

.card-header {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid var(--border);
  background: var(--bg-secondary);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-title {
  font-size: 0.875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-secondary);
}

.card-body {
  padding: 1.25rem;
}

/* Left Column */
.left-col {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Donut Charts */
.donut-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.donut {
  position: relative;
  width: var(--size, 140px);
  height: var(--size, 140px);
}

.donut svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.donut circle {
  fill: none;
  stroke-width: 12;
  stroke-linecap: round;
}

.donut .track {
  stroke: var(--bg-tertiary);
}

.donut .progress {
  stroke: var(--color, var(--claro-red));
}

.donut-content {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.donut-content strong {
  font-size: 1.75rem;
  font-weight: 800;
  color: var(--text-primary);
  line-height: 1;
}

.donut-content small {
  font-size: 0.75rem;
  color: var(--text-secondary);
  margin-top: 0.25rem;
}

/* Risk Donut Multi-color */
.risk-donut .risk-seg {
  stroke-width: 12;
  stroke-linecap: butt;
}

.risk-high { stroke: var(--critical); }
.risk-medium { stroke: var(--medium); }
.risk-low { stroke: var(--low); }
.risk-unknown { stroke: var(--neutral); }

/* Legend */
.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  justify-content: center;
  font-size: 0.75rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  color: var(--text-secondary);
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

/* Big Numbers */
.big-number {
  text-align: center;
  padding: 1.5rem;
}

.big-number strong {
  display: block;
  font-size: 3rem;
  font-weight: 800;
  background: linear-gradient(135deg, var(--claro-red), var(--claro-red-light));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  line-height: 1;
}

.big-number span {
  font-size: 0.875rem;
  color: var(--text-secondary);
  margin-top: 0.5rem;
  display: block;
}

/* Metrics */
.metric {
  display: flex;
  flex-direction: column;
  padding: 1rem 0;
  border-bottom: 1px solid var(--border);
}

.metric:last-child {
  border-bottom: none;
}

.metric-value {
  font-size: 1.75rem;
  font-weight: 800;
  color: var(--text-primary);
}

.metric-label {
  font-size: 0.875rem;
  color: var(--text-secondary);
  margin-top: 0.25rem;
}

.metric.critical .metric-value {
  color: var(--critical);
}

/* Center Column */
.center-col {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Severity Cards Grid */
.severities-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.severity-card {
  background: var(--surface);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border);
  overflow: hidden;
}

.severity-card.critical {
  border-top: 3px solid var(--critical);
}

.severity-card.medium {
  border-top: 3px solid var(--medium);
}

.severity-card.low {
  border-top: 3px solid var(--low);
}

.severity-header {
  padding: 0.875rem 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: var(--bg-secondary);
}

.severity-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.severity-card.critical .severity-dot { background: var(--critical); }
.severity-card.medium .severity-dot { background: var(--medium); }
.severity-card.low .severity-dot { background: var(--low); }

.severity-header h3 {
  font-size: 0.875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.severity-body {
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.severity-metric {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
}

.severity-metric strong {
  font-size: 1.5rem;
  font-weight: 800;
}

.severity-card.critical .severity-metric strong { color: var(--critical); }
.severity-card.medium .severity-metric strong { color: var(--medium); }
.severity-card.low .severity-metric strong { color: #A16207; }

.severity-metric span {
  font-size: 0.75rem;
  color: var(--text-secondary);
}

.severity-footer {
  padding: 0.625rem 1rem;
  background: var(--bg-tertiary);
  font-size: 0.75rem;
  color: var(--text-secondary);
  text-align: center;
}

/* Asset Strip */
.asset-strip {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1px;
  background: var(--border);
}

.asset-item {
  background: var(--surface);
  padding: 1.25rem;
  text-align: center;
}

.asset-item strong {
  display: block;
  font-size: 1.75rem;
  font-weight: 800;
  color: var(--text-primary);
}

.asset-item span {
  font-size: 0.875rem;
  color: var(--text-secondary);
  margin-top: 0.25rem;
  display: block;
}

/* Tables */
.table-container {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.875rem;
}

th {
  text-align: left;
  padding: 0.875rem 1rem;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-secondary);
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border);
}

td {
  padding: 0.875rem 1rem;
  border-bottom: 1px solid var(--border);
  color: var(--text-primary);
}

tr:last-child td {
  border-bottom: none;
}

.numeric {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.control-id code {
  background: var(--bg-tertiary);
  padding: 0.25rem 0.5rem;
  border-radius: var(--radius-sm);
  font-family: 'SF Mono', monospace;
  font-size: 0.8rem;
  color: var(--claro-red);
}

.control-name {
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.empty-state {
  text-align: center;
  color: var(--text-tertiary);
  padding: 2rem;
}

/* Badges */
.badge {
  display: inline-flex;
  align-items: center;
  padding: 0.375rem 0.75rem;
  border-radius: var(--radius-lg);
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.badge.critical {
  background: rgba(213, 43, 30, 0.15);
  color: var(--critical);
}

.badge.medium {
  background: rgba(245, 158, 11, 0.16);
  color: #B45309;
}

.badge.low {
  background: rgba(250, 204, 21, 0.22);
  color: #854D0E;
}

.badge.warning {
  background: rgba(245, 158, 11, 0.16);
  color: #B45309;
}

.badge.success {
  background: rgba(39, 174, 96, 0.15);
  color: var(--success);
}

.badge.neutral {
  background: var(--bg-tertiary);
  color: var(--text-secondary);
}

/* Team Bars */
.team-row {
  display: grid;
  grid-template-columns: 160px 1fr 80px;
  align-items: center;
  gap: 1rem;
  padding: 0.875rem;
  border-bottom: 1px solid var(--border);
}

.team-row:last-child {
  border-bottom: none;
}

.team-info {
  display: flex;
  flex-direction: column;
}

.team-name {
  font-weight: 700;
  color: var(--text-primary);
  font-size: 0.875rem;
}

.team-servers {
  font-size: 0.75rem;
  color: var(--text-tertiary);
}

.team-bar-container {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.team-bar {
  flex: 1;
  height: 8px;
  background: var(--bg-tertiary);
  border-radius: var(--radius-lg);
  display: flex;
  overflow: hidden;
}

.bar-seg {
  height: 100%;
}

.bar-seg.critical { background: var(--critical); }
.bar-seg.medium { background: var(--medium); }
.bar-seg.low { background: var(--low); }

.team-stats {
  display: flex;
  gap: 0.5rem;
  font-size: 0.75rem;
}

.stat {
  padding: 0.125rem 0.375rem;
  border-radius: var(--radius-sm);
  font-weight: 700;
  min-width: 24px;
  text-align: center;
}

.stat.critical { background: rgba(213, 43, 30, 0.15); color: var(--critical); }
.stat.medium { background: rgba(245, 158, 11, 0.16); color: #B45309; }
.stat.low { background: rgba(250, 204, 21, 0.22); color: #854D0E; }

.team-adherence {
  text-align: right;
}

/* Right Column */
.right-col {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Inventory Section */
.history-chart-wrap {
  width: 100%;
  overflow-x: auto;
}

.history-svg {
  display: block;
  width: 100%;
  min-width: 700px;
  height: auto;
}

.history-grid {
  stroke: var(--border);
  stroke-width: 1;
}

.history-axis-label {
  fill: var(--text-secondary);
  font-size: 12px;
}

.history-target {
  stroke: var(--text-tertiary);
  stroke-width: 1.5;
  stroke-dasharray: 7 5;
}

.history-target-label {
  fill: var(--text-secondary);
  font-size: 12px;
  font-weight: 700;
}

.history-line {
  fill: none;
  stroke-width: 3;
  stroke-linejoin: round;
  stroke-linecap: round;
}

.history-point {
  stroke: var(--surface);
  stroke-width: 2;
}

.history-legend {
  margin-top: 0.75rem;
}

.inventory-section .card-body {
  padding: 0;
}

.assets-section .inventory-section {
  border: 0;
  border-top: 1px solid var(--border);
  border-radius: 0;
  box-shadow: none;
}

.assets-section .inventory-section .card-header {
  border-radius: 0;
}

/* Coverage Bar */
.coverage-cell {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.coverage-bar {
  flex: 1;
  height: 8px;
  background: var(--bg-tertiary);
  border-radius: var(--radius-lg);
  overflow: hidden;
  max-width: 120px;
}

.coverage-fill {
  height: 100%;
  border-radius: var(--radius-lg);
}

.coverage-fill.critical { background: var(--critical); }
.coverage-fill.warning { background: var(--warning); }
.coverage-fill.success { background: var(--success); }

.coverage-text {
  font-size: 0.875rem;
  font-weight: 600;
  min-width: 50px;
}

.team-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background: var(--claro-red);
  color: white;
  border-radius: var(--radius);
  font-size: 0.75rem;
  font-weight: 800;
  margin-right: 0.75rem;
}

/* Footnote */
.footnote {
  padding: 1.25rem;
  background: var(--bg-secondary);
  border-left: 4px solid var(--claro-red);
  border-radius: var(--radius);
  font-size: 0.875rem;
  color: var(--text-secondary);
  line-height: 1.7;
}

.footnote strong {
  color: var(--text-primary);
}

/* Footer */
footer {
  text-align: center;
  padding: 2rem;
  color: var(--text-tertiary);
  font-size: 0.875rem;
}

/* Responsive */
@media (max-width: 768px) {
  .header-content {
    min-height: auto;
    grid-template-columns: 64px 1fr;
    gap: 1rem;
    padding: 0.75rem 1rem;
  }

  .brand-logo {
    width: 58px;
    height: 58px;
  }

  .header-title {
    text-align: left;
  }

  .report-date {
    display: none;
  }

  .overview-section,
  .summary-section,
  .action-section {
    grid-template-columns: 1fr;
  }

  .overview-section .left-col,
  .overview-section .assets-section {
    grid-row: auto;
    grid-column: auto;
  }
  
  .severities-grid {
    grid-template-columns: 1fr;
  }
  
  .asset-strip {
    grid-template-columns: 1fr;
  }
  
  .team-row {
    grid-template-columns: 1fr;
    gap: 0.5rem;
  }
  
  .team-bar-container {
    order: 3;
  }
  
  main {
    padding: 1rem;
  }
}

/* Print Styles */
@media print {
  body {
    background: white;
  }
  
  .header {
    position: static;
    box-shadow: none;
  }
  
  .card {
    box-shadow: none;
    border: 1px solid #ddd;
    break-inside: avoid;
  }
  
  .dashboard {
    display: block;
  }
  
  .overview-section, .summary-section, .action-section,
  .assets-section, .history-section {
    margin-bottom: 1rem;
  }
}

</style>
</head>
<body>
<div class="header">
  <div class="header-content">
    <div class="brand">
      <img class="brand-logo" src="__LOGO_DATA__" alt="__CLIENT__">
    </div>
    <div class="header-title">
      <h1>__TITLE__</h1>
      <p>Unix · Visão consolidada de hardening</p>
    </div>
    <div class="report-date">
      <span>Data relatório</span>
      <strong>__REPORT_DATE__</strong>
    </div>
  </div>
</div>

<main>
  <div class="context-bar">
    <span>Resultados consolidados por equipe</span>
    <span>Atualizado em __DATE__</span>
  </div>
  
  <section class="dashboard">
    <section class="overview-section">
      <div class="left-col">
        <article class="card">
          <div class="card-header">
            <span class="card-title">% Conformidade</span>
          </div>
          <div class="card-body">
            <div class="donut-container">
              __COMPLIANCE_DONUT__
              <div class="legend">
                <span class="legend-item"><span class="legend-dot" style="background:var(--claro-red)"></span>PASSED</span>
                <span class="legend-item"><span class="legend-dot" style="background:var(--bg-tertiary)"></span>FAILED</span>
              </div>
            </div>
          </div>
        </article>
        
        <article class="card">
          <div class="card-header">
            <span class="card-title">% Risco nas não conformidades</span>
          </div>
          <div class="card-body">
            <div class="donut-container">
              __RISK_DONUT__
              <div class="legend">
                <span class="legend-item"><span class="legend-dot" style="background:var(--critical)"></span>Alta</span>
                <span class="legend-item"><span class="legend-dot" style="background:var(--medium)"></span>Média</span>
                <span class="legend-item"><span class="legend-dot" style="background:var(--low)"></span>Baixa</span>
              </div>
              <small style="color:var(--text-secondary);font-size:0.75rem;">__RISK_SUMMARY__</small>
            </div>
          </div>
        </article>
      </div>

      <section class="severities-grid">
        __SEVERITY_CARDS__
      </section>

    <article class="card assets-section">
      <div class="card-header">
        <span class="card-title">Ativos</span>
      </div>
      <div class="asset-strip">
          <div class="asset-item"><strong>__KNOWN__</strong><span>inventário conhecido*</span></div>
          <div class="asset-item"><strong>__AUDITED__</strong><span>auditados</span></div>
      </div>
      <section class="inventory-section">
        <div class="card-header">
          <span class="card-title">Cobertura de inventário por equipe</span>
        </div>
        <div class="card-body table-container">
          <table>
            <thead>
              <tr>
                <th>Equipe</th>
                <th class="numeric">Existentes (CMDB)</th>
                <th class="numeric">Auditados</th>
                <th class="numeric">GAP (não auditados)</th>
                <th>Cobertura</th>
              </tr>
            </thead>
            <tbody>
              __INVENTORY_ROWS__
            </tbody>
          </table>
        </div>
      </section>
    </article>
    </section>

    <section class="summary-section" aria-label="Indicadores consolidados">
      <article class="card">
        <div class="card-header">
          <span class="card-title">Meta por servidor</span>
        </div>
        <div class="card-body">
          <div class="big-number">
            <strong>__AT_TARGET__</strong>
            <span>na meta · __BELOW_TARGET__ abaixo</span>
          </div>
        </div>
      </article>

      <article class="card">
        <div class="card-header">
          <span class="card-title">Médias</span>
        </div>
        <div class="card-body">
          <div class="metric">
            <span class="metric-value">__AVG_FAILS__</span>
            <span class="metric-label">não conformidades por ativo</span>
          </div>
          <div class="metric">
            <span class="metric-value">__ADHERENCE__</span>
            <span class="metric-label">aderência consolidada</span>
          </div>
        </div>
      </article>
    </section>

    <article class="card">
      <div class="card-header">
        <span class="card-title">Não conformidades por equipe</span>
      </div>
      <div class="card-body">
        <div class="legend" style="justify-content:flex-start;margin-bottom:1rem;">
          <span class="legend-item"><span class="legend-dot" style="background:var(--critical)"></span>Alta</span>
          <span class="legend-item"><span class="legend-dot" style="background:var(--medium)"></span>Média</span>
          <span class="legend-item"><span class="legend-dot" style="background:var(--low)"></span>Baixa</span>
        </div>
        __TEAM_BARS__
      </div>
    </article>

    <section class="action-section" aria-label="Prioridades de correção">
      <article class="card">
        <div class="card-header">
          <span class="card-title">Correções prioritárias</span>
        </div>
        <div class="card-body">
          <div class="metric critical">
            <span class="metric-value">__HIGH__</span>
            <span class="metric-label">FAILs de criticidade alta</span>
          </div>
          <div class="donut-container" style="margin-top:1rem;">
            __TARGET_DONUT__
          </div>
        </div>
      </article>

      <article class="card">
        <div class="card-header">
          <span class="card-title">Principais não conformidades · Prioridade __CONTROL_FOCUS__</span>
        </div>
        <div class="card-body table-container">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Item não conforme</th>
                <th>Risco</th>
                <th class="numeric">Total</th>
              </tr>
            </thead>
            <tbody>
              __CONTROL_ROWS__
            </tbody>
          </table>
        </div>
      </article>
    </section>

    <article class="card history-section">
      <div class="card-header">
        <span class="card-title">Histórico de aderência por equipe</span>
        <span class="history-period">__HISTORY_PERIOD__</span>
      </div>
      <div class="card-body">
        __HISTORY_CHART__
      </div>
    </article>
    
    <aside class="footnote">
      <strong>Escopo:</strong> equipes e datas são descobertas exclusivamente pelos nomes dos arquivos. O painel principal usa a amostra mais recente de cada equipe; o histórico mantém um ponto por equipe/dia. Chave única equipe + servidor + Audit ID. O inventário é informado por equipe e não há conciliação por hostname. Equipes sem quantidade informada aparecem como "—". IDs excluídos: __EXCLUDED_IDS__. Arquivos ignorados por conteúdo: __SKIPPED__. Arquivos ignorados por falta de equipe/data no nome: __INVALID_NAMES__.
    </aside>
  </section>
  
  <footer>
    Indicadores de Hardening · HTML autocontido · __CLIENT__ · 2026
  </footer>
</main>

</body>
</html>"""


def generate(args: argparse.Namespace) -> None:
    directory = args.diretorio.expanduser().resolve()
    if not directory.is_dir():
        raise ValueError(f"Diretório não encontrado: {directory}")
    excluded_ids = {CORE.normalize_id(item) for item in args.excluir_ids.split(",") if CORE.normalize_id(item)}
    explicit_results = [path.expanduser().resolve() for path in args.resultado]
    files, skipped = discover_results(directory, explicit_results)
    latest_files, snapshots, invalid_names = organize_snapshots(files)
    teams, totals, controls, control_focus = summarize(latest_files, excluded_ids, TARGET)
    history = build_history(snapshots, excluded_ids, TARGET)

    inventories: dict[str, int] = {}
    for team, raw_count in parse_pairs(args.inventario, "--inventario").items():
        try:
            count = int(raw_count)
        except ValueError as error:
            raise ValueError(f"Quantidade inválida para {team}: {raw_count!r}") from error
        if count < 0:
            raise ValueError(f"Quantidade de inventário não pode ser negativa: {team}={count}")
        inventories[team] = count
    used_cmdb_names: set[str] = set()
    for team, raw_path in parse_pairs(args.cmdb, "--cmdb").items():
        path = Path(raw_path).expanduser()
        if not path.is_absolute():
            path = directory / path
        if not path.is_file():
            raise ValueError(f"CMDB não encontrado para {team}: {path}")
        inventories[team] = inventory_count(path)
        used_cmdb_names.add(path.name)

    detected_teams = {team["team"] for team in teams}
    unmatched_inventories = sorted(set(inventories).difference(detected_teams))
    if unmatched_inventories:
        print(
            "AVISO: inventário sem resultado correspondente: "
            + ", ".join(unmatched_inventories)
            + ". Equipes detectadas: "
            + ", ".join(sorted(detected_teams)),
            file=sys.stderr,
        )

    high_share = totals["high"] * 100 / totals["failed"] if totals["failed"] else 0.0
    target_share = totals["at_target"] * 100 / totals["servers"] if totals["servers"] else 0.0
    known_total = sum(inventories[team["team"]] for team in teams if team["team"] in inventories)
    known_label = integer(known_total) if inventories else "—"
    average_fails = totals["failed"] / totals["servers"] if totals["servers"] else 0.0
    history_dates = sorted({item["date"] for item in history})
    history_period = (
        history_dates[0].strftime("%d/%m/%Y")
        if len(history_dates) == 1
        else f'{history_dates[0].strftime("%d/%m/%Y")} a {history_dates[-1].strftime("%d/%m/%Y")}'
        if history_dates
        else "sem amostras"
    )
    
    logo_path = Path(__file__).with_name("Claro.png")
    if not logo_path.is_file():
        raise ValueError(f"Logo não encontrado: {logo_path}")
    logo_data = "data:image/png;base64," + base64.b64encode(logo_path.read_bytes()).decode("ascii")

    replacements = {
        "__PAGE_TITLE__": esc(f"{args.titulo} — {args.cliente}"),
        "__CLIENT__": esc(args.cliente), "__LOGO_DATA__": logo_data,
        "__TITLE__": esc(args.titulo), "__TARGET__": f"{TARGET:g}".replace(".", ","),
        "__DATE__": datetime.now().astimezone().strftime("%d/%m/%Y %H:%M %Z"),
        "__REPORT_DATE__": datetime.now().astimezone().strftime("%d/%m/%Y"),
        "__COMPLIANCE_DONUT__": donut(totals["adherence"], "var(--claro-red)", pct(totals["adherence"]), "PASSED"),
        "__RISK_DONUT__": risk_donut(
            totals["high"], totals["medium"], totals["low"], totals["uninformed"]
        ),
        "__RISK_SUMMARY__": (
            f"{pct(high_share)} Alta · "
            f"{pct(totals['medium'] * 100 / totals['failed'] if totals['failed'] else 0)} Média · "
            f"{pct(totals['low'] * 100 / totals['failed'] if totals['failed'] else 0)} Baixa"
        ),
        "__TARGET_DONUT__": donut(target_share, "var(--claro-red)", pct(target_share), "na meta"),
        "__SEVERITY_CARDS__": severity_cards(totals, teams),
        "__CONTROL_ROWS__": control_rows(controls), "__CONTROL_FOCUS__": esc(control_focus),
        "__TEAM_BARS__": team_bars(teams, TARGET),
        "__HISTORY_CHART__": history_chart(history, TARGET),
        "__HISTORY_PERIOD__": esc(history_period),
        "__INVENTORY_ROWS__": inventory_rows(teams, inventories),
        "__AUDITED__": integer(totals["servers"]), "__KNOWN__": known_label,
        "__HIGH__": integer(totals["high"]), "__AT_TARGET__": integer(totals["at_target"]),
        "__BELOW_TARGET__": integer(totals["below_target"]), "__ADHERENCE__": pct(totals["adherence"]),
        "__AVG_FAILS__": f"{average_fails:.1f}".replace(".", ","),
        "__EXCLUDED_IDS__": esc(", ".join(sorted(excluded_ids)) or "nenhum"),
        "__SKIPPED__": esc(", ".join(name for name in skipped if name not in used_cmdb_names) or "nenhum"),
        "__INVALID_NAMES__": esc(", ".join(invalid_names) or "nenhum"),
    }
    document = HTML
    for placeholder, value in replacements.items():
        document = document.replace(placeholder, value)
    args.saida.expanduser().resolve().write_text(document, encoding="utf-8")
    print(f"Dashboard gerado: {args.saida.expanduser().resolve()}")
    print(f"Resumo: {len(teams)} equipes | {totals['servers']} auditados | {totals['failed']} FAILs | aderência {totals['adherence']:.1f}%")
    print(f"Histórico: {len(history)} pontos diários | {len(history_dates)} datas")
    for team in teams:
        known = inventories.get(team["team"])
        coverage = f"{team['servers']}/{known}" if known is not None else f"{team['servers']}/—"
        print(f"  {team['team']}: cobertura {coverage}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard operacional de hardening - Identidade Visual Claro")
    parser.add_argument("diretorio", nargs="?", type=Path, default=Path("."), help="Diretório dos arquivos")
    parser.add_argument("-o", "--saida", type=Path, default=Path("dashboard_hardening.html"))
    parser.add_argument("--resultado", action="append", default=[], type=Path, help="Resultado explícito; pode repetir")
    parser.add_argument("--cmdb", action="append", default=[], metavar="EQUIPE=ARQUIVO", help="Associa CMDB a uma equipe")
    parser.add_argument("--inventario", action="append", default=[], metavar="EQUIPE=TOTAL", help="Total conhecido sem CMDB")
    parser.add_argument("--excluir-ids", default="999")
    parser.add_argument("--cliente", default="Claro")
    parser.add_argument("--titulo", default="Baseline de Servidores Unix")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        generate(args)
        return 0
    except (OSError, ValueError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
