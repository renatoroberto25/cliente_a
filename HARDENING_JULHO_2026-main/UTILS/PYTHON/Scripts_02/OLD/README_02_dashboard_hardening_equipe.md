# Dashboard técnico individual de hardening

Documentação do script `02_gerar_dashboard_hardening_equipe.py`.

## Objetivo

Gerar um dashboard HTML técnico para uma única equipe de infraestrutura.

A equipe é definida por `--equipe`, que funciona como o prefixo da família de arquivos. O script:

1. procura somente os arquivos dessa família;
2. identifica a data de cada coleta pelo nome;
3. usa a coleta mais recente no diagnóstico principal;
4. usa todas as coletas da família no histórico;
5. gera um HTML autocontido, sem dependências externas.

## Requisitos

- Python 3.10 ou superior;
- `Claro.png` no mesmo diretório do script;
- arquivos de resultado em CSV, TSV ou XLSX;
- nenhuma biblioteca Python externa.

## Uso recomendado

Execute no diretório dos resultados:

```bash
./02_gerar_dashboard_hardening_equipe.py . \
  --equipe "exemplo-equipe-b" \
  --meta 80 \
  -o dashboard_equipe-b_unix.html
```

Também é possível informar qualquer arquivo-semente do diretório:

```bash
./02_gerar_dashboard_hardening_equipe.py \
  exemplo-equipe-c_07_29_2026_-12_41_50-gmt-3.csv \
  --equipe "exemplo-equipe-b" \
  --meta 80 \
  -o dashboard_equipe-b_unix.html
```

Nesse exemplo, o arquivo da equipe C serve somente para localizar o diretório. Quem seleciona os dados é `--equipe exemplo-equipe-b`. Portanto, somente arquivos iniciados por `exemplo-equipe-b` entram no dashboard.

## Convenção dos arquivos

Formato esperado:

```text
<EQUIPE>_<MM>_<DD>_<AAAA>_<informações adicionais>.csv
```

Exemplo:

```text
exemplo-equipe-b_07_16_2026_-12_41_50-gmt-3.csv
exemplo-equipe-b_07_20_2026_-12_41_50-gmt-3.csv
exemplo-equipe-b_07_29_2026_-12_41_50-gmt-3.csv
```

Para `--equipe exemplo-equipe-b`:

- os três arquivos pertencem à mesma família;
- a amostra de 29/07/2026 alimenta o diagnóstico atual;
- as três amostras alimentam o histórico;
- arquivos de outras equipes são ignorados.

A data deve existir no nome no padrão `_MM_DD_AAAA_`.

Se houver mais de um arquivo da mesma família na mesma data, somente um ponto diário é mantido. O desempate utiliza o nome do arquivo.

## Colunas de entrada

Colunas obrigatórias:

```text
asset.host_name
compliance_result
```

O controle pode ser informado de duas maneiras.

### Colunas separadas

```text
compliance.audit_ID
compliance.audit_name
compliance.audit_criticidade
```

### Campo composto

```text
compliance.audit_name
```

No formato:

```text
001, Descrição do controle, Alta
```

O script separa automaticamente ID, descrição e criticidade.

Colunas opcionais usadas no detalhamento:

```text
asset.ip_addresses
asset.operating_systems
```

## Normalização

Resultados reconhecidos como aprovados:

```text
PASSED, PASS, COMPLIANT, CONFORME, OK, TRUE
```

Resultados reconhecidos como falha:

```text
FAILED, FAIL, NON COMPLIANT, NAO CONFORME, NOK, FALSE
```

Demais valores são classificados como `UNKNOWN` e não entram no denominador de aderência.

Criticidades normalizadas:

- Alta: inclui Alta, Crítica, High e Critical;
- Média: inclui Média, Medium, Moderada e Moderate;
- Baixa: inclui Baixa e Low;
- valores diferentes: Não informada.

## Regra de cálculo

A unidade única é:

```text
asset.host_name + compliance.audit_ID
```

Em registros duplicados, prevalece a última linha encontrada.

A aderência é:

```text
PASSED / (PASSED + FAILED) × 100
```

A meta padrão é 80%.

