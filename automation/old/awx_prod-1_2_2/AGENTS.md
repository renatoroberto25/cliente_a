# Diretrizes para Codex / Agente IA — awx_prod-1_2_2

## Regra de Ouro (Modo de Operação)
- **Apenas Criação de Código:** Você NÃO executa nada, NÃO testa, NÃO assume que o ambiente está rodando. O usuário sobe as VMs no Vagrant, testa, destrói e valida.
- **Sem Verborragia:** Proibido introduções, resumos do que foi feito, saudações ou explicações teóricas. Entregue apenas o código/diff direto.
- **Uma Coisa por Vez:** Faça estritamente o que foi pedido na mensagem atual. Não adivinhe próximos passos, não tome iniciativas, não gere "de brinde" roles/tasks que não foram solicitados.
- **Sem Assunções:** Não invente variáveis, pacotes, tags, módulos ou controles que não estejam explicitamente no baseline (`vars/*.yml`, `catalogs/*.csv`) ou nos shellscripts de origem (`REMED_SH/*.sh`, `AUDIT_SH/audit.sh`).
- **Se faltar informação:** pare e pergunte. Não preencha lacuna com suposição.
- **"Apenas Criação de Código" não é gatilho para gerar em lote.** Essa regra trata exclusivamente de você não executar/testar/validar rodando (isso é papel do usuário). Ela NÃO autoriza, nem por analogia, pular a granularidade definida em "Ordem de Trabalho". São regras independentes — uma não anula a outra.
- **Proibido pedir autorização para pular etapa da Ordem de Trabalho.** Se em algum momento você concluir que seria "mais eficiente" gerar todos os domínios de audit+remediation de uma vez, ou qualquer outra forma de agrupar/antecipar entregas além do que foi pedido na mensagem atual, a resposta já é NÃO por definição deste documento. Não pergunte, não sugira, não ofereça como opção. Apenas execute a tarefa da mensagem atual, no escopo pedido, e pare.
- **Domínio == 1 arquivo de audit ou 1 arquivo de remediation, nunca ambos juntos**, e nunca mais de um domínio por resposta, mesmo que o usuário peça algo que pareça abranger vários (nesse caso, pergunte qual domínio específico antes de gerar).

## Escopo
Replicar 1:1 a lógica de `BASES/DEB_v1.2.3` e `BASES/RHEL_V1.3.6` (audit.sh + REMED_SH/*.sh) em roles Ansible para RHEL-like e Debian-like, mantendo o mesmo ID de controle usado no shell/baseline para permitir auditoria cruzada.

- `playbooks/audit.yml`: apenas verifica e valida. Não corrige.
- `playbooks/remediation.yml`: aplica a correção determinística.
- Se um controle não puder ser corrigido com segurança (ex.: requer decisão humana, risco de quebra de serviço), retornar status `MANUAL` — nunca tentar "adivinhar" a correção.
- Idempotência obrigatória: rodar o playbook duas vezes seguidas não pode gerar `changed: true` na segunda execução se nada mudou no host.
- Preferir módulos nativos do Ansible (`lineinfile`, `sysctl`, `pam_limits`, `template`, `service`, `user`, etc.). Usar `shell`/`command` **somente** quando não existir módulo equivalente, e sempre com `changed_when` e `failed_when` explícitos.

## Estrutura de Diretórios (respeitar o padrão existente)
```
roles/
  audit/
    tasks/<dominio>.yml
    rules/<dominio>.yml      # metadados do controle (id, severidade, descrição)
  remediation/
    tasks/<dominio>.yml
    rules/<dominio>.yml
    handlers/main.yml
  common/
    tasks/main.yml
vars/
  baseline_<family>.yml
inventories/<env>/hosts
```
Não criar estrutura alternativa. Não renomear diretórios existentes.

## Rastreabilidade por Controle (Obrigatório em todo playbook)
Cada controle avaliado deve gerar um fato padronizado, equivalente ao CSV do `executor.sh`:

```yaml
- name: "<id_controle> - <descrição curta>"
  ansible.builtin.set_fact:
    resultado_controle:
      id: "<id_controle>"
      severidade: "<BLOCK|WARN|INFO>"
      status: "<PASS|FAIL|MANUAL|CHANGED>"
      detalhe: "<texto curto e objetivo>"
```
- `status` não pode ser omitido ou implícito via `changed`/`ok` puro do módulo — precisa ser explícito.
- O playbook orquestrador consolida esses fatos em relatório final (CSV/JSON), salvo em `logs/reports/{{ inventory_hostname }}/`, espelhando `summary.json`/`summary.txt`/`precheck.csv` do executor.sh.
- Não gerar esse consolidador antes de todos os roles de domínio estarem prontos e validados — isso só é pedido explicitamente quando chegar essa fase.

## Pré-check (equivalente ao `run_precheck` do executor.sh)
Antes de audit/remediation, validar (via `assert`/`fail`, sem corrigir nada):
- Família/versão do SO suportada.
- Privilégio (root/become) adequado ao modo.
- Espaço em disco mínimo para logs.
- Sintaxe/config atual válida antes de mexer (ex.: `sshd -t`, `visudo -c` quando aplicável via `command` com `changed_when: false`).

Bloqueio (`BLOCK`) para pré-check falho = playbook deve parar (`fail` / `meta: end_play`), não seguir mesmo assim.

## Snapshot / Rollback
- Antes de remediation, gerar backup dos arquivos gerenciados (lista já existe em `MANAGED_FILES` do `executor.sh` — reaproveitar, não recriar do zero).
- Usar `ansible.builtin.copy` com `remote_src: true` e `backup: true` ou task dedicada de snapshot, salvando em `logs/backups/{{ inventory_hostname }}/{{ run_id }}/`.
- Rollback é playbook separado (`playbooks/rollback.yml`), não task dentro de remediation.

## Tenable Agent — Prioridade Crítica
Hoje o maior problema é: playbook "roda com sucesso" mas o agente não aparece na console e não há log de troubleshooting. O role de Tenable **não pode** seguir o padrão genérico de "instalar e reportar changed: true". Deve obrigatoriamente:

1. Capturar stdout/stderr real do instalador (`register`), não descartar.
2. Após instalação, checar status do serviço (`nessusagent`) via módulo `service_facts` ou `command: systemctl status`.
3. Validar o link com a console via `nessuscli agent status` (ou equivalente), com `register` do resultado.
4. `failed_when` explícito se o agente não estiver linkado — não reportar sucesso silencioso.
5. Persistir o output bruto do troubleshooting em `logs/remed/tenable/{{ inventory_hostname }}-{{ run_id }}.log`, para que o operador não fique "a ver navios".
6. Retry configurável (variável, não hardcoded) para falha de link, com número máximo de tentativas antes de marcar `FAIL` definitivo.

Este role deve ser tratado como entrega isolada, não como parte de um bloco genérico de "agents/serviços".

## Ordem de Trabalho (seguir nesta sequência, um item por comando)
1. Esqueleto de diretórios/arquivos vazios (RHEL e DEB), sem lógica.
2. Migração de vars/baseline (CSV → YAML), mantendo IDs de controle originais.
3. Um domínio de audit por vez, espelhando o `.sh` correspondente linha a linha.
4. Remediation do mesmo domínio, somente após audit validado pelo usuário.
5. Role Tenable Agent (ver seção acima), isolado.
6. Playbook orquestrador + relatório consolidado — só ao final.

## Formato de Resposta
1. Entregue apenas o bloco de código ou arquivo a ser criado/alterado.
2. Nenhuma frase extra antes ou depois do código.
3. Pare e aguarde o próximo comando.
