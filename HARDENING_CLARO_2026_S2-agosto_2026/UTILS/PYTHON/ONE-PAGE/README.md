# One-page de baselines

Scripts para atualizar o status de baselines a partir de inventários do Tenable e gerar painéis HTML autocontidos. Não é necessário servidor web: o HTML pode ser aberto diretamente no navegador.

## Qual script usar

| Script | Funcionalidade | Entrada | Saída |
|---|---|---|---|
| `04_assets_para_status_baselines.py` | Atualiza os dados automáticos de assets sem sobrescrever os campos manuais | Snapshot de assets CSV + XLSX anterior | Novo XLSX de status |
| `03_one_page_interno.py` | Gera a visão executiva do status das baselines | XLSX de status | One-page HTML |
| `03_gerar_dashboard_hardening_host_audits.py` | Consolida inventário, auditorias e histórico técnico de hardening | CSV de host-audits + CSV de assets | Dashboard HTML + relatório de audits fora do padrão |

Para atualizar o one-page, o fluxo recomendado é executar o `04` e depois o `03_one_page_interno`.

## Fluxo do one-page

```text
snapshot de assets.csv + status anterior.xlsx
                         ↓ 04_assets_para_status_baselines.py
                    novo status.xlsx
                         ↓ 03_one_page_interno.py
                     one-page.html
```

### 1. Atualizar o XLSX de status

O `04_assets_para_status_baselines.py` recebe primeiro o snapshot CSV e depois o XLSX anterior. O novo arquivo mantém os campos manuais existentes e atualiza somente os dados obtidos do Tenable.

```bash
./04_assets_para_status_baselines.py \
  assets-08_27_2026_-13_50_02-gmt-3.csv \
  status_baselines_todos_2026-08-20.xlsx \
  -o status_baselines_todos_2026-08-27.xlsx
```

Formato geral:

```bash
./04_assets_para_status_baselines.py SNAPSHOT.csv STATUS_ANTERIOR.xlsx -o NOVO_STATUS.xlsx
```

As fontes têm papéis diferentes:

- XLSX anterior/CMDB-Jira: `ativos`, `em_uso`, `producao`, `sox`, perfis e status;
- snapshot CSV/Tenable: `com_agent`, `escaneados` e `nao_escaneados`.

O snapshot não substitui os números de inventário da CMDB e não cria novos perfis no XLSX. Perfis encontrados no snapshot que não existam no modelo são contabilizados na aba `RESUMO` para auditoria.

O CSV deve conter:

```text
display_operating_system
operating_systems
has_agent
tags
```

O classificador de sistemas operacionais é lido, por padrão, de `01_EXPORT_TO_DASH.py`. Se ele estiver em outro local, informe-o com `--classificador CAMINHO`.

### 2. Gerar o painel HTML

O `03_one_page_interno.py` lê o novo XLSX e gera o painel:

```bash
./03_one_page_interno.py \
  status_baselines_todos_2026-08-27.xlsx \
  -o one_page_manual_27_08.html
```

O XLSX precisa ter as abas `CLARO-TI`, `BCC`, `STAR-ONE` e `ENG-VIDEO`, com estas colunas:

```text
dominio
perfil
ativos
em_uso
producao
status
```

Também são usadas, quando presentes, as colunas `chave`, `familia`, `versao` e `com_agent`.

## Regras de distribuição por equipe

O `04` usa a categoria das tags para distribuir os assets:

| Categoria da tag | Aba do XLSX |
|---|---|
| `TI` | `CLARO-TI` |
| `BCC` | `BCC` |
| `StarOne` | `STAR-ONE` |
| `Engenharia Video` | `ENG-VIDEO` |

Assets sem uma dessas categorias não são atribuídos e aparecem na aba `RESUMO`. Um asset associado a mais de uma dessas equipes é tratado como erro para evitar classificação ambígua.

## Dashboard técnico de hardening

O `03_gerar_dashboard_hardening_host_audits.py` une duas fontes complementares:

- `assets_last_90_*.csv`: inventário atual de assets/agents, sistema operacional e equipe pelas tags;
- `host-audits-*.csv`: resultados `PASSED` e `FAILED`, controles, criticidades e aderência.

O arquivo de assets não determina conformidade, e o host-audits sozinho não representa todo o inventário.

```bash
./03_gerar_dashboard_hardening_host_audits.py \
  host-audits-08_27_2026_-13_57_09-gmt-3.csv \
  --assets assets_last_90_08_27_2026_-15_16_49-gmt-3.csv \
  -o dashboard_hardening_host_audits.html
```

Cabeçalhos mínimos do host-audits:

```text
asset.host_name
asset.tags
compliance.audit_name
compliance_result
```

`compliance.audit_name` deve seguir o padrão:

```text
ID, nome do controle, criticidade
```

Audits fora desse padrão não participam dos indicadores e são enviados ao relatório auxiliar `audits_fora_do_padrao.html`.

### Equipes e cruzamento das fontes

A categoria da tag define a equipe. `ScanType` representa a forma de coleta e não define equipe. A precedência é:

1. `Engenharia Video=*` → Engenharia de Vídeo;
2. `Engenharia Fixa=*` → Engenharia Fixa;
3. `BCC=*` → BCC;
4. `StarOne=*` → Star One;
5. `TI=*`, `LINUX_CLARO_TI=*` ou `LAB_Linux=HITSS` → Claro TI;
6. sem categoria organizacional → Outras equipes.

O roster usa registros do CSV de assets com `agent_name` preenchido e deduplica o hostname. O cruzamento é:

```text
assets.agent_name ↔ host-audits.asset.host_name
```

Espaços, diferenças entre maiúsculas e minúsculas e o sufixo de FQDN são desconsiderados. Nomes diferentes, como `sensor_eng_video_01` e `sensor01`, não são associados automaticamente.

### Indicadores e histórico

- a aderência é calculada por `PASSED / (PASSED + FAILED)`;
- não conformidades Alta, Média e Baixa vêm somente do host-audits;
- `assets afetados` conta hosts com ao menos uma falha na criticidade;
- IDs configurados em `--excluir-ids` e IDs numéricos maiores que `999` não entram nos indicadores;
- o histórico usa os snapshots `host-audits-*.csv` existentes na mesma pasta;
- a data de cada snapshot é extraída de `host-audits-MM_DD_AAAA_-HH_MM_SS-gmt-3.csv`;
- o CSV de assets não alimenta o histórico de conformidade.

O indicador `Não coletados` representa atualmente a diferença entre o inventário e os hosts com correspondência nominal no host-audits. Portanto, pode incluir hosts não auditados, sensores, diferenças de hostname e assets fora do baseline.

## Requisitos e observações

- Python 3.10 ou superior;
- `openpyxl` é necessário somente para `04_assets_para_status_baselines.py`;
- os dois geradores HTML usam apenas a biblioteca padrão do Python;
- `01_EXPORT_TO_DASH.py` é necessário para o `04`, salvo quando outro classificador é informado por `--classificador`;
- `Claro.png`, quando disponível ao lado dos scripts, é incorporado ao HTML;
- o XLSX deve manter as abas e os cabeçalhos esperados;
- o snapshot de assets deve ser CSV UTF-8 com cabeçalho;
- os arquivos HTML gerados são autocontidos e podem ser abertos localmente no navegador.

Instalação da única dependência externa:

```bash
python3 -m pip install openpyxl
```
