# Status dos baselines

Este diretório contém o fluxo para consolidar os ativos Windows e Linux do
Tenable, preencher a planilha de status dos baselines e gerar o dashboard
executivo em HTML.

## Requisitos

- Python 3.10 ou superior;
- `openpyxl` (usado por `01_TAGS_POR_SO.py`).

```bash
python3 -m pip install openpyxl
```

Execute os comandos a partir deste diretório:

```bash
cd BOOK-HARDENING
```

## 1. Consolidar os ativos e preencher a planilha

O script `01_TAGS_POR_SO.py` lê o CSV Last90 exportado pelo Tenable, agrupa os
ativos por equipe e sistema operacional e atualiza a planilha de baselines.

### Entrada do Tenable

O CSV deve conter, no mínimo, as colunas usadas pelo processamento:

```text
display_operating_system
tags
```

O campo `tags` deve conter uma lista JSON. As equipes são identificadas pela
propriedade `category` das tags e convertidas da seguinte forma:

| Categoria no Tenable | Equipe | Aba da planilha |
| --- | --- | --- |
| `BCC` | `BCC` | `BCC` |
| `Engenharia Video` | `ENG Video` | `ENG-VIDEO` |
| `TI` | `CLARO-TI` | `CLARO-TI` |
| `StarOne` | `STAR ONE` | `STAR-ONE` |

### Planilha de baselines

A planilha informada deve conter as quatro abas da tabela acima. Em cada aba,
a primeira linha deve possuir as colunas:

```text
perfil
ativos
em_uso
```

O script relaciona o valor de `display_operating_system` aos perfis suportados
(Amazon Linux, CentOS, Oracle Linux, RHEL, Ubuntu, SUSE, AIX, HP-UX, Solaris,
Windows Server, Windows Desktop, z/OS e VMware ESXi). Somente um perfil que já
exista na respectiva aba recebe a contagem.

Todo ativo encontrado no Last90 é considerado em uso. Por isso, `ativos` e
`em_uso` recebem a mesma quantidade. Os perfis sem ativos recebem zero e os
ativos sem perfil correspondente são apenas contabilizados no resumo exibido
no terminal.

### Uso

```bash
python3 01_TAGS_POR_SO.py \
  last90-win-linux_08_07_2026_-16_13_28-gmt-3.csv \
  --planilha status_baselines_todos_2026-08-10_preenchido.xlsx
```

Opções:

```text
-o, --saida PATH      CSV consolidado (padrão: equipes_por_so.csv)
-p, --planilha PATH   XLSX atualizado pelo script
                      (padrão: status_baselines_todos_2026-08-07_preenchido.xlsx)
```

O CSV consolidado usa `;` como delimitador e contém:

```text
equipe;sistema_operacional;quantidade
```

> **Atenção:** a planilha indicada em `--planilha` é atualizada no próprio
> arquivo. Mantenha uma cópia do original caso seja necessário preservar os
> valores anteriores.

## 2. Gerar o dashboard

O script `04_STATUS_TO_DASH.py` gera um dashboard HTML a partir de uma planilha
XLSX ou de um arquivo CSV.

### Colunas obrigatórias

Cada aba ou CSV processado deve conter:

```text
dominio
familia
perfil
ativos
em_uso
producao
status
```

As colunas `responsavel`, `com_agent`, `escaneados`, `nao_escaneados`, `chave`,
`sox` e `exportado_em` também são aproveitadas quando presentes para compor as
visões complementares do dashboard.

No XLSX, todas as abas são processadas por padrão, e o nome da aba representa a
equipe. Use `--planilha` para processar apenas uma aba. No CSV, o delimitador
`,` ou `;` e as codificações UTF-8, UTF-16 ou Latin-1 são detectados
automaticamente.

### Uso

```bash
python3 04_STATUS_TO_DASH.py \
  status_baselines_todos_2026-08-10_preenchido.xlsx
```

Opções:

```text
-o, --saida PATH       HTML de saída
                       (padrão: dashboard_status_baselines.html)
-s, --planilha NOME    processa somente a aba indicada do XLSX
```

Exemplo selecionando uma aba e outro arquivo de saída:

```bash
python3 04_STATUS_TO_DASH.py status_baselines_todos_2026-08-10_preenchido.xlsx \
  --planilha CLARO-TI \
  --saida dashboard_claro_ti.html
```

O dashboard considera somente os domínios `Linux` e `Windows`, consolida perfis
repetidos entre as equipes e apresenta:

- quantidade e percentual de baselines criados;
- cobertura dos ativos em uso;
- distribuição dos perfis por status;
- progresso separado de Linux e Windows;
- inventário, agents e escaneamento por equipe;
- maior impacto pendente por equipe e responsável;
- perfis EOL marcados como `Não aplicável`.

Os status vazios são tratados como `Não avaliado`. Também são reconhecidas as
variações sem acento de `Não criado`, `Não avaliado` e `Não aplicável`.

## Atualização periódica

1. Exporte do Tenable um novo CSV Last90 dos ativos Windows e Linux.
2. Faça uma cópia da planilha de status que será atualizada.
3. Execute `01_TAGS_POR_SO.py`, informando o CSV e a planilha com `--planilha`.
4. Confira no terminal quantos ativos foram preenchidos e quantos ficaram sem
   perfil correspondente.
5. Execute `04_STATUS_TO_DASH.py` com a planilha preenchida.
6. Abra `dashboard_status_baselines.html` em um navegador.
