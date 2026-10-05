#!/usr/bin/env python3
"""Gera a visão gerencial de hardening para uma única equipe.

Seleciona a família informada em --equipe, usa a coleta mais recente como
fotografia atual e as anteriores como histórico. O conteúdo é direcionado ao
gerente da equipe, com foco em risco, tendência, esforço e decisão.
"""

from __future__ import annotations

import argparse
import base64
import csv
from collections import Counter, defaultdict
from collections.abc import Iterable, Iterator
from datetime import datetime
import html
import math
from pathlib import Path
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile

SCRIPT_DIR = Path(__file__).resolve().parent
XML_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
REQUIRED_COLUMNS = {"asset.host_name", "compliance.audit_ID", "compliance_result"}
SEVERITY_ORDER = {"Alta": 0, "M\u00e9dia": 1, "Baixa": 2, "N\u00e3o informada": 3}

class Core:
    @staticmethod
    def clean(value):
        return " ".join(str(value or "").strip().split())

    @classmethod
    def fold(cls, value):
        text = unicodedata.normalize("NFKD", cls.clean(value))
        return "".join(c for c in text if not unicodedata.combining(c)).casefold()

    @classmethod
    def normalize_id(cls, value):
        text = cls.clean(value)
        return text.split(".", 1)[0] if re.fullmatch(r"\d+\.0+", text) else text

    @classmethod
    def normalize_status(cls, value):
        status = cls.fold(value).replace("_", " ").replace("-", " ")
        if status in {"passed", "pass", "compliant", "conforme", "ok", "true"}:
            return "PASSED"
        if status in {"failed", "fail", "non compliant", "nao conforme", "nok", "false"}:
            return "FAILED"
        return "UNKNOWN"

    @classmethod
    def normalize_severity(cls, value):
        severity = cls.fold(value)
        if severity in {"critica", "critical", "alta", "high"}:
            return "Alta"
        if severity in {"media", "medium", "moderada", "moderate"}:
            return "M\u00e9dia"
        if severity in {"baixa", "low"}:
            return "Baixa"
        return "N\u00e3o informada"

    @staticmethod
    def parse_audit_name(record):
        value = record.get("compliance.audit_name", "")
        if not value or record.get("compliance.audit_ID"):
            return
        parts = [part.strip() for part in value.split(",", 2)]
        if parts:
            record["compliance.audit_ID"] = parts[0]
        if len(parts) > 1:
            record["compliance.audit_name"] = parts[1]
        if len(parts) > 2:
            record["compliance.audit_criticidade"] = parts[2]

    @staticmethod
    def column_index(reference):
        match = re.match(r"[A-Z]+", reference or "A")
        number = 0
        for letter in (match.group(0) if match else "A"):
            number = number * 26 + ord(letter) - 64
        return number - 1

    @classmethod
    def read_xlsx(cls, path):
        with zipfile.ZipFile(path) as archive:
            names = set(archive.namelist())
            shared = []
            if "xl/sharedStrings.xml" in names:
                root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
                shared = ["".join(node.itertext()) for node in root.findall(f"{XML_NS}si")]
            sheets = sorted(n for n in names if re.fullmatch(r"xl/worksheets/sheet\d+\.xml", n))
            if not sheets:
                raise ValueError("XLSX sem planilha legivel.")
            rows = []
            with archive.open(sheets[0]) as source:
                for _, element in ET.iterparse(source, events=("end",)):
                    if element.tag != f"{XML_NS}row":
                        continue
                    values = {}
                    for cell in element.findall(f"{XML_NS}c"):
                        index = cls.column_index(cell.get("r", "A1"))
                        kind = cell.get("t", "")
                        node = cell.find(f"{XML_NS}v")
                        if kind == "inlineStr":
                            inline = cell.find(f"{XML_NS}is")
                            value = "" if inline is None else "".join(inline.itertext())
                        elif node is None:
                            value = ""
                        elif kind == "s":
                            value = shared[int(node.text or "0")]
                        else:
                            value = node.text or ""
                        values[index] = value
                    rows.append([values.get(i, "") for i in range(max(values, default=-1) + 1)])
                    element.clear()
        if not rows:
            return []
        headers = [cls.clean(x).lstrip("\ufeff") for x in rows[0]]
        return [{h: row[i] if i < len(row) else "" for i, h in enumerate(headers)}
                for row in rows[1:] if any(cls.clean(x) for x in row)]

    @staticmethod
    def read_csv(path):
        raw = path.read_bytes()[:65536]
        try:
            sample, encoding = raw.decode("utf-8-sig"), "utf-8-sig"
        except UnicodeDecodeError:
            sample, encoding = raw.decode("latin-1"), "latin-1"
        try:
            dialect = csv.Sniffer().sniff(sample, delimiters=",;\t|")
        except csv.Error:
            dialect = csv.excel
        with path.open("r", encoding=encoding, newline="") as source:
            for row in csv.DictReader(source, dialect=dialect):
                yield {(k or "").lstrip("\ufeff").strip(): v or "" for k, v in row.items()}

    @classmethod
    def load_records(cls, path):
        suffix = path.suffix.casefold()
        records = cls.read_xlsx(path) if suffix == ".xlsx" else cls.read_csv(path) if suffix in {".csv", ".tsv"} else None
        if records is None:
            raise ValueError("Formato nao suportado. Use .xlsx, .csv ou .tsv.")
        iterator = iter(records)
        try:
            first = next(iterator)
        except StopIteration as error:
            raise ValueError("Arquivo sem registros.") from error
        cls.parse_audit_name(first)
        missing = REQUIRED_COLUMNS.difference(first)
        if missing:
            raise ValueError("Colunas obrigatorias ausentes: " + ", ".join(sorted(missing)))
        yield first
        for record in iterator:
            cls.parse_audit_name(record)
            yield record

    @staticmethod
    def choose_input():
        candidates = [p for pattern in ("*.xlsx", "*.csv", "*.tsv")
                      for p in Path.cwd().glob(pattern) if not p.name.startswith("~$")]
        if not candidates:
            raise ValueError("Nenhum XLSX/CSV/TSV no diretorio atual.")
        return max(candidates, key=lambda p: p.stat().st_mtime)

    @classmethod
    def best_text(cls, rows, field):
        values = [cls.clean(r.get(field, "")) for r in rows if cls.clean(r.get(field, ""))]
        return Counter(values).most_common(1)[0][0] if values else "\u2014"

    @classmethod
    def build_model(cls, records, excluded_ids, target):
        excluded_rows = ignored_rows = duplicates = 0
        unique = {}
        for record in records:
            host = cls.clean(record.get("asset.host_name")) or cls.clean(record.get("asset.name"))
            control_id = cls.normalize_id(record.get("compliance.audit_ID"))
            if control_id in excluded_ids:
                excluded_rows += 1
                continue
            if not host or not control_id:
                ignored_rows += 1
                continue
            key = (host.casefold(), control_id)
            duplicates += int(key in unique)
            unique[key] = {
                "asset.host_name": sys.intern(host),
                "asset.ip_addresses": sys.intern(cls.clean(record.get("asset.ip_addresses"))),
                "asset.operating_systems": sys.intern(cls.clean(record.get("asset.operating_systems"))),
                "compliance.audit_name": sys.intern(cls.clean(record.get("compliance.audit_name"))),
                "compliance.audit_criticidade": sys.intern(cls.normalize_severity(record.get("compliance.audit_criticidade"))),
                "compliance_result": sys.intern(cls.normalize_status(record.get("compliance_result"))),
            }
        by_host = defaultdict(list)
        for (host_key, _), record in unique.items():
            by_host[host_key].append(record)
        servers = []
        all_passed = all_failed = all_unknown = 0
        for rows in by_host.values():
            statuses = Counter(cls.normalize_status(r.get("compliance_result")) for r in rows)
            passed, failed, unknown = statuses["PASSED"], statuses["FAILED"], statuses["UNKNOWN"]
            evaluated = passed + failed
            adherence = passed * 100 / evaluated if evaluated else 0.0
            failures = Counter(cls.normalize_severity(r.get("compliance.audit_criticidade"))
                               for r in rows if cls.normalize_status(r.get("compliance_result")) == "FAILED")
            servers.append({
                "host": cls.best_text(rows, "asset.host_name"), "ip": cls.best_text(rows, "asset.ip_addresses"),
                "os": cls.best_text(rows, "asset.operating_systems"), "passed": passed, "failed": failed,
                "unknown": unknown, "total": evaluated, "adherence": adherence,
                "gap": max(0, math.ceil(evaluated * target / 100) - passed),
                "at_target": evaluated > 0 and adherence >= target,
                "high": failures["Alta"], "medium": failures["M\u00e9dia"],
                "low": failures["Baixa"], "unspecified": failures["N\u00e3o informada"],
            })
            all_passed += passed
            all_failed += failed
            all_unknown += unknown
        servers.sort(key=lambda x: (-x["high"], -x["failed"], -x["medium"], x["adherence"], x["host"].casefold()))
        by_control = defaultdict(list)
        for (_, control_id), record in unique.items():
            by_control[control_id].append(record)
        controls = []
        for control_id, rows in by_control.items():
            statuses = Counter(cls.normalize_status(r.get("compliance_result")) for r in rows)
            severities = Counter(cls.normalize_severity(r.get("compliance.audit_criticidade")) for r in rows)
            severity = sorted(severities, key=lambda x: (-severities[x], SEVERITY_ORDER[x]))[0]
            evaluated = statuses["PASSED"] + statuses["FAILED"]
            controls.append({
                "id": control_id, "name": cls.best_text(rows, "compliance.audit_name"), "severity": severity,
                "failed": statuses["FAILED"], "passed": statuses["PASSED"], "total": evaluated,
                "failure_rate": statuses["FAILED"] * 100 / evaluated if evaluated else 0.0,
            })
        controls.sort(key=lambda x: (x["failed"] == 0, SEVERITY_ORDER[x["severity"]], -x["failed"], -x["failure_rate"], x["id"]))
        evaluated = all_passed + all_failed
        severity_failures = Counter()
        for server in servers:
            severity_failures.update({"Alta": server["high"], "M\u00e9dia": server["medium"],
                                      "Baixa": server["low"], "N\u00e3o informada": server["unspecified"]})
        return {
            "servers": servers, "controls": controls, "server_count": len(servers), "control_count": len(controls),
            "passed": all_passed, "failed": all_failed, "unknown": all_unknown, "evaluated": evaluated,
            "average": all_passed * 100 / evaluated if evaluated else 0.0,
            "at_target": sum(x["at_target"] for x in servers),
            "high_affected_hosts": sum(x["high"] > 0 for x in servers),
            "gap_to_all": sum(x["gap"] for x in servers), "severity_failures": severity_failures,
            "excluded_rows": excluded_rows, "ignored_rows": ignored_rows, "duplicates": duplicates, "target": target,
        }

    @staticmethod
    def severity_badge(severity):
        css = {"Alta": "high", "M\u00e9dia": "medium", "Baixa": "low"}.get(severity, "unknown")
        return f'<span class="badge {css}">{html.escape(severity, quote=True)}</span>'

