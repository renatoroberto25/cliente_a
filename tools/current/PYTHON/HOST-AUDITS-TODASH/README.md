# Dashboards de hardening

Scripts para transformar resultados de Compliance Audit exportados do Tenable em dashboards HTML autocontidos. Não é necessário servidor web: o HTML pode ser aberto diretamente no navegador.

## Qual script usar

| Script | Cenário | Classificação principal |
|---|---|---|
| `02_gerar_dashboard_hardening_equipe.py` | Histórico legado de uma equipe | Prefixo do nome físico dos arquivos |
| `03_gerar_dashboard_hardening_host_audits.py` | Visão consolidada por tags do Tenable | `asset.tags` |
| `04_gerar_dashboard_hardening_audit_file.py` | Um perfil/audit descoberto automaticamente | `compliance.audit_file` |
| `05_gerar_dashboard_hardening_multi_audits.py` | Mega CSV ou múltiplos exports, equipes e perfis | Taxonomia de `compliance.audit_file` |

Para novos exports, o fluxo recomendado é o `05`.

## Exportação no Tenable

Exporte os resultados de **Compliance** em CSV, mantendo a primeira linha com os nomes originais das colunas. A ordem das colunas não importa: os scripts procuram os campos pelo cabeçalho.

### Cabeçalhos recomendados

Para gerar todos os indicadores e manter rastreabilidade, inclua:

```text
asset.host_name
asset.ip_addresses
asset.name
asset.operating_systems
asset.tags
compliance.audit_description
compliance.audit_file
compliance.audit_name
compliance.audit_see_also
compliance.audit_solution
compliance.info
compliance.references
compliance_result
definition.id
definition.output
definition.synopsis
first_seen
id
last_fixed
last_observed
original_compliance_result
```

Esse é o conjunto encontrado nos exports atuais do Tenable. Os scripts não dependem da posição da coluna — `compliance.audit_file` pode estar na coluna G ou em outra posição.

### Campos essenciais para o fluxo multi-audits (`05`)

| Cabeçalho | Uso |
|---|---|
| `asset.host_name` | Identificação e deduplicação do asset |
| `compliance.audit_file` | Tipo, equipe, perfil, versão e data da baseline |
| `compliance.audit_name` | ID, nome e criticidade do controle |
| `compliance_result` | Resultado `PASSED` ou `FAILED` |

Campos fortemente recomendados:

| Cabeçalho | Uso |
|---|---|
| `asset.ip_addresses` | Exibição e busca por IP |
| `asset.operating_systems` | Identificação do sistema operacional |
| `first_seen` | Início do período observado e desempate |
| `last_observed` | Fim do período observado e escolha da linha mais recente |
| `definition.output` | Diagnóstico técnico e rastreabilidade |
| `asset.tags` | Necessário para a classificação por tags do script `03` |

Se `compliance.audit_ID` e `compliance.audit_criticidade` não existirem como colunas independentes, eles são extraídos de `compliance.audit_name`.

## Padrão editorial dos controles

`compliance.audit_name` deve seguir:

```text
ID, nome do controle, criticidade
```

Exemplo:

```text
123, Garantir que o SSH não permita login direto de root, Alta
```

Criticidades reconhecidas: `Alta`, `Média` e `Baixa`, incluindo equivalentes em inglês. A aderência é calculada por:

```text
PASSED / (PASSED + FAILED)
```

## Taxonomia de `compliance.audit_file`

Os scripts `04` e `05` esperam:

```text
TIPO_EQUIPE_PERFIL_DDMMAAAAHHMM.audit
```

Exemplos:

```text
COMPLIANCE_SENSORES_RHEL7-9_FULL_270820261904.audit
COMPLIANCE_SENSORES_DEB_FULL_V1.2.2_240820260943.audit
```

Interpretação do primeiro exemplo:

- tipo: `COMPLIANCE`;
- equipe: `SENSORES`;
- perfil: `RHEL7-9_FULL`;
- publicação/snapshot da baseline: `27/08/2026 19:04`.

