# Dashboard CHECKA_HARDENING

## Regra de leitura

- `999 PASSED`: hardening comprovado pelo log local;
- `999 FAILED`: sem log de hardening;
- `1000` e `1001`: evidências complementares; não anulam um `999 PASSED`.

O dashboard extrai do output do controle 999, quando disponíveis:

- versão registrada;
- tipo do registro (`AUDIT` ou `FULL`);
- origem da execução;
- conteúdo do último registro para rastreabilidade.

Não existe classificação automática de versão atual ou antiga.

## Uso

```bash
python3 gerar_dashboard_checka_hardening.py \
  claro-ti-checka-hardening_08_07_2026_-09_20_30-gmt-3.csv
```

Saída padrão:

```text
dashboard_checka_hardening.html
```

Para escolher outro nome:

```bash
python3 gerar_dashboard_checka_hardening.py resultado.csv -o dashboard.html
```

Requer apenas Python 3.10 ou superior e o arquivo `Claro.png` no mesmo
diretório do script. Não há busca de arquivos em outras pastas.