CORE = Core()

def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def integer(value: int) -> str:
    return f"{value:,}".replace(",", ".")


def pct(value: float) -> str:
    return f"{value:.1f}%".replace(".", ",")


def donut(value: float, color: str, center: str, label: str) -> str:
    bounded = max(0.0, min(100.0, value))
    circumference = 326.73
    offset = circumference * (1 - bounded / 100)
    return f"""
    <div class="donut" style="--color:{color}">
      <svg viewBox="0 0 120 120" aria-hidden="true">
        <circle class="track" cx="60" cy="60" r="52"></circle>
        <circle class="progress" cx="60" cy="60" r="52"
          stroke-dasharray="{circumference:.2f}" stroke-dashoffset="{offset:.2f}"></circle>
      </svg>
      <div class="donut-content"><strong>{esc(center)}</strong><small>{esc(label)}</small></div>
    </div>"""


def risk_donut(model: dict) -> str:
    failures = model["failed"] or 1
    high = model["severity_failures"]["Alta"] * 100 / failures
    medium = model["severity_failures"]["Média"] * 100 / failures
    low = model["severity_failures"]["Baixa"] * 100 / failures
    medium_end = high + medium
    low_end = medium_end + low
    return f"""
    <div class="risk-ring" style="background:conic-gradient(var(--critical) 0 {high:.3f}%,var(--medium) {high:.3f}% {medium_end:.3f}%,var(--low) {medium_end:.3f}% {low_end:.3f}%,var(--neutral) {low_end:.3f}% 100%)">
      <div><strong>{integer(model['failed'])}</strong><small>FAILs</small></div>
    </div>"""


