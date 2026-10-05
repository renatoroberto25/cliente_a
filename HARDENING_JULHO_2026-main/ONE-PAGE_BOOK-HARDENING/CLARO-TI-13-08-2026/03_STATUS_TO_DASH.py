#!/usr/bin/env python3
"""Dashboard executivo de governança e cobertura de hardening."""

from __future__ import annotations

import argparse
import html
import json
import re
from datetime import datetime
from pathlib import Path

from openpyxl import load_workbook


RESPONSAVEIS = {
    "BCC": "NELSON AVILA",
    "CLARO-TI": "ROGERS MAISONNETTE",
    "STAR-ONE": "RUI FIGUEIROA",
    "ENG-VIDEO": "DENILSON ROMANIUC",
}


def numero(valor: object) -> int:
    try:
        return int(float(str(valor or 0).replace(",", ".")))
    except ValueError:
        return 0


def br(valor: int) -> str:
    return f"{valor:,}".replace(",", ".")


def percentual(parte: int, total: int) -> str:
    return (f"{parte / total * 100:.1f}".replace(".", ",") + "%") if total else "0%"


def data_do_arquivo(caminho: Path) -> tuple[datetime, str]:
    resultado = re.search(
        r"(?P<mes>\d{2})_(?P<dia>\d{2})_(?P<ano>\d{4})"
        r"(?:_(?P<hora>\d{2})_(?P<minuto>\d{2})_(?P<segundo>\d{2}))?",
        caminho.stem,
    )
    if resultado:
        partes = resultado.groupdict(default="00")
        data = datetime(
            int(partes["ano"]), int(partes["mes"]), int(partes["dia"]),
            int(partes["hora"]), int(partes["minuto"]), int(partes["segundo"]),
        )
    else:
        data = datetime.fromtimestamp(caminho.stat().st_mtime)
    return data, data.strftime("%d/%m/%Y")


def ler(caminho: Path) -> list[dict[str, object]]:
    workbook = load_workbook(caminho, read_only=True, data_only=True)
    registros = []
    for worksheet in workbook.worksheets:
        linhas = worksheet.iter_rows(values_only=True)
        cabecalho = [str(valor or "").strip() for valor in next(linhas, ())]
        for valores in linhas:
            if not any(valor is not None for valor in valores):
                continue
            registro = {
                campo: valores[indice] if indice < len(valores) else None
                for indice, campo in enumerate(cabecalho) if campo
            }
            registro["equipe"] = worksheet.title
            registros.append(registro)
    return registros


def metricas(caminho: Path) -> dict[str, object]:
    registros = ler(caminho)
    equipes = []
    for equipe in sorted({str(r["equipe"]) for r in registros}):
        membros = [r for r in registros if r["equipe"] == equipe]
        ativos = sum(numero(r.get("ativos")) for r in membros)
        agentes = sum(numero(r.get("com_agent")) for r in membros)
        equipes.append({
            "equipe": equipe,
            "responsavel": RESPONSAVEIS.get(equipe, "NÃO DEFINIDO"),
            "ativos": ativos,
            "agentes": agentes,
            "cegos": max(ativos - agentes, 0),
        })
    equipes.sort(key=lambda item: (-int(item["cegos"]), str(item["equipe"])))
    catalogo = {str(r.get("chave")) for r in registros if r.get("chave")}
    criados = {
        str(r.get("chave")) for r in registros
        if str(r.get("status") or "").strip().casefold() == "criado"
    }
    return {
        "perfis": len(catalogo), "criados": len(criados), "equipes": equipes,
        "ativos": sum(int(e["ativos"]) for e in equipes),
        "agentes": sum(int(e["agentes"]) for e in equipes),
    }


def historico(pasta: Path, atual: Path) -> list[dict[str, object]]:
    candidatos = set(pasta.glob("status_baselines_tenable_*.xlsx"))
    candidatos.add(atual.resolve())
    pontos = []
    for caminho in candidatos:
        if not caminho.is_file() or caminho.name.startswith(".~lock"):
            continue
        data, rotulo = data_do_arquivo(caminho)
        dados = metricas(caminho)
        pontos.append({
            "data": data.isoformat(), "rotulo": rotulo,
            "ativos": dados["ativos"], "agentes": dados["agentes"],
            "cobertura": round(int(dados["agentes"]) / int(dados["ativos"]) * 100, 2)
            if dados["ativos"] else 0,
        })
    pontos.sort(key=lambda ponto: str(ponto["data"]))
    return pontos


