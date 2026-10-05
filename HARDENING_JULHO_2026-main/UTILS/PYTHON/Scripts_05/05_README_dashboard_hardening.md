# Dashboard de Hardening por Equipe

O `05_MULTI_TEAMS_MULTI_SHEATS.py` lê resultados CSV, TSV ou XLSX da mesma
pasta e gera um dashboard HTML autocontido, sempre em modo claro.

Requer apenas Python 3.10 ou superior, sem bibliotecas externas.

## Arquivos de resultado

Padrão esperado:

```text
NOME-DA-EQUIPE_...MM_DD_AAAA...csv
```

Exemplo desta pasta:

```text
exemplo-equipe-a_07_29_2026_-12_41_50-gmt-3.csv
```

- Equipe: texto antes do primeiro `_`.
- Data: `MM_DD_AAAA`.
- Horário: ignorado.
- Arquivo sem equipe, data ou colunas válidas: ignorado.
- As equipes são descobertas automaticamente pelo nome dos arquivos.

## Funcionamento

- O painel principal usa somente o arquivo mais recente de cada equipe.
- Arquivos antigos não são somados ao estado atual.
- O histórico usa um ponto por equipe e por dia, em ordem cronológica.
- A meta de conformidade é fixa em 80%.
- O inventário é informado manualmente com `--inventario EQUIPE=TOTAL`.

Colunas mínimas:

```text
asset.host_name
compliance.audit_name
compliance_result
```

Formato de `compliance.audit_name`:

```text
ID, Nome do controle, Criticidade
```

Exemplo:

```text
003, Controle de SSH, Alta
```

## Executar com as amostras atuais

```bash
./05_MULTI_TEAMS_MULTI_SHEATS.py . \
  --inventario exemplo-equipe-a=7 \
  --inventario exemplo-equipe-b=5 \
  --inventario exemplo-equipe-c=10
```

Saída atual:

```text
Dashboard gerado: .../dashboard_hardening.html
Resumo: 3 equipes | 15 auditados | 25 FAILs | aderência 83.3%
Histórico: 9 pontos diários | 3 datas
  EXEMPLO-EQUIPE-A: cobertura 5/7
  EXEMPLO-EQUIPE-C: cobertura 5/10
  EXEMPLO-EQUIPE-B: cobertura 5/5
```

Histórico presente nas amostras:

| Equipe | 16/07/2026 | 20/07/2026 | 29/07/2026 |
|---|---:|---:|---:|
| EXEMPLO-EQUIPE-A | 0% | 66% | 56% |
| EXEMPLO-EQUIPE-B | 0% | 60% | 98% |
| EXEMPLO-EQUIPE-C | 0% | 48% | 96% |

## Opções úteis

```bash
# Alterar o arquivo de saída
./05_MULTI_TEAMS_MULTI_SHEATS.py . --saida dashboard_cliente.html

# Consultar todas as opções
./05_MULTI_TEAMS_MULTI_SHEATS.py --help
```

## Cálculos

- Aderência: `PASSED / (PASSED + FAILED)`.
- Cobertura: servidores auditados / inventário informado.
- Chave única: equipe + servidor + ID do controle.
- O ID `999` é excluído por padrão.
