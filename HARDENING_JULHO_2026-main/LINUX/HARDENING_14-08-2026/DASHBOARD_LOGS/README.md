# Dashboard dos logs

Gera um HTML autocontido a partir dos logs criados pelo `executor.sh`, sem dependências externas.

Formato esperado para cada controle:

```text
ID,NOME,CRITICIDADE,RESULTADO
1,Bloqueio cramfs,Alta,PASS
```

```bash
python3 DASHBOARD_LOGS/gerar_dashboard_logs.py logs/audit
```

Opções principais:

```bash
-o dashboard.html
--meta 80
--cliente "Cliente"
--historico
```

Sem `--historico`, é usada somente a execução mais recente de cada servidor.

Indicadores:

- aderência geral: `PASS / (PASS + FAIL)`;
- aderência Alta: mesma fórmula somente para controles de criticidade Alta;
- qualidade ponderada: Alta = 3, Média = 2 e Baixa = 1;
- ranking: FAIL Alta, total de FAIL, FAIL Média e aderência.