def severity_cards(model: dict) -> str:
    config = (
        ("Alta", "critical", "Tratar primeiro"),
        ("Média", "medium", "Planejar correção"),
        ("Baixa", "low", "Acompanhar backlog"),
        ("Não informada", "neutral", "Classificar risco"),
    )
    return "".join(
        f"""<article class="severity-card {css}">
          <span>{esc(label)}</span><strong>{integer(model['severity_failures'][label])}</strong>
          <small>{esc(hint)}</small>
        </article>"""
        for label, css, hint in config
    )


def host_bars(servers: list[dict]) -> str:
    selected = servers[:10]
    maximum = max((item["high"] + item["medium"] + item["low"] for item in selected), default=1) or 1
    rows: list[str] = []
    for item in selected:
        high = item["high"] * 100 / maximum
        medium = item["medium"] * 100 / maximum
        low = item["low"] * 100 / maximum
        rows.append(f"""
        <div class="bar-row">
          <div class="bar-label" title="{esc(item['host'])}"><strong>{esc(item['host'])}</strong><small>{esc(item['ip'])}</small></div>
          <div class="bar-track"><span class="bar-high" style="width:{high:.3f}%"></span><span class="bar-medium" style="width:{medium:.3f}%"></span><span class="bar-low" style="width:{low:.3f}%"></span></div>
          <div class="bar-value">A {integer(item['high'])} · M {integer(item['medium'])} · B {integer(item['low'])}</div>
        </div>""")
    return "".join(rows) or '<p class="empty">Nenhum host para exibir.</p>'


def priority_control_rows(controls: list[dict]) -> str:
    rows: list[str] = []
    for position, control in enumerate((item for item in controls if item["failed"] > 0), 1):
        if position > 10:
            break
        rows.append(f"""
        <tr>
          <td class="rank">{position}</td><td><strong>{esc(control['id'])}</strong></td>
          <td>{esc(control['name'])}</td><td>{CORE.severity_badge(control['severity'])}</td>
          <td class="numeric fail">{integer(control['failed'])}</td>
          <td class="numeric">{pct(control['failure_rate'])}</td>
        </tr>""")
    return "".join(rows) or '<tr><td colspan="6" class="empty">Nenhuma não conformidade encontrada.</td></tr>'


def server_rows(servers: list[dict]) -> str:
    rows: list[str] = []
    for position, server in enumerate(servers, 1):
        state = "ok" if server["at_target"] else "below"
        label = "Na meta" if server["at_target"] else "Abaixo da meta"
        rows.append(f"""
        <tr data-state="{state}">
          <td class="rank">{position}</td>
          <td><strong>{esc(server['host'])}</strong><small>{esc(server['ip'])}</small></td>
          <td class="os" title="{esc(server['os'])}">{esc(server['os'])}</td>
          <td class="numeric critical-text">{integer(server['high'])}</td>
          <td class="numeric medium-text">{integer(server['medium'])}</td>
          <td class="numeric">{integer(server['low'])}</td>
          <td class="numeric fail">{integer(server['failed'])}</td>
          <td><div class="progress-line"><span style="width:{server['adherence']:.3f}%"></span></div><strong>{pct(server['adherence'])}</strong></td>
          <td class="numeric">{integer(server['gap'])}</td>
          <td><span class="status {state}">{label}</span></td>
        </tr>""")
    return "".join(rows)


def control_rows(controls: list[dict]) -> str:
    rows: list[str] = []
    for control in controls:
        rows.append(f"""
        <tr>
          <td><strong>{esc(control['id'])}</strong></td><td>{esc(control['name'])}</td>
          <td>{CORE.severity_badge(control['severity'])}</td>
          <td class="numeric fail">{integer(control['failed'])}</td>
          <td class="numeric">{integer(control['passed'])}</td>
          <td class="numeric">{integer(control['total'])}</td>
          <td><div class="progress-line failure"><span style="width:{control['failure_rate']:.3f}%"></span></div><strong>{pct(control['failure_rate'])}</strong></td>
        </tr>""")
    return "".join(rows)