- aderência maior ou igual a 80%: host na meta;
- aderência abaixo de 80%: host abaixo da meta;
- host na meta: gap igual a zero;
- host abaixo da meta: gap representa as conversões mínimas de FAILED para PASSED necessárias para chegar a 80%.

Como os controles irrelevantes já foram retirados da base, alcançar 80% não exige alterações adicionais nos hosts que já estão na meta. Os FAILs restantes continuam no backlog técnico, mas não aumentam o gap da meta.

## Exclusão de controles

Por padrão, o ID `999` é excluído:

```bash
--excluir-ids 999
```

Para excluir vários IDs:

```bash
--excluir-ids "999,998,997"
```

Para não excluir nenhum ID:

```bash
--excluir-ids ""
```

Se o ID não existir na base, a configuração não altera os resultados.

## Ordem da narrativa

O HTML apresenta:

1. leitura da situação atual;
2. distribuição das não conformidades por criticidade;
3. hosts prioritários;
4. controles de maior alcance;
5. esforço para alcançar 80%;
6. fila técnica por host;
7. backlog completo por controle;
8. histórico e evolução da equipe.

## Histórico

O rodapé contém três gráficos:

- aderência consolidada;
- total de FAILs;
- servidores auditados.

Também apresenta a variação entre as duas últimas coletas:

- diferença de aderência em pontos percentuais;
- aumento ou redução de FAILs;
- aumento ou redução de servidores auditados.

O número de servidores representa os hosts encontrados na coleta. Cobertura de CMDB não é calculada porque os arquivos atuais não fornecem um inventário CMDB separado.

## Parâmetros

| Parâmetro | Obrigatório | Padrão | Finalidade |
|---|---:|---:|---|
| `entrada` | não | diretório atual | Diretório ou arquivo-semente usado para localizar os resultados |
| `--equipe` | sim | — | Prefixo da família de arquivos |
| `-o, --saida` | não | `dashboard_hardening_equipe.html` | HTML de saída |
| `--meta` | não | `80` | Meta percentual por servidor |
| `--excluir-ids` | não | `999` | IDs desconsiderados |
| `--cliente` | não | `Claro` | Nome exibido no dashboard |
| `--titulo` | não | `Baseline de Servidores Unix` | Título do relatório |

## Exemplos

### Equipe B

```bash
./02_gerar_dashboard_hardening_equipe.py . \
  --equipe "exemplo-equipe-b" \
  -o dashboard_equipe-b_unix.html
```

### Equipe C

```bash
./02_gerar_dashboard_hardening_equipe.py . \
  --equipe "exemplo-equipe-c" \
  -o dashboard_equipe-c_unix.html
```

### Diretório externo

```bash
./02_gerar_dashboard_hardening_equipe.py /dados/resultados \
  --equipe "equipe-linux-core" \
  --meta 80 \
  -o dashboard_linux_core.html
```

## Saída no terminal

Exemplo:

```text
Dashboard da equipe gerado: /caminho/dashboard_equipe-b_unix.html
Família: exemplo-equipe-b* | 3 amostras | atual: exemplo-equipe-b_07_29_2026_-12_41_50-gmt-3.csv
Equipe: exemplo-equipe-b | 5 hosts | 1 FAILs | aderência 98.0% | 5 na meta
```

## Erros comuns

### Nenhum arquivo da família

Confirme o prefixo:

```bash
ls -1 exemplo-equipe-b*
```

### Data não reconhecida

Confirme o padrão `_MM_DD_AAAA_` no nome.

### Logo não encontrado

Mantenha estes arquivos juntos:

```text
02_gerar_dashboard_hardening_equipe.py
Claro.png
```

### Mistura entre equipes

Os dados são selecionados exclusivamente por `--equipe`. O argumento `entrada` somente determina onde procurar.


./02_gerar_dashboard_hardening_equipe.py --equipe claro-ti-default --cliente Claro -o dash_default.html;
./02_gerar_dashboard_hardening_equipe.py --equipe claro-ti-jira --cliente Claro -o dash_jira.html;
./02_gerar_dashboard_hardening_equipe.py --equipe claro-ti-piloto --cliente Claro -o dash_piloto.html