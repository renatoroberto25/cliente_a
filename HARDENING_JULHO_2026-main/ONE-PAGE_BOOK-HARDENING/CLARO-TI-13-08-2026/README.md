# Tenable Pure — Status de Baselines

Pipeline para transformar o inventário de assets do Tenable em uma planilha
consolidada de cobertura de hardening, separada por equipe e perfil de sistema
operacional.

## Fluxo operacional

```text
Export de assets do Tenable
        ↓
Planilha status_baselines do dia, informada pelo usuário
        ↓
02_POPULAR_STATUS_BASELINE.py
        ↓
Planilha status com as métricas atualizadas
        ↓
03_STATUS_TO_DASH.py
        ↓
dashboard_status_baselines.html
```

No uso normal, o pipeline é `02 → 03`: o usuário cria ou escolhe a planilha de
status do período, informa essa planilha ao `02` e depois aponta o `03` para o
arquivo preenchido.

O `01_GERAR_STATUS_BASELINE.py` é opcional. Ele existe somente para criar um
molde novo quando necessário.

## Requisitos

- Python 3.10 ou superior;
- pacote `openpyxl`;
- export CSV de assets do Tenable.

Verificação rápida:

```bash
python3 -c "import openpyxl; print(openpyxl.__version__)"
```

## Uso normal

### 1. Popular a planilha do período

```bash
./02_POPULAR_STATUS_BASELINE.py \
  assets_EXPORT.csv \
  status_baselines_tenable_DATA.xlsx
```

O `02` atualiza diretamente a planilha informada.

### 2. Gerar o dashboard

```bash
./03_STATUS_TO_DASH.py status_baselines_tenable_DATA.xlsx
```

Saída:

```text
dashboard_status_baselines.html
```

As planilhas datadas mantidas na pasta também são utilizadas pelo dashboard
para montar o histórico de evolução.

## Utilitário opcional: criar um molde novo

```bash
./01_GERAR_STATUS_BASELINE.py
```

O arquivo abaixo é criado na própria pasta do script:

```text
status_baselines_tenable.xlsx
```

> **Atenção:** executar o `01` novamente substitui esse arquivo e retorna todas
> as métricas para zero. Preserve ou renomeie planilhas históricas antes disso.

### Abas/equipes

O status contém quatro abas:

```text
CLARO-TI
BCC
STAR-ONE
ENG-VIDEO
```

### Perfis canônicos

Cada aba contém os mesmos 19 perfis, inicialmente com `status = Criado`:

```text
RHEL:            6, 7, 8 e 9
Debian:          11, 12 e 13
Ubuntu:          16, 18, 20, 22 e 24
Windows Server:  2012, 2016, 2019, 2022 e 2025
Windows Desktop: 10 e 11
```

### Colunas do status

```text
chave
dominio
familia
versao
perfil
ativos
em_uso
producao
sox
com_agent
sem_agent
escaneados
nao_escaneados
status
baseline
responsavel
observacao
```

## Popular o status com o Tenable

```bash
./02_POPULAR_STATUS_BASELINE.py \
  assets-08_13_2026_-16_49_05-gmt-3.csv \
  status_baselines_tenable.xlsx
```

O segundo argumento é opcional. Sem ele, o script usa
`status_baselines_tenable.xlsx` no diretório atual:

```bash
./02_POPULAR_STATUS_BASELINE.py assets.csv
```

> **Atenção:** o `02` atualiza a planilha informada no próprio arquivo. Antes de
> contar novamente, ele zera as métricas de todas as linhas.

### Colunas obrigatórias do export

```text
display_operating_system
tags
has_agent
last_authenticated_scan_time
```

As demais colunas do export são ignoradas pelos scripts `01` e `02`.

### Identificação das equipes

O campo `tags` deve ser um JSON válido. A categoria da tag define a aba:

```text
Categoria TI                 → CLARO-TI
Categoria BCC                → BCC
Categoria StarOne            → STAR-ONE
Categoria Engenharia Video   → ENG-VIDEO
```