DATE_PATTERN = re.compile(r"_(\d{2})_(\d{2})_(\d{4})(?:_|$)")


def result_datetime(path: Path) -> datetime | None:
    match = DATE_PATTERN.search(path.stem)
    if not match:
        return None
    month, day, year = map(int, match.groups())
    try:
        return datetime(year, month, day)
    except ValueError:
        return None


def discover_team_files(seed: Path | None, team: str) -> list[tuple[datetime, Path]]:
    location = (seed or Path.cwd()).expanduser()
    directory = location if location.is_dir() else location.parent
    directory = directory.resolve()
    if not directory.is_dir():
        raise ValueError(f"Diretório de busca não encontrado: {directory}")
    prefix = team.casefold()
    candidates = sorted(
        path for pattern in ("*.xlsx", "*.csv", "*.tsv")
        for path in directory.glob(pattern)
        if path.name.casefold().startswith(prefix) and not path.name.startswith("~$")
    )
    if not candidates:
        raise ValueError(
            f"Nenhum arquivo da família {team!r} encontrado em {directory}. "
            f"Esperado: {team}*.csv/xlsx/tsv"
        )
    dated = [(captured_at, path) for path in candidates if (captured_at := result_datetime(path))]
    invalid = [path.name for path in candidates if result_datetime(path) is None]
    if not dated:
        raise ValueError(
            f"Os arquivos de {team!r} não possuem data no padrão _MM_DD_AAAA_: "
            + ", ".join(invalid)
        )
    daily: dict[datetime, Path] = {}
    for captured_at, path in dated:
        current = daily.get(captured_at)
        if current is None or path.name > current.name:
            daily[captured_at] = path
    return sorted(daily.items())


def build_history(samples: list[tuple[datetime, Path]], excluded_ids: set[str], target: float) -> list[dict]:
    history: list[dict] = []
    for captured_at, path in samples:
        model = CORE.build_model(CORE.load_records(path), excluded_ids, target)
        history.append({
            "date": captured_at,
            "path": path,
            "adherence": model["average"],
            "servers": model["server_count"],
            "failed": model["failed"],
            "at_target": model["at_target"],
        })
    return history


def metric_history(history: list[dict], key: str, color: str, title: str, percent: bool = False, target: float | None = None) -> str:
    width, height = 520, 220
    left, right, top, bottom = 48, 18, 28, 42
    plot_width, plot_height = width - left - right, height - top - bottom
    values = [float(item[key]) for item in history]
    maximum = 100.0 if percent else max(values, default=0.0)
    maximum = max(1.0, maximum)
    x_step = plot_width / max(1, len(history) - 1)

    def x(index: int) -> float:
        return left + (plot_width / 2 if len(history) == 1 else index * x_step)

    def y(value: float) -> float:
        return top + (maximum - value) * plot_height / maximum

    elements = [
        f'<svg viewBox="0 0 {width} {height}" role="img" aria-label="{esc(title)}">',
        f'<line class="history-axis" x1="{left}" y1="{top}" x2="{left}" y2="{height-bottom}"/>',
        f'<line class="history-axis" x1="{left}" y1="{height-bottom}" x2="{width-right}" y2="{height-bottom}"/>',
    ]
    for ratio in (0, .5, 1):
        value = maximum * ratio
        grid_y = y(value)
        label = pct(value) if percent else integer(round(value))
        elements.append(f'<line class="history-gridline" x1="{left}" y1="{grid_y:.1f}" x2="{width-right}" y2="{grid_y:.1f}"/>')
        elements.append(f'<text class="history-label" x="{left-7}" y="{grid_y+4:.1f}" text-anchor="end">{label}</text>')
    if target is not None:
        target_y = y(target)
        elements.append(f'<line class="history-target" x1="{left}" y1="{target_y:.1f}" x2="{width-right}" y2="{target_y:.1f}"/>')
    points = " ".join(f"{x(index):.1f},{y(value):.1f}" for index, value in enumerate(values))
    elements.append(f'<polyline class="history-line" style="stroke:{color}" points="{points}"/>')
    for index, (item, value) in enumerate(zip(history, values)):
        point_x, point_y = x(index), y(value)
        shown = pct(value) if percent else integer(round(value))
        elements.append(f'<circle class="history-point" style="fill:{color}" cx="{point_x:.1f}" cy="{point_y:.1f}" r="5"><title>{item["date"].strftime("%d/%m/%Y")}: {shown}</title></circle>')
        elements.append(f'<text class="history-value" x="{point_x:.1f}" y="{point_y-10:.1f}" text-anchor="middle">{shown}</text>')
        elements.append(f'<text class="history-label" x="{point_x:.1f}" y="{height-bottom+23}" text-anchor="middle">{item["date"].strftime("%d/%m")}</text>')
    elements.append("</svg>")
    return f'<div class="history-metric"><h3>{esc(title)}</h3>{"".join(elements)}</div>'


def history_chart(history: list[dict], target: float) -> str:
    if not history:
        return '<p class="empty">Sem histórico disponível.</p>'
    charts = (
        metric_history(history, "adherence", "var(--success)", "Aderência consolidada", True, target)
        + metric_history(history, "failed", "var(--critical)", "Total de FAILs")
        + metric_history(history, "servers", "var(--info)", "Servidores auditados")
    )
    latest = history[-1]
    previous = history[-2] if len(history) > 1 else None
    delta = ""
    if previous:
        adherence_delta = latest["adherence"] - previous["adherence"]
        fail_delta = latest["failed"] - previous["failed"]
        server_delta = latest["servers"] - previous["servers"]
        adherence_label = f"{adherence_delta:+.1f}".replace(".", ",")
        delta = (
            f'<div class="history-delta"><strong>Variação da última coleta:</strong> '
            f'aderência {adherence_label} p.p. · FAILs {fail_delta:+d} · servidores {server_delta:+d}</div>'
        )
    return f'<div class="history-charts">{charts}</div>{delta}'