def render(caminho: Path) -> str:
    dados = metricas(caminho)
    ativos, agentes = int(dados["ativos"]), int(dados["agentes"])
    cegos = max(ativos - agentes, 0)
    criados, perfis = int(dados["criados"]), int(dados["perfis"])
    prontidao = percentual(criados, perfis)
    cobertura = percentual(agentes, ativos)
    cegueira = percentual(cegos, ativos)
    pontos = historico(caminho.resolve().parent, caminho)
    payload = json.dumps(pontos, ensure_ascii=False).replace("</", "<\\/")
    _, posicao = data_do_arquivo(caminho)

    linhas = "".join(
        f'''<tr><td><strong>{html.escape(str(e["equipe"]))}</strong></td>
        <td>{html.escape(str(e["responsavel"]))}</td>
        <td class="num">{br(int(e["ativos"]))}</td>
        <td class="num ok">{br(int(e["agentes"]))}</td>
        <td class="num danger"><strong>{br(int(e["cegos"]))}</strong></td>
        <td class="telemetry"><div><span style="width:{int(e["agentes"])/int(e["ativos"])*100 if e["ativos"] else 0:.2f}%"></span></div><small>{percentual(int(e["agentes"]), int(e["ativos"]))}</small></td></tr>'''
        for e in dados["equipes"]
    )

    return f'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Governança & Cobertura de Hardening</title>