Um ativo com mais de uma dessas categorias será contabilizado em mais de uma
aba. Um ativo sem categoria reconhecida será informado como `sem equipe` e não
entrará no status.

## Regras de classificação

### Família RHEL

As seguintes distribuições são consolidadas nos perfis canônicos RHEL:

```text
Red Hat Enterprise Linux
RHEL
CentOS
Oracle Linux
AlmaLinux
Rocky Linux
```

A versão explícita da distribuição tem prioridade. Quando a descrição informa
a família, mas não informa sua versão, o kernel pode ser usado:

```text
Linux Kernel 3.* → RHEL 7
Linux Kernel 4.* → RHEL 8
Linux Kernel 5.* → RHEL 9
```

Somente versões de 6 a 9 entram no catálogo.

### Debian

São aceitas versões 11 ou superiores quando existe uma linha correspondente no
status. No catálogo atual:

```text
Debian 11
Debian 12
Debian 13
```

### Ubuntu

São aceitas versões 16 ou superiores quando existe uma linha correspondente no
status. No catálogo atual:

```text
Ubuntu 16
Ubuntu 18
Ubuntu 20
Ubuntu 22
Ubuntu 24
```

### Windows Server

Versões posteriores a 2008 são elegíveis. O catálogo atual contém:

```text
Windows Server 2012
Windows Server 2016
Windows Server 2019
Windows Server 2022
Windows Server 2025
```

Descrições de `Windows Server 2012 R2` são consolidadas em `Windows Server
2012`. Windows Server 2008 ou anterior fica fora do catálogo.

### Windows Desktop

Entram somente:

```text
Windows 10
Windows 11
```

## Métricas preenchidas

O `02_POPULAR_STATUS_BASELINE.py` zera e recalcula:

```text
ativos
em_uso
com_agent
sem_agent
escaneados
nao_escaneados
```

Regras:

- `ativos`: quantidade classificada no perfil e na equipe;
- `em_uso`: igual a `ativos` neste pipeline;
- `com_agent`: `has_agent` verdadeiro;
- `sem_agent`: `has_agent` falso;
- `escaneados`: tem agent e `last_authenticated_scan_time` preenchido;
- `nao_escaneados`: tem agent, mas não possui scan autenticado informado.

Os campos abaixo não são calculados pelo export atual:

```text
producao
sox
```

## Registros não contabilizados

O resumo exibido ao final separa:

- `fora do catálogo`: SO ausente, não reconhecido ou fora dos perfis elegíveis;
- `sem equipe`: perfil elegível, mas sem uma das quatro tags organizacionais;
- `sem linha`: perfil reconhecido cuja chave não existe na planilha informada.

Esses registros não são incluídos nas métricas do status.

## Histórico recomendado

O ideal é criar ou nomear a planilha do período antes de executar o `02`:

```bash
./02_POPULAR_STATUS_BASELINE.py \
  assets-08_13_2026_-16_49_05-gmt-3.csv \
  status_baselines_tenable_08_13_2026_16_49_05.xlsx
```

Use nomes consistentes para permitir comparação entre execuções:

```text
status_baselines_tenable_MM_DD_AAAA_HH_MM_SS.xlsx
```

## Execução operacional completa

```bash
cd TENABLE_PURE

./02_POPULAR_STATUS_BASELINE.py \
  assets-08_13_2026_-16_49_05-gmt-3.csv \
  status_baselines_tenable_08_13_2026_16_49_05.xlsx

./03_STATUS_TO_DASH.py \
  status_baselines_tenable_08_13_2026_16_49_05.xlsx
```

Resumo:

```text
Export Tenable → 02 popula o status informado → 03 gera o dashboard
```

## Manutenção

Para alterar o escopo:

- edite `CATALOGO` no `01_GERAR_STATUS_BASELINE.py`;
- mantenha as regras equivalentes em `perfil()` no
  `02_POPULAR_STATUS_BASELINE.py`;
- edite `EQUIPES` nos dois scripts caso as abas ou categorias mudem;
- teste sempre em uma cópia do XLSX, pois os scripts sobrescrevem suas saídas.
