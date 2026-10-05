# Dashboard de Hardening Unix

Este diretório contém um gerador autocontido para consolidar resultados de
auditoria de hardening e produzir um dashboard HTML.

O arquivo `04_gerar_dashboard_hardening_template.py` não depende do gerador
anterior, de módulos locais ou de bibliotecas Python externas. Ele pode ser
copiado sozinho para outro diretório e executado junto aos arquivos de dados.

O dashboard novo foi organizado com base no relatório visual de referência
`TO_DASH_EXEMPLO.png`, preservando a identidade visual vermelha do projeto
atual.

## Arquivos principais

- `04_gerar_dashboard_hardening_template.py`: versão no formato do novo
  painel operacional e totalmente autocontida.
- Arquivos CSV, TSV ou XLSX: resultados das equipes e CMDBs opcionais.
- O nome do arquivo HTML de saída é definido por `--saida`.

## Requisitos

- Python 3.10 ou superior.
- Não requer instalação de bibliotecas externas.
- Resultados em CSV, TSV ou XLSX.
- Navegador moderno para visualizar o HTML.

## Convenção dos resultados

Cada arquivo de resultado representa uma equipe. O nome da equipe é extraído
do trecho anterior ao primeiro `_` no nome do arquivo.

Exemplos:

```text
EQUIPE-N1_27072026_14_32_22-gmt-3.csv → EQUIPE-N1
EQUIPE-N2_resultado.csv                → EQUIPE-N2
EQUIPE-N3_auditoria.xlsx              → EQUIPE-N3
```

Nos arquivos atuais, os resultados precisam possuir estas colunas de origem:

```text
asset.host_name
compliance.audit_name
compliance_result
```

O campo `compliance.audit_name` contém três informações separadas por vírgula:

```text
119, UsePAM habilitado, Alta
```

Durante a leitura, o script transforma esse conteúdo internamente em:

```text
compliance.audit_ID          = 119
compliance.audit_name        = UsePAM habilitado
compliance.audit_criticidade = Alta
```

Por isso, `compliance.audit_ID` e `compliance.audit_criticidade` não precisam
existir como colunas físicas nos CSVs atuais. Se uma fonte futura já entregar
esses campos separados, eles também serão utilizados.

Os estados reconhecidos incluem `PASSED`, `FAILED` e valores equivalentes em
português. Apenas `PASSED` e `FAILED` entram no cálculo da aderência.

## Executando

No diretório do projeto:

```bash
./04_gerar_dashboard_hardening_template.py .
```

Por padrão, o arquivo gerado será:

```text
dashboard_hardening_template.html
```

Para definir outro nome:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --saida dashboard_cliente.html
```

## CMDB por equipe

O CMDB é associado explicitamente a uma equipe. Ele é utilizado somente para
comparar a quantidade de servidores existentes com a quantidade auditada.

Não é realizada conciliação por hostname.

Exemplo:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --cmdb EQUIPE-N1=EQUIPE-N1_CMDB_JIRA.csv
```

Neste caso, os registros do CMDB pertencem somente à `EQUIPE-N1`. Eles não são
somados ao inventário das demais equipes.

É possível associar mais de um CMDB:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --cmdb EQUIPE-N1=EQUIPE-N1_CMDB_JIRA.csv \
  --cmdb EQUIPE-N2=EQUIPE-N2_CMDB.csv
```

Quando uma equipe não possui CMDB ou quantidade de inventário informada, sua
cobertura aparece como `N/D`. Isso evita interpretar ausência de informação
como inventário igual a zero.

## Quantidade fixa de servidores

Quando existe uma quantidade oficial, mas não há um arquivo CMDB disponível,
ela pode ser informada diretamente:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --inventario EQUIPE-N1=444 \
  --inventario EQUIPE-N2=100
```

Também é possível combinar os dois métodos:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --cmdb EQUIPE-N1=EQUIPE-N1_CMDB_JIRA.csv \
  --inventario EQUIPE-N2=100
```

Se a mesma equipe for informada nas duas opções, o CMDB terá precedência.

## Selecionando resultados explicitamente

Sem `--resultado`, o script examina os arquivos CSV, TSV e XLSX do diretório e
considera como resultado somente aqueles que possuem as colunas obrigatórias.

Para limitar a execução a arquivos específicos, repita `--resultado`:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --resultado EQUIPE-N1_27072026_14_32_22-gmt-3.csv \
  --resultado EQUIPE-N2_27072026_14_32_22-gmt-3.csv \
  --cmdb EQUIPE-N1=EQUIPE-N1_CMDB_JIRA.csv
```