<style>
:root{{--bg:#f3f5f7;--card:#fff;--text:#17212b;--muted:#687582;--line:#d9e0e6;--blue:#185f91;--green:#27753c;--red:#b42318;--amber:#a15c00}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif}}
main{{width:min(1380px,95vw);margin:28px auto 50px}}h1{{margin:0;font-size:27px}}h2{{margin:0 0 14px;font-size:18px}}.subtitle{{margin:5px 0;color:var(--muted)}}
.callout{{margin:18px 0;padding:14px 17px;border-left:4px solid var(--blue);background:#e9f2f8;color:#274b65}}
.cards{{display:grid;grid-template-columns:repeat(4,1fr);gap:11px;margin:18px 0}}.card,.panel{{background:var(--card);border:1px solid var(--line);border-radius:8px}}.card{{padding:16px}}.card span{{display:block;color:var(--muted);font-size:12px}}.card strong{{display:block;margin-top:4px;font-size:25px}}.card small{{color:var(--muted)}}.card.danger{{border-color:#e3a6a1;background:#fff8f7}}.card.danger strong{{color:var(--red)}}
.panel{{padding:18px;margin-bottom:15px}}.funnel{{display:grid;grid-template-columns:repeat(2,1fr);gap:0;align-items:stretch}}.step{{position:relative;padding:16px;border:1px solid var(--line);background:#f8fafb}}.step:not(:last-child)::after{{content:"→";position:absolute;right:-10px;top:37%;z-index:2;color:var(--blue);font-size:20px}}.step strong{{display:block;font-size:22px}}.step span{{display:block;color:var(--muted);font-size:12px}}.step.red strong{{color:var(--red)}}
.table-wrap{{overflow:auto}}table{{width:100%;border-collapse:collapse}}th,td{{padding:10px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap}}th{{background:#edf1f4;color:#43515d;font-size:11px;text-transform:uppercase}}.num{{text-align:right;font-variant-numeric:tabular-nums}}.ok{{color:var(--green)}}.danger{{color:var(--red)}}
.telemetry{{min-width:145px}}.telemetry div{{height:7px;background:#e1e6ea;border-radius:6px;overflow:hidden}}.telemetry div span{{display:block;height:100%;background:var(--red)}}.telemetry small{{display:block;text-align:right;color:var(--muted)}}
.chart{{height:250px;position:relative;border-left:1px solid var(--line);border-bottom:1px solid var(--line);margin:25px 10px 35px 42px}}.chart svg{{width:100%;height:100%;overflow:visible}}.chart-label{{font-size:11px;fill:var(--muted)}}.legend{{display:flex;gap:20px;color:var(--muted);font-size:12px}}.dot{{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:5px}}footer{{color:var(--muted);text-align:right;font-size:12px}}
@media(max-width:900px){{.cards,.funnel{{grid-template-columns:repeat(2,1fr)}}.step::after{{display:none}}}}@media(max-width:560px){{.cards,.funnel{{grid-template-columns:1fr}}}}
</style></head><body><main>
<header><h1>Governança & Cobertura de Hardening</h1><p class="subtitle">Visibilidade executiva do programa · posição de {posicao}</p></header>
<div class="callout"><strong>Visão consolidada.</strong> Os perfis elegíveis possuem baseline disponível; a cobertura de auditoria considera os ativos com coleta ativa.</div>
<section class="cards">
 <div class="card"><span>Perfis com baseline</span><strong>{prontidao}</strong><small>{criados} de {perfis} perfis elegíveis</small></div>
 <div class="card"><span>Ativos no escopo</span><strong>{br(ativos)}</strong><small>Sistemas operacionais elegíveis</small></div>
 <div class="card"><span>Ativos auditáveis</span><strong>{br(agentes)}</strong><small>{cobertura} com agent</small></div>
 <div class="card danger"><span>Ativos pendentes de auditoria</span><strong>{br(cegos)}</strong><small>{cegueira} sem coleta ativa</small></div>
</section>
<section class="panel"><h2>Funil de prontidão</h2><div class="funnel">
 <div class="step"><span>1 · Baselines disponíveis</span><strong>{br(ativos)} · {prontidao}</strong><span>Ativos contemplados por perfis com baseline</span></div>
 <div class="step red"><span>2 · Coleta ativa</span><strong>{br(agentes)} · {cobertura}</strong><span>Ativos com agent e auditáveis</span></div>
</div></section>
<section class="panel"><h2>Status por equipe</h2><div class="table-wrap"><table>
<thead><tr><th>Equipe</th><th>Responsável</th><th>Ativos no escopo</th><th>Com agent</th><th>Sem agent</th><th>Prontidão de telemetria</th></tr></thead><tbody>{linhas}</tbody></table></div></section>
<section class="panel"><h2>Evolução dos ativos auditáveis</h2><div class="legend"><span><i class="dot" style="background:#185f91"></i>Ativos no escopo</span><span><i class="dot" style="background:#27753c"></i>Ativos auditáveis</span></div><div id="chart" class="chart"></div><p class="subtitle">Cada arquivo <code>status_baselines_tenable_DATA.xlsx</code> na pasta adiciona um ponto ao histórico.</p></section>
<footer>Fonte: {html.escape(caminho.name)}</footer>
<script>const history={payload};
const chart=document.querySelector('#chart');
if(!history.length){{chart.textContent='Sem histórico disponível.'}}else{{
 const w=1000,h=230,pad=20,max=Math.max(...history.map(x=>x.ativos),1);
 const x=i=>history.length===1?w/2:pad+i*(w-2*pad)/(history.length-1);const y=v=>h-pad-v*(h-2*pad)/max;
 const line=field=>history.map((d,i)=>`${{i?'L':'M'}}${{x(i)}},${{y(d[field])}}`).join(' ');
 const dots=(field,color)=>history.map((d,i)=>`<circle cx="${{x(i)}}" cy="${{y(d[field])}}" r="5" fill="${{color}}"><title>${{d.rotulo}}: ${{d[field].toLocaleString('pt-BR')}}</title></circle>`).join('');
 const labels=history.map((d,i)=>`<text x="${{x(i)}}" y="${{h+17}}" text-anchor="middle" class="chart-label">${{d.rotulo}}</text>`).join('');
 chart.innerHTML=`<svg viewBox="0 0 ${{w}} ${{h}}" preserveAspectRatio="none"><path d="${{line('ativos')}}" fill="none" stroke="#185f91" stroke-width="3"/>${{dots('ativos','#185f91')}}<path d="${{line('agentes')}}" fill="none" stroke="#27753c" stroke-width="3"/>${{dots('agentes','#27753c')}}${{labels}}</svg>`;
}}</script></main></body></html>'''


def main() -> int:
    parser = argparse.ArgumentParser(description="Dashboard executivo de hardening.")
    candidatos = sorted(Path(__file__).parent.glob("status_baselines_tenable_*.xlsx"))
    parser.add_argument("status", type=Path, nargs="?", default=candidatos[-1] if candidatos else None)
    parser.add_argument("-o", "--saida", type=Path, default=Path(__file__).with_name("dashboard_status_baselines.html"))
    args = parser.parse_args()
    if args.status is None or not args.status.is_file():
        raise SystemExit("Informe uma planilha status_baselines_tenable_DATA.xlsx")
    args.saida.write_text(render(args.status), encoding="utf-8")
    dados = metricas(args.status)
    print(f"Dashboard gerado: {args.saida.resolve()} — {dados['ativos']} no escopo, {dados['agentes']} com agent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
