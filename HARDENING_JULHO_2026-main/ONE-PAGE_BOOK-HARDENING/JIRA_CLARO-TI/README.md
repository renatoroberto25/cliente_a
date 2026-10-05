# Dashboard de Baselines

Fluxo simples para transformar a exportação da CMDB/Jira em dashboards de
gestão e acompanhamento de baselines.

## Fluxo

```text
Jira/CMDB
   ↓ exportação CSV
01_EXPORT_TO_DASH.py
   ↓
dashboard_baselines.html
   ↓ analista informa os status
status_baselines_todos_DATA.csv
   ↓
02_STATUS_TO_DASH.py
   ↓
dashboard_status_baselines.html
```

## 1. Gerar o dashboard de trabalho

```bash
./01_EXPORT_TO_DASH.py export_jira.csv
```

Saída padrão:

```text
dashboard_baselines.html
```

No dashboard, o analista pode:

- Filtrar os perfis por domínio, família, versão e status.
- Informar o status do baseline.
- Registrar baseline, responsável e observação.
- Alterar vários perfis de uma vez.
- Exportar todos os status ou somente os perfis filtrados.
- Importar uma exportação anterior para comparação.

## 2. Gerar o dashboard executivo

Depois de usar **Exportar todos** no primeiro dashboard:

```bash
./02_STATUS_TO_DASH.py status_baselines_todos_DATA.csv
```

Saída padrão:

```text
dashboard_status_baselines.html
```

Esse dashboard apresenta:

- Progresso geral dos baselines.
- Cobertura dos ativos em uso.
- Status por domínio e família.
- Perfis pendentes com maior impacto.

## Requisitos

- Python 3.
- Navegador web para abrir os arquivos HTML.

## Pendência atual

O script `01_EXPORT_TO_DASH.py` ainda importa o módulo local
`consolidar_os_cmdb`, que não está presente nesta pasta. O módulo precisa ser
restaurado ou essa dependência precisa ser removida antes da próxima execução.