A data do `audit_file` forma a série histórica da baseline. `first_seen` e `last_observed` não criam novos pontos nessa série; eles registram o período em que os resultados foram observados e resolvem duplicidades.

## 05 — mega CSV e multi-audits (recomendado)

Um único CSV pode conter N equipes, N perfis e N audit files. O nome físico do CSV não participa da classificação: cada linha é encaminhada pelo valor de `compliance.audit_file`.

Mega CSV:

```bash
python3 05_gerar_dashboard_hardening_multi_audits.py mega.csv
```

Vários exports:

```bash
python3 05_gerar_dashboard_hardening_multi_audits.py sensores_*.csv
```

Mega CSV mais arquivos complementares:

```bash
python3 05_gerar_dashboard_hardening_multi_audits.py mega.csv sensores_*.csv
```

Diretório inteiro:

```bash
python3 05_gerar_dashboard_hardening_multi_audits.py /caminho/dos/exports/
```

Saída personalizada e meta de 85%:

```bash
python3 05_gerar_dashboard_hardening_multi_audits.py mega.csv \
  --saida dashboard_geral.html \
  --meta 85
```

Regras do `05`:

- separa tipo, equipe, perfil, versão e data usando `compliance.audit_file`;
- cria uma série independente para cada `tipo + equipe + família de perfil`;
- consolida sobreposição entre o mega CSV e exports menores;
- usa a chave `audit_file + asset.host_name + compliance.audit_ID`;
- em duplicidades, prevalece `last_observed`, depois `first_seen`;
- ignora IDs numéricos maiores que `999`, tratados como controles utilitários;
- mostra hosts e controles em cada snapshot para evidenciar mudanças de escopo;
- linhas fora da taxonomia são contabilizadas, mas não entram nos indicadores.

Saída padrão: `dashboard_hardening_multi_audits.html`.

## 04 — dashboard automático de um perfil

Procura os arquivos compatíveis do diretório atual, seleciona o audit mais recente pela taxonomia e define automaticamente equipe, perfil e nome da saída:

```bash
python3 04_gerar_dashboard_hardening_audit_file.py
```

Também é possível indicar um arquivo ou diretório:

```bash
python3 04_gerar_dashboard_hardening_audit_file.py sensores.csv
```

## 03 — consolidado por tags

Use quando as equipes devem ser identificadas por `asset.tags`, com as regras Claro TI, Engenharia de Vídeo, BCC, Star One e Outras equipes.

```bash
python3 03_gerar_dashboard_hardening_host_audits.py HOST_AUDITS.csv \
  --contexto-assets-xlsx STATUS_BASELINES.xlsx \
  --saida dashboard_hardening_host_audits.html \
  --saida-audits-fora-padrao audits_fora_do_padrao.html
```

Cabeçalhos mínimos desse CSV:

```text
asset.host_name
asset.tags
compliance.audit_name
compliance_result
```

O script gera o dashboard principal e um relatório separado com audits fora de `ID, nome, criticidade`. O XLSX de contexto é opcional; quando usado, precisa ter os cabeçalhos `chave`, `dominio`, `ativos`, `em_uso`, `com_agent`, `escaneados` e `nao_escaneados` nas planilhas esperadas pelo script.

## 02 — histórico legado por prefixo

Mantido para relatórios cujo agrupamento depende do nome físico dos arquivos:

```bash
python3 02_gerar_dashboard_hardening_equipe.py . --equipe PREFIXO
```

Para projetos novos, prefira a taxonomia interna do `05`, que também funciona quando todos os resultados estão reunidos em um único CSV.

## Requisitos e observações

- Python 3.10 ou superior;
- não há dependências Python externas;
- `Claro.png` é incorporado no HTML quando está ao lado dos scripts;
- CSV UTF-8 e Latin-1 são reconhecidos automaticamente;
- delimitadores vírgula, ponto e vírgula, tabulação e `|` são detectados;
- IDs numéricos maiores que `999` e IDs configurados em `--excluir-ids` não entram nos indicadores;
- `UNKNOWN` não participa do denominador da aderência.
