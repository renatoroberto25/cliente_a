# Hardening — status e próximos passos

Atualizado em 08/09/2026.

Audits Tenable, baselines e automações foram criados. A estrutura disponível permite remediar, auditar, contra-auditar, gerar dashboards e apresentar os resultados. Os audits estão consolidados em taxonomia para exibição dos dados no fluxo:

`AUDIT → RESULTADO → processamento .py → DASHBOARD HTML`

As pendências atuais dependem de acessos, conectividade, disponibilidade e retorno das equipes. Exigem articulação da coordenação/gerência com os responsáveis externos à execução técnica do hardening.

**Todas as equipes receberão a automação em shell script, incluindo BCC.**

## Status por equipe

### BCC

Há defasagem entre a versão entregue e as automações disponíveis, além de complexidade na execução via Ansible puro. A continuidade será feita com os shell scripts.

- [ ] Entregar os scripts(automações de e rhel like) adequados ao sistema operacional e alinhar a execução com a equipe.
- [ ] Registrar a versão entregue e agendar aplicação e contra-auditoria.

### ENG VÍDEO

Em andamento, com avanço lento por indisponibilidade da equipe. Na semana anterior a esta atualização, GMUDs e outras atividades impediram a disponibilização de tempo para o hardening.

Os alinhamentos anteriores amadureceram a automação, com rollback, index e backups locais confiáveis. A aplicação AS-IS nos sensores estava sem problemas reportados até 28/08/2026.

- [ ] Retomar agenda com a equipe para continuar aplicação e validação.

### CLARO-TI

Ponto sensível: alinhar com **Edgard/HITSS** uma regra global de firewall que permita a todas as redes sob nossa administração acessar a **Tenable Cloud pela porta TCP 443**.

Permanece o histórico de resistência à aplicação AS-IS. As adaptações feitas pela equipe suavizaram remediações e mantiveram FAILs na auditoria, com aderência abaixo de 80% no perfil FULL. O perfil light apresentou boa aderência nos RHEL 7 com agentes mais antigos.

Ativos citados no acompanhamento: `brux1270`, `rjux0197`, `ecc11cashdb01`, `brux0782`, `cbl2am37400`.

- [ ] Tratar com Edgard/HITSS a liberação global de firewall e validar a conectividade das redes administradas.
- [ ] Alinhar a aplicação dos shell scripts e contra-auditar os FAILs persistentes.

Encaminhamento: **Pavlov → Rogers**. Solicitar usuário para acesso autenticado, com credencial no cofre CyberArk. Usuário com `sudo` é suficiente; autenticação por senha ou chave RSA.

- [ ] Alinhar com Pavlov o contato com Rogers para disponibilizar o acesso.
- [ ] Validar autenticação e sudo antes de seguir com a execução.

### STAR ONE

Sem resposta até esta atualização. Hardening já disponibilizado; permanece pendente o retorno de **Eduardo Kiki** para testes. Backups continuam como questão do ambiente a resolver.

- [ ] Obter retorno de Eduardo Kiki e definir agenda de testes.
- [ ] Confirmar as condições de backup do ambiente.

## Materiais de referência

Materiais no repositório:

| Material | Local |
|---|---|
| Audits Tenable | [audits/](audits/) |
| Baselines e critérios de enquadramento | [baselines/README.md](baselines/README.md) |
| Automações disponíveis | [automation/current/](automation/current/) |
| Automação Debian-like | [DEB_v1.2.3](automation/current/DEB_v1.2.3/README.md) |
| Automação RHEL-like | [RHEL_V1.3.6](automation/current/RHEL_V1.3.6/README.md) |
| Resultados e evidências | [results/](results/) |
| Ferramentas de processamento | [tools/current/](tools/current/) |

## Próximos passos

1. Atualizar com as equipes os pontos focais, as pendências e as janelas de execução.
2. Priorizar com coordenação/gerência o desbloqueio de firewall, credenciais e agendas.
3. Confirmar sistema operacional, baseline, versão do script e condições de backup/rollback de cada ambiente.
4. Aplicar a remediação na janela alinhada com a equipe e executar auditoria/contra-auditoria.
5. Consolidar evidências, gerar dashboards e apresentar aderência, FAILs e dependências restantes.

A base técnica está disponível para execução. Registrar cada avanço com equipe, ativo, versão aplicada, data, resultado da auditoria e próxima ação.
