# Diff e consolidação dos audits executados

## Resultado

- 13 arquivos de origem analisados.
- 11 conteúdos técnicos únicos por SHA-256.
- 2 pares de conteúdo exato detectados, sem fundir as identidades das equipes.
- 13 baselines independentes gerados: um para cada arquivo `COMPLIANCE_*.audit`.

## Duplicatas exatas

| SHA-256 (prefixo) | Primeiro audit | Outro baseline com conteúdo idêntico |
|---|---|---|
| `6fe2aeee0489` | `COMPLIANCE_AUTENTICADO_DEB_FULL_V1.2.2_240820261554.audit` | `COMPLIANCE_SENSORES_DEB_FULL_POST_V1.2.2_180820261100.audit` |
| `49ef75f328df` | `COMPLIANCE_CLARO-TI-PILOTO_RHEL_FULL_V1.3.5_270820261907.audit` | `COMPLIANCE_LAB_RHEL7-9_FULL_PRE_V1.3.5_130820261348.audit` |

## Audits próximos que não são duplicatas

| Grupo | Similaridade observada | Decisão |
|---|---:|---|
| RHEL Claro TI JIRA PRE (184) x RHEL Claro TI JIRA FULL (182) | 98,9% dos comandos | Manter ambos: há diferença de controles. |
| RHEL LAB POS (177) x RHEL Claro TI Piloto/LAB PRE (177) | 89,2% dos comandos; 98,9% das descrições | Manter ambos: os comandos executados mudam. |
| RHEL Sensores FULL (177) x RHEL LAB POS (177) | 84,3% dos comandos; 100% das descrições | Manter ambos: mesma cobertura nominal, implementação de auditoria diferente. |
| Debian Sensores PRE (170) x Debian Sensores FULL (169) | 98,2% dos comandos; 34,0% das descrições exatas | Manter ambos: metadados e cobertura não são idênticos. |
| Debian Autenticado/POST (159) x Debian Sensores FULL (169) | 89,4% dos comandos; 90,7% das descrições | Manter ambos: conjuntos de controles diferentes. |

## Critério aplicado

O conteúdo repetido foi confirmado por SHA-256, mas não elimina um baseline quando a
equipe, o perfil ou a execução identificada no nome são diferentes. Similaridade de
descrição ou comando foi usada apenas para localizar variantes.

Cada workbook `BASELINE_COMPLIANCE_*.xlsx` usa exatamente um audit como fonte de verdade.
A aba `Origem` registra nome, plataforma, quantidade de controles e SHA-256; a aba
`Baseline` preserva os campos técnicos efetivamente usados naquele scan.