Arquivos como os dois `dinv` não possuem o formato de resultado de hardening e
são ignorados na descoberta automática.

## Personalização

Nome do cliente e título:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --cliente "Nome do cliente" \
  --titulo "Baseline de Servidores Unix"
```

Meta individual de aderência:

```bash
./04_gerar_dashboard_hardening_template.py . --meta 75
```

IDs de auditoria que não devem entrar nos cálculos:

```bash
./04_gerar_dashboard_hardening_template.py . \
  --excluir-ids 999,1000,1001
```

O ID `999` é excluído por padrão.

## Exemplo usado neste diretório

```bash
./04_gerar_dashboard_hardening_template.py . \
  --cmdb EQUIPE-N1=EQUIPE-N1_CMDB_JIRA.csv \
  --cliente Claro \
  --titulo "Baseline de Servidores Unix" \
  --saida dashboard_hardening_template.html
```

Com os arquivos atuais, o resultado esperado é:

| Equipe | Auditados | Existentes | Cobertura |
|---|---:|---:|---:|
| EQUIPE-N1 | 71 | 444 | 16,0% |
| EQUIPE-N2 | 71 | N/D | N/D |
| EQUIPE-N3 | 71 | N/D | N/D |

## Indicadores do dashboard

- Aderência consolidada: `PASSED / (PASSED + FAILED)`.
- Não conformidades: quantidade de resultados `FAILED`.
- Criticidade: distribuição dos FAILs entre Alta, Média e Baixa.
- Ativos afetados: servidores com pelo menos um FAIL daquela criticidade.
- Principais não conformidades: controles com maior quantidade de FAILs,
  aplicando prioridade em cascata. Mostra somente Alta quando houver FAILs
  Altos; na ausência deles, somente Média; Baixa aparece apenas quando não
  existirem FAILs Altos nem Médios.
- Meta por servidor: quantidade de servidores acima ou abaixo da meta.
- Cobertura: `servidores auditados / servidores existentes`.

A chave usada para eliminar duplicidades é:

```text
equipe + servidor + Audit ID
```

## Ajuda da linha de comando

```bash
./04_gerar_dashboard_hardening_template.py --help
```

O HTML é autocontido e pode ser aberto diretamente no navegador, enviado para
outras pessoas ou impresso como PDF pelo botão `Imprimir / PDF`.

EXECUCAO TESTE:

rsilva@fedora:~/Documentos/HARDENING/AGDV-1583/AGDV-1584/04$ ./04_gerar_dashboard_hardening_template.py . --saida dashboard_cmdb_informado.html --inventario BCC-TESTE=400 --inventario CLARO-TI=80 --inventario ENG-TESTE=71
Dashboard gerado: /home/rsilva/Documentos/HARDENING/AGDV-1583/AGDV-1584/04/dashboard_cmdb_informado.html
Resumo: 3 equipes | 213 auditados | 17739 FAILs | aderência 53.9%
  BCC-TESTE: cobertura 74/400
  CLARO-TI: cobertura 71/80
  ENG-TESTE: cobertura 68/71
rsilva@fedora:~/Documentos/HARDENING/AGDV-1583/AGDV-1584/04$ ./04_gerar_dashboard_hardening_template.py . --saida dashboard_sem_cmdb.html
Dashboard gerado: /home/rsilva/Documentos/HARDENING/AGDV-1583/AGDV-1584/04/dashboard_sem_cmdb.html
Resumo: 3 equipes | 213 auditados | 17739 FAILs | aderência 53.9%
  BCC-TESTE: cobertura 74/N/D
  CLARO-TI: cobertura 71/N/D
  ENG-TESTE: cobertura 68/N/D
rsilva@fedora:~/Documentos/HARDENING/AGDV-1583/AGDV-1584/04$ 


./04_gerar_dashboard_hardening_gerencial_equipe.py \
  /caminho/dos/resultados \
  --equipe "exemplo-equipe-b" \
  --meta 80 \
  -o dashboard_gerencial_equipe-b.html
