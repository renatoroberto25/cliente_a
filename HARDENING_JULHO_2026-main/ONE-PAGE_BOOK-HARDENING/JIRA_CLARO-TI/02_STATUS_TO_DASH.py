#!/usr/bin/env python3
"""Gera um dashboard executivo a partir do CSV de status dos baselines."""

from __future__ import annotations

import argparse
import csv
import html
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo


STATUS_COLORS = {
    "Criado": "#27753c",
    "Em andamento": "#b37a00",
    "Não criado": "#b34b1f",
    "Não avaliado": "#77838f",
    "Não aplicável": "#526579",
    "Revisar CMDB": "#79528e",
}
STATUS_ORDER = (
    "Criado",
    "Em andamento",
    "Não criado",
    "Não avaliado",
    "Revisar CMDB",
    "Não aplicável",
)


def format_number(value: int) -> str:
    return f"{value:,}".replace(",", ".")


def format_percent(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "0%"
    return (
        f"{numerator / denominator * 100:.1f}"
        .replace(".", ",")
        .rstrip("0")
        .rstrip(",")
        + "%"
    )


def as_int(value: str) -> int:
    try:
        return int(value.strip())
    except (AttributeError, ValueError):
        return 0


def read_status_csv(path: Path) -> list[dict[str, str]]:
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
        dialect = csv.Sniffer().sniff(text[:65536], delimiters=";,")
    except csv.Error:
        dialect = csv.excel
        dialect.delimiter = ";"
    rows = [
        {
            str(key or "").strip(): str(value or "").strip()
            for key, value in row.items()
        }
        for row in csv.DictReader(text.splitlines(), dialect=dialect)
    ]
    required = {
        "dominio",
        "familia",
        "perfil",
        "ativos",
        "em_uso",
        "producao",
        "status",
    }
    missing = required - set(rows[0] if rows else ())
    if missing:
        raise ValueError(
            f"Coluna(s) obrigatória(s) ausente(s): {', '.join(sorted(missing))}"
        )
    return rows


def exported_at(rows: list[dict[str, str]]) -> str:
    value = next(
        (row.get("exportado_em", "") for row in rows if row.get("exportado_em")),
        "",
    )
    if not value:
        return "Data não informada"
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        local = parsed.astimezone(ZoneInfo("America/Sao_Paulo"))
        return local.strftime("%d/%m/%Y às %H:%M")
    except ValueError:
        return value


def aggregate(
    rows: list[dict[str, str]], fields: tuple[str, ...]
) -> list[dict[str, object]]:
    groups: dict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        key = tuple(row.get(field, "") or "(vazio)" for field in fields)
        groups[key].append(row)

    result = []
    for key, members in groups.items():
        status_counts = Counter(row.get("status", "Não avaliado") for row in members)
        applicable = [
            row for row in members if row.get("status") != "Não aplicável"
        ]
        active = sum(as_int(row.get("em_uso", "")) for row in applicable)
        covered = sum(
            as_int(row.get("em_uso", ""))
            for row in applicable
            if row.get("status") == "Criado"
        )
        result.append(
            {
                "key": key,
                "profiles": len(members),
                "created": status_counts["Criado"],
                "in_progress": status_counts["Em andamento"],
                "not_created": status_counts["Não criado"],
                "not_evaluated": status_counts["Não avaliado"],
                "review": status_counts["Revisar CMDB"],
                "not_applicable": status_counts["Não aplicável"],
                "active": active,
                "covered": covered,
                "production": sum(
                    as_int(row.get("producao", "")) for row in members
                ),
            }
        )
    return result


def progress_bar(covered: int, total: int, label: str = "") -> str:
    percentage = covered / total * 100 if total else 0
    return (
        '<div class="progress">'
        f'<span style="width:{min(percentage, 100):.2f}%"></span>'
        "</div>"
        f'<small>{html.escape(label or format_percent(covered, total))}</small>'
    )


def render_dashboard(rows: list[dict[str, str]], source: Path) -> str:
    applicable = [row for row in rows if row.get("status") != "Não aplicável"]
    profile_total = len(applicable)
    profile_created = sum(row.get("status") == "Criado" for row in applicable)
    active_total = sum(as_int(row.get("em_uso", "")) for row in applicable)
    active_covered = sum(
        as_int(row.get("em_uso", ""))
        for row in applicable
        if row.get("status") == "Criado"
    )
    production_total = sum(as_int(row.get("producao", "")) for row in rows)
    status_counts = Counter(row.get("status", "Não avaliado") for row in rows)
    domains = aggregate(rows, ("dominio",))
    families = aggregate(rows, ("dominio", "familia"))
    domains.sort(key=lambda item: (-int(item["active"]), str(item["key"])))
    families.sort(
        key=lambda item: (
            str(item["key"][0]).casefold(),
            -int(item["active"]),
            str(item["key"][1]).casefold(),
        )
    )
    pending = sorted(
        (
            row
            for row in rows
            if row.get("status") not in {"Criado", "Não aplicável"}
        ),
        key=lambda row: (
            -as_int(row.get("em_uso", "")),
            row.get("perfil", "").casefold(),
        ),
    )[:12]

    status_segments = []
    for status in STATUS_ORDER:
        count = status_counts[status]
        if not count:
            continue
        width = count / len(rows) * 100
        status_segments.append(
            f'<span title="{html.escape(status)}: {count}" '
            f'style="width:{width:.3f}%;background:{STATUS_COLORS[status]}"></span>'
        )
    legend = "".join(
        f'<span><i style="background:{STATUS_COLORS[status]}"></i>'
        f"{html.escape(status)}: <strong>{status_counts[status]}</strong></span>"
        for status in STATUS_ORDER
        if status_counts[status]
    )

    domain_rows = []
    for item in domains:
        domain = str(item["key"][0])
        domain_rows.append(
            "<tr>"
            f"<td><strong>{html.escape(domain)}</strong></td>"
            f'<td class="number">{item["profiles"]}</td>'
            f'<td class="number ok">{item["created"]}</td>'
            f'<td class="number">{item["in_progress"]}</td>'
            f'<td class="number todo">{item["not_created"]}</td>'
            f'<td class="number muted">{item["not_evaluated"]}</td>'
            f'<td class="number">{format_number(int(item["active"]))}</td>'
            f'<td class="coverage-cell">{progress_bar(int(item["covered"]), int(item["active"]))}</td>'
            "</tr>"
        )

    family_rows = []
    for item in families:
        domain, family = (str(value) for value in item["key"])
        family_rows.append(
            "<tr>"
            f"<td>{html.escape(domain)}</td>"
            f"<td><strong>{html.escape(family)}</strong></td>"
            f'<td class="number">{item["profiles"]}</td>'
            f'<td class="number ok">{item["created"]}</td>'
            f'<td class="number todo">{item["not_created"]}</td>'
            f'<td class="number muted">{item["not_evaluated"]}</td>'
            f'<td class="number">{format_number(int(item["active"]))}</td>'
            f'<td class="coverage-cell">{progress_bar(int(item["covered"]), int(item["active"]))}</td>'
            "</tr>"
        )

    pending_rows = []
    for row in pending:
        status = row.get("status", "Não avaliado")
        color = STATUS_COLORS.get(status, STATUS_COLORS["Não avaliado"])
        pending_rows.append(
            "<tr>"
            f"<td>{html.escape(row.get('dominio', ''))}</td>"
            f"<td><strong>{html.escape(row.get('perfil', ''))}</strong></td>"
            f'<td><span class="badge" style="color:{color};border-color:{color}">'
            f"{html.escape(status)}</span></td>"
            f'<td class="number">{format_number(as_int(row.get("em_uso", "")))}</td>'
            f'<td class="number">{format_number(as_int(row.get("producao", "")))}</td>'
            f"<td>{html.escape(row.get('responsavel', '') or '—')}</td>"
            "</tr>"
        )

    return f"""<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Status de baselines</title>
  <style>
    :root {{
      --bg:#f3f5f7;--card:#fff;--text:#17212b;--muted:#687582;
      --line:#d9e0e6;--accent:#185f91;--ok:#27753c;--todo:#b34b1f;
    }}
    *{{box-sizing:border-box}}
    body{{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif}}
    main{{width:min(1320px,95vw);margin:28px auto 50px}}
    h1{{margin:0;font-size:26px}} h2{{margin:0 0 13px;font-size:18px}}
    .subtitle{{margin:4px 0 0;color:var(--muted)}}
    .cards{{display:grid;grid-template-columns:repeat(5,1fr);gap:11px;margin:22px 0}}
    .card,.panel{{background:var(--card);border:1px solid var(--line);border-radius:8px}}
    .card{{padding:16px}} .card span{{display:block;color:var(--muted);font-size:12px}}
    .card strong{{display:block;margin-top:4px;font-size:23px}}
    .panel{{padding:18px;margin-bottom:15px}}
    .overall{{display:grid;grid-template-columns:180px 1fr;gap:26px;align-items:center}}
    .score{{text-align:center}} .score strong{{display:block;color:var(--accent);font-size:40px;line-height:1}}
    .score span{{display:block;margin-top:7px;color:var(--muted)}}
    .stack{{display:flex;height:14px;overflow:hidden;border-radius:7px;background:#e2e7eb}}
    .stack span{{display:block;height:100%}}
    .legend{{display:flex;flex-wrap:wrap;gap:8px 18px;margin-top:12px;color:var(--muted);font-size:12px}}
    .legend span{{white-space:nowrap}} .legend i{{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:5px}}
    .table-wrap{{overflow:auto}} table{{width:100%;border-collapse:collapse}}
    th,td{{padding:9px 10px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap}}
    th{{color:#43515d;background:#edf1f4;font-size:11px;text-transform:uppercase;letter-spacing:.025em}}
    tr:last-child td{{border-bottom:0}} .number{{text-align:right;font-variant-numeric:tabular-nums}}
    .ok{{color:var(--ok)}} .todo{{color:var(--todo)}} .muted{{color:var(--muted)}}
    .coverage-cell{{min-width:130px}} .progress{{height:7px;overflow:hidden;border-radius:5px;background:#e0e6ea}}
    .progress span{{display:block;height:100%;border-radius:5px;background:var(--ok)}}
    .coverage-cell small{{display:block;margin-top:3px;color:var(--muted);text-align:right}}
    .badge{{display:inline-block;padding:2px 7px;border:1px solid;border-radius:10px;font-size:11px;font-weight:650}}
    details summary{{cursor:pointer;color:var(--accent);font-weight:650}}
    details .table-wrap{{margin-top:14px}}
    footer{{margin-top:17px;color:var(--muted);font-size:12px;text-align:right}}
    @media(max-width:950px){{.cards{{grid-template-columns:repeat(2,1fr)}}.overall{{grid-template-columns:1fr}}}}
    @media(max-width:560px){{.cards{{grid-template-columns:1fr}}}}
  </style>
</head>
<body>
<main>
  <header>
    <h1>Status atual dos baselines</h1>
    <p class="subtitle">Apanhado geral por sistema operacional · posição de {html.escape(exported_at(rows))}</p>
  </header>

  <section class="cards">
    <div class="card"><span>Perfis aplicáveis</span><strong>{profile_total}</strong></div>
    <div class="card"><span>Baselines criados</span><strong>{profile_created}</strong></div>
    <div class="card"><span>Progresso por perfil</span><strong>{format_percent(profile_created, profile_total)}</strong></div>
    <div class="card"><span>Ativos em uso cobertos</span><strong>{format_number(active_covered)}</strong></div>
    <div class="card"><span>Cobertura dos ativos</span><strong>{format_percent(active_covered, active_total)}</strong></div>
  </section>

  <section class="panel overall">
    <div class="score">
      <strong>{format_percent(active_covered, active_total)}</strong>
      <span>{format_number(active_covered)} de {format_number(active_total)} ativos em uso</span>
    </div>
    <div>
      <h2>Distribuição dos {len(rows)} perfis</h2>
      <div class="stack">{"".join(status_segments)}</div>
      <div class="legend">{legend}</div>
    </div>
  </section>

  <section class="panel">
    <h2>Progresso por domínio</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Domínio</th><th>Perfis</th><th>Criados</th><th>Em andamento</th><th>Não criados</th><th>Não avaliados</th><th>Ativos em uso</th><th>Cobertura</th></tr></thead>
      <tbody>{"".join(domain_rows)}</tbody>
    </table></div>
  </section>

  <section class="panel">
    <h2>Maior impacto pendente</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Domínio</th><th>Perfil</th><th>Status</th><th>Em uso</th><th>Produção</th><th>Responsável</th></tr></thead>
      <tbody>{"".join(pending_rows)}</tbody>
    </table></div>
  </section>

  <section class="panel">
    <details>
      <summary>Detalhamento por família</summary>
      <div class="table-wrap"><table>
        <thead><tr><th>Domínio</th><th>Família</th><th>Perfis</th><th>Criados</th><th>Não criados</th><th>Não avaliados</th><th>Ativos em uso</th><th>Cobertura</th></tr></thead>
        <tbody>{"".join(family_rows)}</tbody>
      </table></div>
    </details>
  </section>

  <footer>
    Fonte: {html.escape(source.name)} · {format_number(production_total)} registros associados a produção
  </footer>
</main>
</body>
</html>
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gera um dashboard executivo do status dos baselines."
    )
    parser.add_argument(
        "arquivo",
        type=Path,
        help="CSV exportado pelo dashboard de gestão de baselines",
    )
    parser.add_argument(
        "-o",
        "--saida",
        type=Path,
        default=Path("dashboard_status_baselines.html"),
        help="HTML de saída (padrão: dashboard_status_baselines.html)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.arquivo.is_file():
        raise SystemExit(f"Arquivo não encontrado: {args.arquivo}")
    try:
        rows = read_status_csv(args.arquivo)
    except (ValueError, csv.Error) as error:
        raise SystemExit(f"Erro: {error}") from error
    args.saida.write_text(
        render_dashboard(rows, args.arquivo),
        encoding="utf-8",
    )
    print(
        f"{args.saida}: {len(rows)} perfis, "
        f"{sum(row.get('status') == 'Criado' for row in rows)} criados"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