def quantity(value: int, singular: str, plural: str) -> str:
    return f"{integer(value)} {singular if value == 1 else plural}"


def management_actions(model: dict) -> str:
    high = model["severity_failures"]["Alta"]
    high_hosts = model["high_affected_hosts"]
    below = model["server_count"] - model["at_target"]
    gap = model["gap_to_all"]
    failed_controls = [item for item in model["controls"] if item["failed"] > 0]
    top_control = failed_controls[0] if failed_controls else None
    actions = []
    if high:
        actions.append((
            "critical", "Risco imediato",
            f"Apoiar a remoção de {quantity(high, 'FAIL Alto', 'FAILs Altos')} em "
            f"{quantity(high_hosts, 'host', 'hosts')}."
        ))
    else:
        actions.append((
            "success", "Risco imediato",
            "Sem FAILs Altos na coleta atual; manter prevenção e monitoramento."
        ))
    if below:
        actions.append((
            "warning", "Meta por servidor",
            f"Direcionar capacidade para {quantity(below, 'host abaixo', 'hosts abaixo')} da meta; "
            f"gap mínimo de {quantity(gap, 'correção', 'correções')}."
        ))
    else:
        actions.append((
            "success", "Meta por servidor",
            "Todos os hosts atingiram 80%; preservar o resultado no próximo ciclo."
        ))
    if top_control:
        actions.append((
            "info", "Maior alavanca",
            f"Priorizar o controle {esc(top_control['id'])} — "
            f"{esc(top_control['name'])} — com "
            f"{quantity(top_control['failed'], 'FAIL', 'FAILs')}."
        ))
    else:
        actions.append(("success", "Maior alavanca", "Nenhum controle com FAIL na coleta atual."))
    return "".join(
        f'<article class="decision {css}"><span>{title}</span><p>{text}</p></article>'
        for css, title, text in actions
    )

