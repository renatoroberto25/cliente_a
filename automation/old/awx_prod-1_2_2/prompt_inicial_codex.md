# Contexto do Projeto

Repositório: `~/GitHub/HARDENING_CLARO_2026_S2/AUTOMACAO/awx_prod-1_2_2`

Este projeto contém automação de hardening (personalizado) para RHEL e Debian, hoje implementada em shellscript puro, organizada em `BASES/`:

```
BASES/
  awx_prod-1_2_0/        <- versão Ansible anterior, DESATUALIZADA, servirá de referência de estrutura, não de conteúdo
  DEB_v1.2.3/            <- shellscript Debian, é a fonte de verdade atual (Debian)
    AUDIT_SH/audit.sh
    REMED_SH/01_kernel.sh ... 18_home_file_hygiene.sh
    executor.sh
    logs/{audit,remed,reports}
  RHEL_V1.3.6/            <- shellscript RHEL, é a fonte de verdade atual (RHEL)
    AUDIT_SH/audit.sh
    REMED_SH/01_kernel.sh ... 18_home_file_hygiene.sh
    executor.sh
    baseline_rhel_1.3.5_resumido.csv
    05_Hardening_CLARO-TI_RHEL_JIRA.csv
    logs/{audit,remed,reports,backups}
```

Baseline/catálogo de controles consolidado: `catalogs/baseline_deb.csv` e `catalogs/baseline_rhel.csv`.

## O que existe hoje (awx_prod-1_2_0) e por que está sendo substituído
A versão `awx_prod-1_2_0` já é Ansible, mas está desatualizada em relação ao baseline atual (`RHEL_V1.3.6` / `DEB_v1.2.3`) e, principalmente, **o role de instalação do Tenable Agent não dá visibilidade nenhuma**: o playbook roda, reporta sucesso, mas o agente não aparece na console do Tenable e não existe log/troubleshooting que explique o motivo. Isso é hoje o maior ponto de dor operacional.

## Objetivo geral
Reescrever a automação em **Ansible puro**, replicando fielmente a lógica já validada nos shellscripts de `DEB_v1.2.3` e `RHEL_V1.3.6` — não reinventar controles, não mudar critério de PASS/FAIL, apenas traduzir a execução shell para tasks/roles Ansible idempotentes.

O comportamento do playbook deve espelhar o `executor.sh` atual:
- **Pré-check operacional** antes de qualquer ação (SO suportado, privilégio, espaço em disco, sintaxe/config atual válida) — bloqueia execução se falhar.
- **Audit**: verifica e reporta PASS/FAIL/MANUAL por controle, sem alterar nada.
- **Remediation**: aplica correção determinística; se não for seguro corrigir automaticamente, retorna `MANUAL`.
- **Snapshot antes de remediar** (lista de arquivos gerenciados já existe no `executor.sh`, variável `MANAGED_FILES`) e **rollback** a partir desse snapshot.
- **Relatório consolidado** por execução (equivalente a `summary.json`/`summary.txt`/`precheck.csv`), com contagem de PASS/FAIL/MANUAL e comparação antes/depois.

O `executor.sh` anexados ao repositório (ou já compartilhado com você) é a referência de comportamento — leia-o inteiro antes de começar qualquer tarefa. Claro não vai ser a mesma coisa no ansible não vai ser interativo ok, mas o backup rollback é mt interessante.

## Regras de trabalho
Todas as regras de como você deve trabalhar (o que pode e não pode fazer, formato de resposta, granularidade de entrega, rastreabilidade por controle, estrutura de diretórios obrigatória) estão em `AGENTS.md`, na raiz deste diretório. Leia e siga à risca, incluindo a seção "Ordem de Trabalho" — ela define a sequência em que as tarefas serão pedidas. Não pule etapas, não antecipe etapas futuras.

## Prioridade crítica: Tenable Agent
Quando chegarmos na etapa do role de instalação do Tenable Agent (etapa 5 da Ordem de Trabalho em `AGENTS.md`), o foco não é só instalar — é dar visibilidade total: capturar output real do instalador, validar status do serviço, validar link com a console (`nessuscli agent status` ou equivalente), falhar explicitamente (`failed_when`) se não linkar, e gravar log de troubleshooting em arquivo. Isso está detalhado no `AGENTS.md`, seção "Tenable Agent — Prioridade Crítica". Não trate esse role como genérico.

## Primeira tarefa (fazer APENAS isto agora)
Leia `executor.sh`, `AGENTS.md` e a estrutura de `BASES/DEB_v1.2.3` e `BASES/RHEL_V1.3.6`.

Depois, gere **apenas o esqueleto de diretórios e arquivos vazios** (sem nenhuma task, sem lógica, sem vars preenchidas) para os dois novos conjuntos de roles, um para RHEL-like e outro para Debian-like, respeitando a estrutura definida em `AGENTS.md`:

```
roles/
  audit/tasks/
  audit/rules/
  remediation/tasks/
  remediation/rules/
  remediation/handlers/
  common/tasks/
vars/
inventories/<env>/hosts
playbooks/audit.yml
playbooks/remediation.yml
```

Não crie conteúdo de tasks. Não crie roles referentes ao Tenable ainda. Não gere relatório nem orquestrador. Apenas a árvore vazia (arquivos `.gitkeep` ou `main.yml` vazio onde fizer sentido para o Ansible reconhecer o role).

Aguarde meu próximo comando antes de prosseguir.
