# Política de consolidação

## Autoridade

`HARDENING_CLARO_2026_S2-agosto_2026` é a fonte oficial para audits,
baselines e automações atuais.

## Decisões

- Audits e baselines de julho de 2026 ou anteriores não serão importados.
- Arquivos idênticos ao conteúdo de agosto serão descartados da migração.
- Shell scripts antigos serão avaliados somente por funcionalidade ausente.
- `awx_prod-1_2_2` será a base Ansible de produção.
- Ansible e IAC antigos ficarão como candidatos até revisão técnica.
- Dashboards, Windows, relatórios e utilitários exclusivos serão avaliados
  separadamente.
- Resultados de execução e dados exportados não serão misturados com código.

## Estados do inventário

- `official`: audit ou baseline oficial de agosto.
- `current`: automação atual de agosto.
- `current_support`: documentação ou dado de apoio atual.
- `candidate`: funcionalidade a avaliar para incorporação.
- `duplicate_of_august`: conteúdo já existente em agosto.
- `excluded_old_content`: audit ou baseline antigo excluído por regra.
- `review_data`: resultado ou dado antigo que exige decisão.
- `review_legacy`: documentação ou conteúdo histórico a classificar.

O inventário completo está em `docs/inventory.tsv` e pode ser regenerado com
`scripts/build_inventory.sh`.

## Resumo do primeiro inventário

- 2.128 arquivos analisados.
- 112 audits/baselines oficiais de agosto.
- 714 audits/baselines antigos excluídos.
- 173 arquivos antigos idênticos ao conteúdo de agosto.
- 350 candidatos Ansible antigos.
- 365 candidatos shell antigos.
- 36 candidatos de dashboard antigos.
- 18 candidatos IAC antigos.