HTML = r"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>__PAGE_TITLE__</title>
<style>
:root{--claro-red:#D52B1E;--claro-dark:#B51D12;--critical:#D52B1E;--medium:#F59E0B;--low:#FACC15;--success:#27AE60;--info:#2E7BD6;--neutral:#6B7280;--bg:#fff;--soft:#F8F9FA;--muted-bg:#F3F4F6;--text:#111827;--muted:#4B5563;--border:#E5E7EB;--shadow:0 4px 8px rgba(0,0,0,.09);--radius:16px}
*{box-sizing:border-box;margin:0;padding:0}body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;color:var(--text);background:#fff;line-height:1.55}.header{background:#F00000;color:#fff}.header-inner{max-width:1600px;min-height:118px;margin:auto;padding:1rem 2rem;display:grid;grid-template-columns:180px 1fr 180px;align-items:center;gap:2rem}.logo{width:84px;height:84px;object-fit:contain}.header-title{text-align:center}.header-title h1{font-size:clamp(1.55rem,2.5vw,2.4rem);line-height:1.15}.header-title p{margin-top:.4rem}.report-date{text-align:right}.report-date span{display:block;font-size:.78rem;font-weight:700}.report-date strong{display:block;margin-top:.25rem}
main{max-width:1600px;margin:auto;padding:2rem}.context{display:flex;justify-content:space-between;gap:1rem;padding:.8rem 1rem;margin-bottom:1.5rem;background:var(--soft);border-radius:10px;color:var(--muted);font-size:.86rem}.dashboard{display:flex;flex-direction:column;gap:1.5rem}.card{border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden;background:#fff}.card-header{display:flex;justify-content:space-between;align-items:center;gap:1rem;padding:1rem 1.25rem;background:var(--soft);border-bottom:1px solid var(--border)}.card-title{font-size:.85rem;font-weight:800;text-transform:uppercase;letter-spacing:.055em;color:var(--muted)}.card-subtitle{font-size:.78rem;color:var(--muted);margin-top:.15rem}.card-body{padding:1.25rem}
.hero{display:grid;grid-template-columns:1.35fr .65fr;gap:1.5rem}.hero-message{padding:1.8rem;background:linear-gradient(135deg,#F00000,var(--claro-dark));color:#fff;border-radius:var(--radius);box-shadow:var(--shadow)}.hero-message .eyebrow{font-size:.75rem;font-weight:800;text-transform:uppercase;letter-spacing:.08em;opacity:.85}.hero-message h2{font-size:clamp(1.7rem,3vw,2.75rem);line-height:1.12;margin:.65rem 0}.hero-message p{font-size:1rem;max-width:900px}.trend{display:inline-flex;margin-top:1.25rem;padding:.55rem .8rem;border-radius:99px;background:rgba(255,255,255,.18);font-weight:700;font-size:.83rem}.hero-donut{display:flex;align-items:center;justify-content:center;min-height:280px}
.kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:1rem}.kpi{border:1px solid var(--border);border-top:4px solid var(--claro-red);border-radius:12px;padding:1.05rem;background:#fff;box-shadow:var(--shadow)}.kpi span{display:block;color:var(--muted);font-size:.72rem;text-transform:uppercase;font-weight:700}.kpi strong{display:block;font-size:1.75rem;margin:.25rem 0}.kpi small{color:var(--muted);font-size:.72rem}
.donut{position:relative;width:170px;height:170px}.donut svg{width:100%;height:100%;transform:rotate(-90deg)}.donut circle{fill:none;stroke-width:12}.donut .track{stroke:var(--muted-bg)}.donut .progress{stroke:var(--color);stroke-linecap:round}.donut-content{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center}.donut-content strong,.risk-ring strong{font-size:1.85rem;line-height:1}.donut-content small,.risk-ring small{color:var(--muted);margin-top:.35rem}
.history-charts{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem}.history-metric{border:1px solid var(--border);border-radius:12px;padding:1rem;overflow:hidden}.history-metric h3{font-size:.8rem;text-transform:uppercase;color:var(--muted)}.history-metric svg{display:block;width:100%;height:auto}.history-axis{stroke:#CBD5E1}.history-gridline{stroke:#E5E7EB}.history-target{stroke:var(--medium);stroke-width:2;stroke-dasharray:6 5}.history-line{fill:none;stroke-width:3;stroke-linecap:round;stroke-linejoin:round}.history-point{stroke:#fff;stroke-width:2}.history-label{fill:var(--muted);font-size:10px}.history-value{fill:var(--text);font-size:10px;font-weight:700}.history-delta{margin-top:1rem;padding:.8rem 1rem;background:var(--soft);border-radius:8px;color:var(--muted);font-size:.82rem}
.manager-grid{display:grid;grid-template-columns:.8fr 1.2fr;gap:1.5rem}.risk-layout{display:grid;grid-template-columns:190px 1fr;gap:1rem;align-items:center}.risk-ring{width:170px;height:170px;border-radius:50%;display:grid;place-items:center;position:relative}.risk-ring:before{content:"";position:absolute;inset:17px;border-radius:50%;background:#fff}.risk-ring div{position:relative;display:flex;flex-direction:column;align-items:center}.severity-list{display:grid;gap:.65rem}.severity-line{display:grid;grid-template-columns:12px 1fr auto;align-items:center;gap:.7rem;padding:.65rem 0;border-bottom:1px solid var(--border)}.severity-line i{width:12px;height:12px;border-radius:3px}.severity-line strong{font-size:1.15rem}.decisions{display:grid;gap:.85rem}.decision{border-left:5px solid var(--neutral);padding:1rem 1.1rem;background:var(--soft);border-radius:8px}.decision.critical{border-color:var(--critical)}.decision.warning{border-color:var(--medium)}.decision.success{border-color:var(--success)}.decision.info{border-color:var(--info)}.decision span{font-size:.72rem;text-transform:uppercase;color:var(--muted);font-weight:800}.decision p{margin-top:.25rem;font-weight:600}
.focus-grid{display:grid;grid-template-columns:1fr 1fr;gap:1.5rem}.bar-row{display:grid;grid-template-columns:145px 1fr 145px;align-items:center;gap:.7rem;margin:.85rem 0}.bar-label{overflow:hidden}.bar-label strong,.bar-label small{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.bar-label small{font-size:.7rem;color:var(--muted)}.bar-track{height:13px;background:var(--muted-bg);border-radius:99px;overflow:hidden;display:flex}.bar-track span{height:100%;min-width:1px}.bar-high{background:var(--critical)}.bar-medium{background:var(--medium)}.bar-low{background:var(--low)}.bar-value{text-align:right;font-size:.72rem;font-weight:700;white-space:nowrap}
.table-wrap{overflow:auto;max-height:420px}table{width:100%;border-collapse:collapse;min-width:650px}th{position:sticky;top:0;background:var(--muted-bg);padding:.7rem;text-align:left;font-size:.66rem;text-transform:uppercase;color:var(--muted)}td{padding:.7rem;border-bottom:1px solid var(--border)}.numeric{text-align:right}.rank{color:#9CA3AF}.fail{color:var(--critical);font-weight:800}.badge{display:inline-block;border-radius:99px;padding:.25rem .5rem;font-size:.66rem;font-weight:800}.badge.high{background:#FEE2E2;color:#991B1B}.badge.medium{background:#FEF3C7;color:#92400E}.badge.low{background:#FEF9C3;color:#854D0E}.badge.unknown{background:#E5E7EB;color:#4B5563}.method{padding:1rem 1.25rem;border-left:4px solid var(--claro-red);background:var(--soft);border-radius:10px;color:var(--muted);font-size:.77rem}footer{text-align:center;color:var(--muted);font-size:.74rem;padding:1rem}
@media(max-width:1150px){.kpis{grid-template-columns:repeat(3,1fr)}.hero,.manager-grid,.focus-grid{grid-template-columns:1fr}.history-charts{grid-template-columns:1fr}.hero-donut{min-height:230px}}
@media(max-width:700px){.header-inner{grid-template-columns:70px 1fr;padding:1rem}.logo{width:62px;height:62px}.report-date{display:none}main{padding:1rem}.context{flex-direction:column}.kpis{grid-template-columns:1fr 1fr}.risk-layout{grid-template-columns:1fr}.risk-ring{margin:auto}.bar-row{grid-template-columns:95px 1fr}.bar-value{grid-column:2}}
@media print{main{max-width:none;padding:1rem}.card,.kpi{box-shadow:none}.hero,.manager-grid,.focus-grid{break-inside:avoid}.table-wrap{max-height:none}.header{print-color-adjust:exact;-webkit-print-color-adjust:exact}}
</style>
</head>
<body>
<header class="header"><div class="header-inner">
  <div><img class="logo" src="__LOGO_DATA__" alt="__CLIENT__"></div>
  <div class="header-title"><h1>__TITLE__</h1><p>Unix · Visão gerencial da equipe __TEAM__</p></div>
  <div class="report-date"><span>Data do relatório</span><strong>__REPORT_DATE__</strong></div>
</div></header>
<main>
  <div class="context"><span><strong>Equipe:</strong> __TEAM__ · <strong>Amostra atual:</strong> __SOURCE__</span><span>__SAMPLE_COUNT__ coletas · __HISTORY_PERIOD__ · Meta ≥ __TARGET__%</span></div>
  <section class="dashboard">
    <section class="hero">
      <article class="hero-message">
        <span class="eyebrow">Síntese gerencial</span>
        <h2>__HEADLINE__</h2>
        <p>__MANAGER_NOTE__</p>
        <span class="trend">__TREND__</span>
      </article>
      <article class="card"><div class="card-header"><span class="card-title">Aderência atual</span></div><div class="hero-donut">__COMPLIANCE_DONUT__</div></article>
    </section>

    <section class="kpis">
      <article class="kpi"><span>Servidores auditados</span><strong>__SERVERS__</strong><small>na coleta mais recente</small></article>
      <article class="kpi"><span>Hosts na meta</span><strong>__AT_TARGET__ / __SERVERS__</strong><small>meta individual de __TARGET__%</small></article>
      <article class="kpi"><span>Total de FAILs</span><strong>__FAILED__</strong><small>__AVG_FAILS__ por servidor</small></article>
      <article class="kpi"><span>Criticidade Alta</span><strong>__HIGH__</strong><small>em __HIGH_HOSTS__ hosts</small></article>
      <article class="kpi"><span>Abaixo da meta</span><strong>__BELOW__</strong><small>servidores que exigem atenção</small></article>
      <article class="kpi"><span>Esforço mínimo</span><strong>__GAP__</strong><small>correções para todos atingirem 80%</small></article>
    </section>

    <article class="card"><div class="card-header"><div><span class="card-title">1 · Evolução da equipe</span><div class="card-subtitle">Resultado, exposição e volume auditado ao longo das coletas</div></div><span class="card-subtitle">__SAMPLE_COUNT__ amostras</span></div><div class="card-body">__HISTORY_CHART__</div></article>

    <section class="manager-grid">
      <article class="card"><div class="card-header"><span class="card-title">2 · Perfil de risco atual</span></div><div class="card-body risk-layout">
        __RISK_DONUT__
        <div class="severity-list">
          <div class="severity-line"><i style="background:var(--critical)"></i><span>Alta</span><strong>__HIGH__</strong></div>
          <div class="severity-line"><i style="background:var(--medium)"></i><span>Média</span><strong>__MEDIUM__</strong></div>
          <div class="severity-line"><i style="background:var(--low)"></i><span>Baixa</span><strong>__LOW__</strong></div>
          <div class="severity-line"><i style="background:var(--neutral)"></i><span>Não informada</span><strong>__UNINFORMED__</strong></div>
        </div>
      </div></article>
      <article class="card"><div class="card-header"><div><span class="card-title">3 · Decisões recomendadas</span><div class="card-subtitle">Pontos que exigem patrocínio, capacidade ou acompanhamento gerencial</div></div></div><div class="card-body decisions">__MANAGEMENT_ACTIONS__</div></article>
    </section>

    <section class="focus-grid">
      <article class="card"><div class="card-header"><div><span class="card-title">4 · Hosts que concentram exposição</span><div class="card-subtitle">Visão resumida para dimensionar prioridade e capacidade</div></div></div><div class="card-body">__HOST_BARS__</div></article>
      <article class="card"><div class="card-header"><div><span class="card-title">5 · Controles de maior alcance</span><div class="card-subtitle">Correções com potencial de reduzir recorrência na equipe</div></div></div><div class="table-wrap"><table><thead><tr><th>#</th><th>ID</th><th>Controle</th><th>Risco</th><th class="numeric">FAILs</th><th class="numeric">Taxa</th></tr></thead><tbody>__PRIORITY_CONTROLS__</tbody></table></div></article>
    </section>

    <aside class="method"><strong>Escopo:</strong> somente arquivos iniciados por <code>__TEAM_PREFIX__</code>. A coleta mais recente representa a situação atual e as anteriores compõem o histórico. Aderência = PASSED / (PASSED + FAILED). Meta gerencial: __TARGET__%. IDs excluídos: <code>__EXCLUDED_IDS__</code>.</aside>
  </section>
  <footer>Visão Gerencial de Hardening · HTML autocontido · __CLIENT__ · __GENERATED_AT__</footer>
</main>
</body></html>"""

def render(model: dict, source: Path, output: Path, args: argparse.Namespace, excluded_ids: set[str], history: list[dict]) -> None:
    logo_path = SCRIPT_DIR / "Claro.png"
    if not logo_path.is_file():
        raise ValueError(f"Logo não encontrado: {logo_path}")
    logo_data = "data:image/png;base64," + base64.b64encode(logo_path.read_bytes()).decode("ascii")
    high = model["severity_failures"]["Alta"]
    medium = model["severity_failures"]["Média"]
    low = model["severity_failures"]["Baixa"]
    uninformed = model["severity_failures"]["Não informada"]
    below = model["server_count"] - model["at_target"]
    average_fails = model["failed"] / model["server_count"] if model["server_count"] else 0.0
    previous = history[-2] if len(history) > 1 else None
    if below == 0 and high == 0:
        headline = "Todos os hosts na meta, com risco crítico controlado."
        manager_note = "O foco gerencial passa a ser sustentar o resultado e remover as recorrências restantes."
    elif below == 0:
        headline = "Todos os hosts na meta, mas ainda há exposição Alta."
        manager_note = "A aderência está adequada, porém os itens Altos precisam de patrocínio imediato."
    elif model["average"] >= model["target"]:
        headline = "Aderência consolidada na meta, com exceções a tratar."
        manager_note = (
            f"A média da equipe superou 80%, mas {quantity(below, 'host permanece', 'hosts permanecem')} "
            "abaixo da meta individual."
        )
    else:
        headline = "Equipe abaixo da meta e requer priorização de capacidade."
        manager_note = "O próximo ciclo deve concentrar esforço nos hosts e controles de maior alcance."
    if previous:
        adherence_delta = model["average"] - previous["adherence"]
        fail_delta = model["failed"] - previous["failed"]
        server_delta = model["server_count"] - previous["servers"]
        adherence_label = f"{adherence_delta:+.1f}".replace(".", ",")
        trend = (
            f"Desde a última coleta: aderência {adherence_label} p.p. · "
            f"FAILs {fail_delta:+d} · servidores {server_delta:+d}"
        )
    else:
        trend = "Primeira coleta disponível para esta equipe."
    period = (
        history[0]["date"].strftime("%d/%m/%Y") if len(history) == 1
        else f'{history[0]["date"].strftime("%d/%m/%Y")} a {history[-1]["date"].strftime("%d/%m/%Y")}'
    )
    replacements = {
        "__PAGE_TITLE__": esc(f"{args.titulo} — {args.equipe}"),
        "__LOGO_DATA__": logo_data, "__CLIENT__": esc(args.cliente),
        "__TITLE__": esc(args.titulo), "__TEAM__": esc(args.equipe),
        "__SOURCE__": esc(source.name),
        "__REPORT_DATE__": datetime.now().astimezone().strftime("%d/%m/%Y"),
        "__GENERATED_AT__": datetime.now().astimezone().strftime("%d/%m/%Y %H:%M %Z"),
        "__TARGET__": f"{model['target']:g}".replace(".", ","),
        "__HEADLINE__": esc(headline), "__MANAGER_NOTE__": esc(manager_note), "__TREND__": esc(trend),
        "__COMPLIANCE_DONUT__": donut(model["average"], "var(--claro-red)", pct(model["average"]), "aderência"),
        "__SERVERS__": integer(model["server_count"]), "__AT_TARGET__": integer(model["at_target"]),
        "__FAILED__": integer(model["failed"]), "__AVG_FAILS__": f"{average_fails:.1f}".replace(".", ","),
        "__HIGH__": integer(high), "__MEDIUM__": integer(medium), "__LOW__": integer(low),
        "__UNINFORMED__": integer(uninformed), "__HIGH_HOSTS__": integer(model["high_affected_hosts"]),
        "__BELOW__": integer(below), "__GAP__": integer(model["gap_to_all"]),
        "__HISTORY_CHART__": history_chart(history, model["target"]),
        "__RISK_DONUT__": risk_donut(model), "__MANAGEMENT_ACTIONS__": management_actions(model),
        "__HOST_BARS__": host_bars(model["servers"][:8]),
        "__PRIORITY_CONTROLS__": priority_control_rows(model["controls"][:8]),
        "__SAMPLE_COUNT__": integer(len(history)), "__HISTORY_PERIOD__": esc(period),
        "__TEAM_PREFIX__": esc(args.equipe),
        "__EXCLUDED_IDS__": esc(", ".join(sorted(excluded_ids)) or "nenhum"),
    }
    document = HTML
    for placeholder, value in replacements.items():
        document = document.replace(placeholder, value)
    output.write_text(document, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard gerencial de uma equipe de infraestrutura.")
    parser.add_argument("entrada", nargs="?", type=Path, help="Diretório ou arquivo-semente que define onde procurar")
    parser.add_argument("-o", "--saida", type=Path, default=Path("dashboard_hardening_gerencial_equipe.html"))
    parser.add_argument("--equipe", required=True, help="Prefixo da família de arquivos; ex.: exemplo-equipe-b")
    parser.add_argument("--meta", type=float, default=80.0, help="Meta percentual por servidor (padrão: 80)")
    parser.add_argument("--excluir-ids", default="999", help="IDs separados por vírgula (padrão: 999)")
    parser.add_argument("--cliente", default="Claro", help="Nome do cliente")
    parser.add_argument("--titulo", default="Visão Gerencial de Hardening", help="Título do relatório")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if not 0 < args.meta <= 100:
            raise ValueError("A meta deve estar entre 0 e 100.")
        excluded = {CORE.normalize_id(item) for item in args.excluir_ids.split(",") if CORE.normalize_id(item)}
        samples = discover_team_files(args.entrada, args.equipe)
        history = build_history(samples, excluded, args.meta)
        source = samples[-1][1]
        model = CORE.build_model(CORE.load_records(source), excluded, args.meta)
        if not model["servers"]:
            raise ValueError("Nenhum host válido permaneceu após os filtros.")
        output = args.saida.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        render(model, source, output, args, excluded, history)
        print(f"Dashboard da equipe gerado: {output}")
        print(f"Família: {args.equipe}* | {len(samples)} amostras | atual: {source.name}")
        print(f"Equipe: {args.equipe} | {model['server_count']} hosts | {model['failed']} FAILs | aderência {model['average']:.1f}% | {model['at_target']} na meta")
        return 0
    except (OSError, UnicodeError, ValueError, RuntimeError, csv.Error, zipfile.BadZipFile, ET.ParseError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
