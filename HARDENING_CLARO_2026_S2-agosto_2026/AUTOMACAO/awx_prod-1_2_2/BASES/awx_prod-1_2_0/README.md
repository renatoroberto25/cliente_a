# HITSS AWX Pro 1.2

Projeto Ansible para auditoria e aplicação do baseline de hardening Claro TI
em sistemas RHEL-like.

## Escopo oficial

A única fonte de verdade é o arquivo validado pelo cliente:

```text
05_Hardening_CLARO-TI_RHEL_JIRA.csv
```

O projeto executa exatamente os 181 IDs presentes nesse CSV:

- auditoria: 181 controles, sem IDs adicionais;
- remediação: 181 controles, sem IDs adicionais;
- ID, perfil e descrição: mantidos em `vars/baseline_claro_ti.yml` conforme o CSV;
- controles sem correção segura ou sem parâmetros definidos pelo cliente: resultado `MANUAL`.

Planilhas anteriores e scripts shell não definem o comportamento desta
automação. Não existem controles de `firewalld`, `iptables` ou `nftables`
nesse escopo.

## Playbooks

### Auditoria

```text
playbooks/audit.yml
```

Valida o baseline sem corrigir o host. Os resultados são apresentados como:

```text
[HITSS][AUDIT][ID] APROVADO
[HITSS][AUDIT][ID] REPROVADO
```

### Remediação

```text
playbooks/remediation.yml
```

Aplica somente correções determinísticas. Os resultados possíveis são:

```text
[HITSS][REMEDIATION][ID] OK
[HITSS][REMEDIATION][ID] CHANGED
[HITSS][REMEDIATION][ID] MANUAL
[HITSS][REMEDIATION][ID] FALHA
```

`MANUAL` não significa controle ignorado. Significa que sua aplicação exige
senha, janela de mudança, validação de compatibilidade ou definição específica
do ambiente.

## Configuração no AWX

Crie dois Job Templates usando o mesmo Project, Inventory e Machine Credential:

| Nome sugerido | Playbook |
| --- | --- |
| `HITSS - Audit 1.2` | `playbooks/audit.yml` |
| `HITSS - Remediation 1.2` | `playbooks/remediation.yml` |

Configuração necessária:

- habilitar **Privilege Escalation**;
- utilizar credencial com acesso SSH e `become`;
- limitar o Inventory a hosts RHEL-like;
- executar primeiro a auditoria;
- revisar os resultados `MANUAL` antes da remediação.

O inventário em `inventories/prod/hosts` é somente um modelo. No AWX, utilize
o Inventory administrado pelo Automation Controller.

## Execução local

Instale o Ansible definido em `requirements.txt` e ajuste o inventário:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml
ansible-playbook -i inventories/prod/hosts playbooks/remediation.yml
```

Execução limitada a um host:

```bash
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml --limit servidor
```

Execução por domínio:

```bash
ansible-playbook playbooks/audit.yml --tags baseline_kernel
ansible-playbook playbooks/remediation.yml --tags baseline_accounts
```

Tags principais:

- `baseline_kernel`;
- `baseline_fs`;
- `baseline_network`;
- `baseline_services`;
- `baseline_accounts`;
- `baseline_pam`;
- `file_permissions`;
- `baseline_family`;
- `baseline_client`.

## Estrutura

```text
awx_prod-1.2/
├── ansible.cfg
├── inventories/prod/hosts
├── playbooks/
│   ├── audit.yml
│   └── remediation.yml
├── roles/
│   ├── common/
│   ├── audit/
│   └── remediation/
└── vars/
    ├── baseline_claro_ti.yml
    └── hitss.yml
```

- `roles/common`: carrega o catálogo e valida a família do sistema operacional;
- `roles/audit/tasks`: validações do host;
- `roles/audit/rules`: valores técnicos esperados;
- `roles/remediation/tasks`: correções, pós-checks e controles manuais;
- `roles/remediation/rules`: parâmetros técnicos de correção;
- `vars/baseline_claro_ti.yml`: catálogo oficial de ID, perfil e descrição;
- `vars/hitss.yml`: parâmetros ajustáveis do ambiente.

## Evidências

Audit e remediation aparecem integralmente no Job Output do AWX. Cada execução
também registra data, versão, host, sistema operacional e tags em:

```text
/var/log/hitss-hardening.log
```

## Validação do projeto

```bash
ansible-playbook -i localhost, --connection=local playbooks/audit.yml --syntax-check
ansible-playbook -i localhost, --connection=local playbooks/remediation.yml --syntax-check
```

Antes de promover alterações, confirme novamente que audit e remediation
possuem exatamente os mesmos 181 IDs do CSV oficial.
