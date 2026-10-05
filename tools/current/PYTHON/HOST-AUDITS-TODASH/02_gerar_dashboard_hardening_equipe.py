#!/usr/bin/env python3
"""Gera o dashboard técnico individual de uma equipe de infraestrutura.

Descobre todos os resultados CSV/XLSX/TSV da família informada em --equipe,
usa a amostra mais recente no diagnóstico e mantém as anteriores no histórico.
Produz um HTML autocontido com narrativa técnica e identidade visual do cliente.
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
    def normalize_control_name(cls, value):
        """Corrige problemas editoriais recorrentes sem alterar o sentido do controle."""
        text = cls.clean(value)
        corrections = (
            (r"\bmaior igual a\b", "maior ou igual a"),
            (r"\bauditd\s*\(", "auditd ("),
            (r"\bVerificacao\b", "Verificação"),
            (r"\bvestigios\b", "vestígios"),
            (r"\bremediacao\b", "remediação"),
        )
        for pattern, replacement in corrections:
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
        if text.endswith(")") and "(" not in text:
            text = text[:-1].rstrip()
        return text

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
                "id": control_id,
                "name": cls.normalize_control_name(cls.best_text(rows, "compliance.audit_name")),
                "severity": severity,
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
    total_failures = model["failed"]
    failures = total_failures or 1
    high = model["severity_failures"]["Alta"] * 100 / failures
    medium = model["severity_failures"]["Média"] * 100 / failures
    low = model["severity_failures"]["Baixa"] * 100 / failures
    medium_end = high + medium
    low_end = medium_end + low
    legend = "".join(
        f"""<li><span class="risk-swatch {css}" aria-hidden="true"></span>
          <span class="risk-name">{esc(label)}</span>
          <strong>{integer(model['severity_failures'][label])}</strong>
          <small>{pct(model['severity_failures'][label] * 100 / failures) if total_failures else '0,0%'}</small></li>"""
        for label, css in (
            ("Alta", "critical"), ("Média", "medium"),
            ("Baixa", "low"), ("Não informada", "neutral"),
        )
    )
    return f"""
    <div class="risk-content">
      <div class="risk-ring" role="img" aria-label="Distribuição de {integer(total_failures)} reprovações por criticidade" style="background:conic-gradient(var(--critical) 0 {high:.3f}%,var(--medium) {high:.3f}% {medium_end:.3f}%,var(--low) {medium_end:.3f}% {low_end:.3f}%,var(--neutral) {low_end:.3f}% 100%)">
        <div><strong>{integer(total_failures)}</strong><small>reprovados</small></div>
      </div>
      <div class="risk-breakdown">
        <div class="risk-legend-head" aria-hidden="true"><span>Criticidade</span><span>Qtd.</span><span>%</span></div>
        <ul class="risk-legend" aria-label="Quantidade e percentual de reprovações por criticidade">{legend}</ul>
      </div>
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
          <td class="rank" data-label="#">{position}</td><td data-label="ID"><strong>{esc(control['id'])}</strong></td>
          <td data-label="Controle" class="wrap-text">{esc(control['name'])}</td><td data-label="Risco">{CORE.severity_badge(control['severity'])}</td>
          <td data-label="Reprovados" class="numeric fail">{integer(control['failed'])}</td>
          <td data-label="Taxa" class="numeric">{pct(control['failure_rate'])}</td>
        </tr>""")
    return "".join(rows) or '<tr><td colspan="6" class="empty">Nenhuma não conformidade encontrada.</td></tr>'


def server_rows(servers: list[dict]) -> str:
    rows: list[str] = []
    for position, server in enumerate(servers, 1):
        state = "ok" if server["at_target"] else "below"
        label = "Na meta" if server["at_target"] else "Abaixo da meta"
        rows.append(f"""
        <tr data-state="{state}">
          <td class="rank" data-label="#">{position}</td>
          <td data-label="Host / IP" class="host-cell"><strong>{esc(server['host'])}</strong><small>{esc(server['ip'])}</small></td>
          <td data-label="Sistema operacional" class="os" title="{esc(server['os'])}">{esc(server['os'])}</td>
          <td data-label="Alta" class="numeric critical-text">{integer(server['high'])}</td>
          <td data-label="Média" class="numeric medium-text">{integer(server['medium'])}</td>
          <td data-label="Baixa" class="numeric">{integer(server['low'])}</td>
          <td data-label="Reprovados" class="numeric fail">{integer(server['failed'])}</td>
          <td data-label="Aderência"><div class="progress-line"><span style="width:{server['adherence']:.3f}%"></span></div><strong>{pct(server['adherence'])}</strong></td>
          <td data-label="Correções necessárias" class="numeric">{integer(server['gap'])}</td>
          <td data-label="Status"><span class="status {state}">{label}</span></td>
        </tr>""")
    return "".join(rows)


def control_rows(controls: list[dict]) -> str:
    rows: list[str] = []
    for control in controls:
        rows.append(f"""
        <tr>
          <td data-label="ID"><strong>{esc(control['id'])}</strong></td><td data-label="Controle" class="wrap-text">{esc(control['name'])}</td>
          <td data-label="Risco">{CORE.severity_badge(control['severity'])}</td>
          <td data-label="Reprovados" class="numeric fail">{integer(control['failed'])}</td>
          <td data-label="Aprovados" class="numeric">{integer(control['passed'])}</td>
          <td data-label="Avaliados" class="numeric">{integer(control['total'])}</td>
          <td data-label="Taxa de reprovação"><div class="progress-line failure"><span style="width:{control['failure_rate']:.3f}%"></span></div><strong>{pct(control['failure_rate'])}</strong></td>
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
        metric_history(history, "adherence", "var(--success)", "Aderência Geral", True, target)
        + metric_history(history, "failed", "var(--critical)", "Total de reprovados")
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
            f'aderência {adherence_label} p.p. · reprovados {fail_delta:+d} · servidores {server_delta:+d}</div>'
        )
    return f'<div class="history-charts">{charts}</div>{delta}'


HTML = r"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>__PAGE_TITLE__</title>
<style>
:root{--claro-red:#D52B1E;--claro-dark:#B51D12;--critical:#D52B1E;--medium:#F59E0B;--low:#FACC15;--success:#27AE60;--info:#2E7BD6;--neutral:#6B7280;--bg:#fff;--bg-soft:#F8F9FA;--bg-muted:#F3F4F6;--text:#111827;--text-soft:#4B5563;--text-muted:#9CA3AF;--border:#E5E7EB;--shadow:0 4px 6px -1px rgba(0,0,0,.1),0 2px 4px -1px rgba(0,0,0,.06);--radius:16px}
*{box-sizing:border-box;margin:0;padding:0}html{scroll-behavior:smooth}body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:var(--bg);color:var(--text);line-height:1.55}button,input,select{font:inherit}
.header{background:#F00000;color:#fff;position:sticky;top:0;z-index:20;border-bottom:1px solid var(--claro-dark)}.header-content{max-width:1600px;min-height:118px;margin:auto;padding:1rem 2rem;display:grid;grid-template-columns:180px 1fr 180px;align-items:center;gap:2rem}.brand-logo{display:block;width:84px;height:84px;object-fit:contain}.header-title{text-align:center}.header h1{font-size:clamp(1.5rem,2.4vw,2.35rem);font-weight:800;line-height:1.2}.header-title p{margin-top:.35rem}.report-date{text-align:right}.report-date span{display:block;font-size:.8rem;font-weight:700}.report-date strong{display:block;margin-top:.25rem}
main{max-width:1600px;margin:auto;padding:2rem}.context-bar{display:flex;justify-content:space-between;gap:1rem;margin-bottom:1.5rem;padding:.75rem 1rem;background:var(--bg-soft);border-radius:10px;color:var(--text-soft);font-size:.875rem}.dashboard{display:flex;flex-direction:column;gap:1.5rem}.card{background:#fff;border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden}.card-header{padding:1rem 1.25rem;border-bottom:1px solid var(--border);background:var(--bg-soft);display:flex;align-items:center;justify-content:space-between;gap:1rem}.card-title{font-size:.875rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:var(--text-soft)}.card-subtitle{font-size:.78rem;color:var(--text-soft)}.card-body{padding:1.25rem}
.opening{display:grid;grid-template-columns:1.2fr .8fr;gap:1.5rem}.diagnosis{padding:1.6rem 1.75rem;background:linear-gradient(135deg,#F00000,var(--claro-dark));color:#fff;border-radius:var(--radius);box-shadow:var(--shadow)}.diagnosis .eyebrow{font-size:.75rem;font-weight:800;text-transform:uppercase;letter-spacing:.08em;opacity:.85}.diagnosis h2{font-size:clamp(1.55rem,2.5vw,2.35rem);line-height:1.15;margin:.55rem 0}.diagnosis p{max-width:850px}.diagnosis-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:1px;margin-top:1.4rem;background:rgba(255,255,255,.25)}.diagnosis-item{background:rgba(125,0,0,.25);padding:1rem}.diagnosis-item strong{display:block;font-size:1.6rem}.diagnosis-item span{font-size:.78rem}
.risk-card-header{align-items:flex-start}.risk-card-header .card-subtitle{margin-top:.18rem}.donut-panel{display:grid;grid-template-columns:minmax(155px,.72fr) minmax(280px,1.28fr);height:100%;padding:0}.metric-panel{display:flex;min-width:0;min-height:218px;padding:1.25rem;flex-direction:column}.metric-panel+.metric-panel{border-left:1px solid var(--border)}.metric-panel-title{display:block;margin-bottom:1rem;color:var(--text-soft);font-size:.72rem;font-weight:800;text-transform:uppercase}.compliance-panel{align-items:center}.compliance-panel .metric-panel-title{align-self:stretch}.compliance-panel .donut{margin:auto}.risk-panel .risk-content{margin:auto 0}.donut{position:relative;width:142px;height:142px}.donut svg{width:100%;height:100%;transform:rotate(-90deg)}.donut circle{fill:none;stroke-width:12}.donut .track{stroke:var(--bg-muted)}.donut .progress{stroke:var(--color);stroke-linecap:round}.donut-content{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center}.donut-content strong,.risk-ring strong{font-size:1.65rem;line-height:1}.donut-content small,.risk-ring small{margin-top:.35rem;color:var(--text-soft);font-size:.7rem;text-transform:uppercase}.risk-content{display:grid;grid-template-columns:112px minmax(150px,1fr);align-items:center;gap:.85rem;width:100%;min-width:0}.risk-ring{width:112px;height:112px;border-radius:50%;display:grid;place-items:center;position:relative}.risk-ring:before{content:"";position:absolute;inset:12px;border-radius:50%;background:#fff}.risk-ring div{position:relative;display:flex;flex-direction:column;align-items:center}.risk-breakdown{min-width:0}.risk-legend-head{display:grid;grid-template-columns:minmax(0,1fr) 34px 43px;gap:.45rem;padding:0 0 .35rem 16px;border-bottom:1px solid var(--border);color:var(--text-muted);font-size:.58rem;font-weight:800;text-transform:uppercase}.risk-legend-head span:nth-child(n+2){text-align:right}.risk-legend{list-style:none;display:grid;min-width:0}.risk-legend li{display:grid;grid-template-columns:10px minmax(0,1fr) 34px 43px;align-items:center;gap:.45rem;min-height:27px;font-size:.7rem}.risk-legend strong{font-variant-numeric:tabular-nums;text-align:right}.risk-legend small{color:var(--text-soft);text-align:right;white-space:nowrap}.risk-swatch{width:9px;height:9px;border-radius:50%;background:var(--neutral)}.risk-swatch.critical{background:var(--critical)}.risk-swatch.medium{background:var(--medium)}.risk-swatch.low{background:var(--low)}.risk-name{overflow-wrap:anywhere}
.severity-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem}.severity-card{padding:1.15rem 1.25rem;border:1px solid var(--border);border-top:5px solid var(--neutral);border-radius:12px;box-shadow:var(--shadow)}.severity-card.critical{border-top-color:var(--critical)}.severity-card.medium{border-top-color:var(--medium)}.severity-card.low{border-top-color:var(--low)}.severity-card span,.severity-card small{display:block;color:var(--text-soft)}.severity-card strong{display:block;font-size:2rem;margin:.2rem 0}
.action-grid{display:grid;grid-template-columns:1fr 1fr;gap:1.5rem}.bar-row{display:grid;grid-template-columns:minmax(130px,160px) minmax(100px,1fr) minmax(125px,150px);align-items:center;gap:.8rem;margin:.9rem 0}.bar-label{min-width:0}.bar-label strong,.bar-label small{display:block;overflow-wrap:anywhere;word-break:break-word}.bar-label small{font-size:.72rem;color:var(--text-soft)}.bar-track{height:14px;background:var(--bg-muted);border-radius:99px;overflow:hidden;display:flex}.bar-track span{height:100%;min-width:1px}.bar-high{background:var(--critical)}.bar-medium{background:var(--medium)}.bar-low{background:var(--low)}.bar-value{text-align:right;font-size:.75rem;font-weight:700;white-space:nowrap}
.effort-grid{display:grid;grid-template-columns:220px 1fr;gap:1.5rem}.target-box{display:flex;align-items:center;justify-content:center}.metric-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem}.metric{padding:1.2rem;border-left:4px solid var(--claro-red);background:var(--bg-soft);border-radius:8px}.metric strong{display:block;font-size:1.7rem}.metric span{display:block;font-size:.78rem;color:var(--text-soft)}
.toolbar{display:flex;align-items:center;justify-content:space-between;gap:1rem;padding:1rem 1.25rem}.filters{display:flex;gap:.75rem;flex-wrap:wrap;min-width:0}.filters input,.filters select{border:1px solid var(--border);border-radius:8px;padding:.65rem .8rem;min-width:min(220px,100%);max-width:100%}.result-count{font-size:.8rem;color:var(--text-soft)}.table-wrap{overflow:auto;max-width:100%;max-height:650px}table{width:100%;border-collapse:collapse;min-width:1050px}th{position:sticky;top:0;z-index:2;background:var(--bg-muted);padding:.75rem;text-align:left;font-size:.68rem;text-transform:uppercase;letter-spacing:.05em;color:var(--text-soft);white-space:nowrap}td{padding:.72rem .75rem;border-bottom:1px solid var(--border);vertical-align:middle}tr:hover td{background:#FFF8F7}.numeric{text-align:right;font-variant-numeric:tabular-nums}.rank{width:44px;color:var(--text-muted)}td small{display:block;color:var(--text-soft);font-size:.72rem}.host-cell,.wrap-text{overflow-wrap:anywhere;word-break:break-word}.os{max-width:260px;white-space:normal;overflow-wrap:anywhere;word-break:break-word}.fail,.critical-text{color:var(--critical);font-weight:800}.medium-text{color:#B66B00;font-weight:800}.progress-line{display:inline-block;width:80px;max-width:100%;height:7px;margin-right:.5rem;background:var(--bg-muted);border-radius:20px;overflow:hidden;vertical-align:middle}.progress-line span{display:block;height:100%;background:var(--success)}.progress-line.failure span{background:var(--critical)}.status,.badge{display:inline-block;border-radius:99px;padding:.28rem .55rem;font-size:.68rem;font-weight:800;white-space:nowrap}.status.ok{background:#DCFCE7;color:#166534}.status.below,.badge.high{background:#FEE2E2;color:#991B1B}.badge.medium{background:#FEF3C7;color:#92400E}.badge.low{background:#FEF9C3;color:#854D0E}.badge.unknown{background:#E5E7EB;color:#4B5563}.empty{text-align:center;padding:2rem;color:var(--text-soft)}
.history-charts{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem}.history-metric{border:1px solid var(--border);border-radius:12px;padding:1rem;overflow:hidden}.history-metric h3{font-size:.82rem;text-transform:uppercase;color:var(--text-soft);letter-spacing:.04em}.history-metric svg{display:block;width:100%;height:auto;margin-top:.5rem}.history-axis{stroke:#CBD5E1;stroke-width:1}.history-gridline{stroke:#E5E7EB;stroke-width:1}.history-target{stroke:var(--medium);stroke-width:2;stroke-dasharray:6 5}.history-line{fill:none;stroke-width:3;stroke-linejoin:round;stroke-linecap:round}.history-point{stroke:#fff;stroke-width:2}.history-label{fill:var(--text-soft);font-size:10px}.history-value{fill:var(--text);font-size:10px;font-weight:700}.history-delta{margin-top:1rem;padding:.8rem 1rem;background:var(--bg-soft);border-radius:8px;color:var(--text-soft);font-size:.82rem}.history-files{font-size:.75rem;color:var(--text-soft);font-weight:600}.method{padding:1rem 1.25rem;background:var(--bg-soft);border-left:4px solid var(--claro-red);border-radius:10px;color:var(--text-soft);font-size:.78rem}.method strong{color:var(--text)}footer{text-align:center;padding:1rem;color:var(--text-soft);font-size:.75rem}
@media(max-width:1100px){.opening,.action-grid{grid-template-columns:1fr}.severity-grid,.metric-grid{grid-template-columns:1fr 1fr}.history-charts{grid-template-columns:1fr}.header{position:static}.donut-panel{min-height:270px}}
@media(max-width:700px){.header-content{grid-template-columns:62px minmax(0,1fr);gap:.75rem;padding:.85rem 1rem}.brand-logo{width:56px;height:56px}.header-title{text-align:left}.header h1{font-size:1.25rem}.header-title p{font-size:.78rem}.report-date{display:none}main{padding:.75rem}.dashboard{gap:1rem}.context-bar,.toolbar{flex-direction:column;align-items:stretch}.card-header,.card-body{padding:1rem}.donut-panel,.severity-grid,.metric-grid,.effort-grid{grid-template-columns:1fr}.donut-panel{height:auto;padding:0}.metric-panel{min-height:0}.metric-panel+.metric-panel{border-top:1px solid var(--border);border-left:0}.risk-content{grid-template-columns:104px minmax(0,1fr)}.risk-ring{width:104px;height:104px}.diagnosis{padding:1.25rem}.diagnosis-grid{grid-template-columns:1fr}.bar-row{grid-template-columns:minmax(0,1fr) auto;gap:.35rem .75rem;padding:.25rem 0}.bar-label{grid-column:1/-1}.bar-track{grid-column:1}.bar-value{grid-column:2}.target-box{padding:1rem}.filters{width:100%}.filters input,.filters select{width:100%;min-width:0}.result-count{text-align:right}.table-wrap{max-height:none;overflow:visible;padding:.75rem}.table-wrap table{min-width:0;display:block}.table-wrap thead{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}.table-wrap tbody,.table-wrap tr{display:block}.table-wrap tr{margin-bottom:.85rem;border:1px solid var(--border);border-radius:10px;overflow:hidden;background:#fff}.table-wrap td{display:grid;grid-template-columns:minmax(92px,36%) minmax(0,1fr);align-items:start;gap:.75rem;width:100%;max-width:none;padding:.58rem .7rem;text-align:left!important;white-space:normal}.table-wrap td::before{content:attr(data-label);font-size:.66rem;font-weight:800;text-transform:uppercase;letter-spacing:.04em;color:var(--text-soft)}.table-wrap td:empty{display:none}.table-wrap td[colspan]{display:block}.table-wrap td[colspan]::before{content:none}.table-wrap .rank{width:auto}.table-wrap .progress-line{width:min(80px,45%)}.table-wrap tr:hover td{background:inherit}}
@media print{.header{position:static}.toolbar{display:none}main{max-width:none;padding:1rem}.card,.severity-card{box-shadow:none}.table-wrap{max-height:none;overflow:visible}th{position:static}.full-table{break-before:page}.opening,.action-grid{break-inside:avoid}}
</style>
</head>
<body>
<header class="header"><div class="header-content">
  <div><img class="brand-logo" src="__LOGO_DATA__" alt="__CLIENT__"></div>
  <div class="header-title"><h1>__TITLE__</h1><p>Unix · Diagnóstico técnico</p></div>
  <div class="report-date"><span>Data relatório</span><strong>__REPORT_DATE__</strong></div>
</div></header>
<main>
  <div class="context-bar"><span><strong>Equipe:</strong> __TEAM__ · <strong>Amostra atual:</strong> __SOURCE__</span><span>__SAMPLE_COUNT__ __COLLECTION_WORD__ · __HISTORY_PERIOD__ · Meta ≥ __TARGET__%</span></div>
  <section class="dashboard">
    <section class="opening">
      <article class="diagnosis">
        <span class="eyebrow">1 · Situação Geral</span>
        <h2>__HEADLINE__</h2>
        <p>O primeiro ciclo de atuação deve reduzir exposição de criticidade Alta e concentrar mudanças nos controles recorrentes.</p>
        <div class="diagnosis-grid">
          <div class="diagnosis-item"><strong>__HIGH__</strong><span>reprovados de criticidade Alta</span></div>
          <div class="diagnosis-item"><strong>__HIGH_HOSTS__</strong><span>hosts expostos a Alta</span></div>
          <div class="diagnosis-item"><strong>__BELOW__</strong><span>hosts abaixo da meta</span></div>
        </div>
      </article>
      <article class="card"><div class="card-header risk-card-header"><div><h2 class="card-title">Resultado da avaliação</h2><div class="card-subtitle">Aderência geral e composição das não conformidades</div></div></div><div class="card-body donut-panel">
        <section class="metric-panel compliance-panel" aria-labelledby="compliance-title"><h3 class="metric-panel-title" id="compliance-title">Aderência geral</h3>__COMPLIANCE_DONUT__</section>
        <section class="metric-panel risk-panel" aria-labelledby="risk-title"><h3 class="metric-panel-title" id="risk-title">Distribuição dos reprovados</h3>__RISK_DONUT__</section>
      </div></article>
    </section>

    <section class="severity-grid" aria-label="Distribuição das não conformidades">__SEVERITY_CARDS__</section>

    <section class="action-grid">
      <article class="card"><div class="card-header"><div><h2 class="card-title">2 · Hosts para começar</h2><div class="card-subtitle">Ordenação: Alta, total de reprovados, Média e aderência</div></div></div><div class="card-body">__HOST_BARS__</div></article>
      <article class="card"><div class="card-header"><div><h2 class="card-title">3 · Mudanças de maior alcance</h2><div class="card-subtitle">Controles recorrentes que reduzem risco em mais hosts</div></div></div><div class="table-wrap" style="max-height:430px"><table><thead><tr><th>#</th><th>ID</th><th>Controle</th><th>Risco</th><th class="numeric">Reprovados</th><th class="numeric">Taxa</th></tr></thead><tbody>__PRIORITY_CONTROLS__</tbody></table></div></article>
    </section>

    <article class="card"><div class="card-header"><div><h2 class="card-title">4 · Esforço para alcançar a meta</h2><div class="card-subtitle">Correções necessárias, calculadas host a host</div></div></div><div class="card-body effort-grid">
      <div class="target-box">__TARGET_DONUT__</div>
      <div class="metric-grid">
        <div class="metric"><strong>__GAP__</strong><span>correções necessárias para a meta</span></div>
        <div class="metric"><strong>__AT_TARGET__ / __SERVERS__</strong><span>hosts atualmente na meta</span></div>
        <div class="metric"><strong>__FAILED__</strong><span>reprovados em __EVALUATED__ itens avaliados</span></div>
        <div class="metric"><strong>__AVG_FAILS__</strong><span>não conformidades por host</span></div>
      </div>
    </div></article>

    <article class="card full-table"><div class="card-header"><div><h2 class="card-title">5 · Lista de Assets</h2><div class="card-subtitle">Inventário de execução: risco, aderência e correções necessárias</div></div></div>
      <div class="toolbar"><div class="filters"><input id="hostSearch" type="search" aria-label="Buscar assets" placeholder="Buscar hostname, IP ou SO"><select id="stateFilter" aria-label="Filtrar assets por status"><option value="all">Todos os hosts</option><option value="below">Abaixo da meta</option><option value="ok">Na meta</option></select></div><span class="result-count" id="resultCount" aria-live="polite"></span></div>
      <div class="table-wrap"><table id="hostTable"><thead><tr><th>#</th><th>Host / IP</th><th>Sistema operacional</th><th class="numeric">Alta</th><th class="numeric">Média</th><th class="numeric">Baixa</th><th class="numeric">Reprovados</th><th>Aderência</th><th class="numeric">Correções necessárias</th><th>Status</th></tr></thead><tbody>__SERVER_ROWS__</tbody></table><div id="emptyHosts" class="empty" hidden>Nenhum host encontrado.</div></div>
    </article>

    <article class="card full-table"><div class="card-header"><div><h2 class="card-title">6 · Backlog completo por controle</h2><div class="card-subtitle">Use a taxa de reprovação para distinguir recorrência de casos isolados</div></div></div><div class="table-wrap"><table><thead><tr><th>ID</th><th>Controle</th><th>Risco</th><th class="numeric">Reprovados</th><th class="numeric">Aprovados</th><th class="numeric">Avaliados</th><th>Taxa de reprovação</th></tr></thead><tbody>__CONTROL_ROWS__</tbody></table></div></article>

    <article class="card"><div class="card-header"><div><h2 class="card-title">7 · Histórico e evolução <code>__TEAM_PREFIX__</code></h2><div class="card-subtitle">Aderência, reprovados e quantidade de servidores em todas as coletas da família</div></div><span class="history-files">__SAMPLE_COUNT__ __SAMPLE_WORD__</span></div><div class="card-body">__HISTORY_CHART__</div></article>

    <aside class="method"><strong>Escopo de cálculo:</strong> somente arquivos iniciados por <code>__TEAM_PREFIX__</code>. A amostra mais recente alimenta o diagnóstico; as demais alimentam o histórico. Chave única <code>asset.host_name + compliance.audit_ID</code>; em duplicidades prevalece a última linha. Denominador de aderência: aprovados + reprovados. IDs excluídos: <code>__EXCLUDED_IDS__</code>. Registros excluídos: __EXCLUDED_ROWS__ · duplicados: __DUPLICATES__ · ignorados: __IGNORED_ROWS__ · desconhecidos: __UNKNOWN__.</aside>
  </section>
  <footer>Indicadores de Hardening · HTML autocontido · __CLIENT__ · __GENERATED_AT__</footer>
</main>
<script>
(()=>{const search=document.getElementById('hostSearch'),filter=document.getElementById('stateFilter'),rows=[...document.querySelectorAll('#hostTable tbody tr')],count=document.getElementById('resultCount'),empty=document.getElementById('emptyHosts');function apply(){const query=search.value.trim().toLocaleLowerCase('pt-BR'),state=filter.value;let visible=0;rows.forEach(row=>{const show=(!query||row.textContent.toLocaleLowerCase('pt-BR').includes(query))&&(state==='all'||row.dataset.state===state);row.hidden=!show;if(show)visible++});count.textContent=`${visible} de ${rows.length} hosts`;empty.hidden=visible!==0}search.addEventListener('input',apply);filter.addEventListener('change',apply);apply()})();
</script>
</body></html>"""


def render(model: dict, source: Path, output: Path, args: argparse.Namespace, excluded_ids: set[str], history: list[dict]) -> None:
    logo_path = SCRIPT_DIR / "Claro.png"
    if not logo_path.is_file():
        raise ValueError(f"Logo não encontrado: {logo_path}")
    logo_data = "data:image/png;base64," + base64.b64encode(logo_path.read_bytes()).decode("ascii")
    high = model["severity_failures"]["Alta"]
    below = model["server_count"] - model["at_target"]
    target_share = model["at_target"] * 100 / model["server_count"] if model["server_count"] else 0.0
    average_fails = model["failed"] / model["server_count"] if model["server_count"] else 0.0
    headline = (
        f"{integer(high)} não conformidades Altas em {integer(model['high_affected_hosts'])} hosts."
        if high else
        f"Sem reprovações de criticidade Alta; o foco passa para recorrência e aderência."
    )
    replacements = {
        "__PAGE_TITLE__": esc(f"{args.titulo} — {args.equipe}"), "__LOGO_DATA__": logo_data,
        "__CLIENT__": esc(args.cliente), "__TITLE__": esc(args.titulo), "__TEAM__": esc(args.equipe),
        "__SOURCE__": esc(source.name), "__REPORT_DATE__": datetime.now().astimezone().strftime("%d/%m/%Y"),
        "__GENERATED_AT__": datetime.now().astimezone().strftime("%d/%m/%Y %H:%M %Z"),
        "__TARGET__": f"{model['target']:g}".replace(".", ","), "__HEADLINE__": esc(headline),
        "__HIGH__": integer(high), "__HIGH_HOSTS__": integer(model["high_affected_hosts"]),
        "__BELOW__": integer(below), "__COMPLIANCE_DONUT__": donut(model["average"], "var(--claro-red)", pct(model["average"]), "aprovados"),
        "__RISK_DONUT__": risk_donut(model), "__SEVERITY_CARDS__": severity_cards(model),
        "__HOST_BARS__": host_bars(model["servers"]), "__PRIORITY_CONTROLS__": priority_control_rows(model["controls"]),
        "__TARGET_DONUT__": donut(target_share, "var(--success)", pct(target_share), "hosts na meta"),
        "__GAP__": integer(model["gap_to_all"]), "__AT_TARGET__": integer(model["at_target"]),
        "__SERVERS__": integer(model["server_count"]), "__FAILED__": integer(model["failed"]),
        "__EVALUATED__": integer(model["evaluated"]), "__AVG_FAILS__": f"{average_fails:.1f}".replace(".", ","),
        "__SERVER_ROWS__": server_rows(model["servers"]), "__CONTROL_ROWS__": control_rows(model["controls"]),
        "__EXCLUDED_IDS__": esc(", ".join(sorted(excluded_ids)) or "nenhum"),
        "__EXCLUDED_ROWS__": integer(model["excluded_rows"]), "__DUPLICATES__": integer(model["duplicates"]),
        "__IGNORED_ROWS__": integer(model["ignored_rows"]), "__UNKNOWN__": integer(model["unknown"]),
        "__TEAM_PREFIX__": esc(args.equipe), "__SAMPLE_COUNT__": integer(len(history)),
        "__COLLECTION_WORD__": "coleta" if len(history) == 1 else "coletas",
        "__SAMPLE_WORD__": "amostra" if len(history) == 1 else "amostras",
        "__HISTORY_PERIOD__": esc(
            history[0]["date"].strftime("%d/%m/%Y") if len(history) == 1
            else f'{history[0]["date"].strftime("%d/%m/%Y")} a {history[-1]["date"].strftime("%d/%m/%Y")}'
        ),
        "__HISTORY_CHART__": history_chart(history, model["target"]),
    }
    document = HTML
    for placeholder, value in replacements.items():
        document = document.replace(placeholder, value)
    output.write_text(document, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera dashboard técnico individual de uma equipe de infraestrutura.")
    parser.add_argument("entrada", nargs="?", type=Path, help="Diretório ou arquivo-semente que define onde procurar")
    parser.add_argument("-o", "--saida", type=Path, default=Path("dashboard_hardening_equipe.html"))
    parser.add_argument("--equipe", required=True, help="Prefixo da família de arquivos; ex.: exemplo-equipe-b")
    parser.add_argument("--meta", type=float, default=80.0, help="Meta percentual por servidor (padrão: 80)")
    parser.add_argument("--excluir-ids", default="999", help="IDs separados por vírgula (padrão: 999)")
    parser.add_argument("--cliente", default="Claro", help="Nome do cliente")
    parser.add_argument("--titulo", default="Baseline DEFAULT RHEL 1.3.5", help="Título do relatório")
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
        sample_word = "amostra" if len(samples) == 1 else "amostras"
        print(f"Família: {args.equipe}* | {len(samples)} {sample_word} | atual: {source.name}")
        print(f"Equipe: {args.equipe} | {model['server_count']} hosts | {model['failed']} reprovados | aderência {model['average']:.1f}% | {model['at_target']} na meta")
        return 0
    except (OSError, UnicodeError, ValueError, RuntimeError, csv.Error, zipfile.BadZipFile, ET.ParseError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
