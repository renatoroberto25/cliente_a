## Como Usar
### 1. Verificar conectividade
```bash
ansible -i inventory/hosts -m ping all
```
### 2. Rodar auditoria completa
```bash
ansible-playbook -i inventory/hosts playbooks/audit.yml
ansible-playbook -i inventory/hosts playbooks/audit.yml | tee logs/audit/audit-$(date +%Y%m%d-%H%M%S).log


```
### 3. Rodar remediação completa
```bash
ansible-playbook -i inventory/hosts playbooks/remediation.yml
ansible-playbook -i inventory/hosts playbooks/remediation.yml | tee logs/remediation/remediation-$(date +%Y%m%d-%H%M%S).log

```
### 4. Executar controle específico
```bash
ansible-playbook -i inventory/hosts playbooks/audit.yml --tags audit_hitss_XX -l servidor_web
ansible-playbook -i inventory/hosts playbooks/remediation.yml --tags remediation_hitss_XX -l servidor_web
```
### 5. Listar todas as tags disponíveis
```bash
ansible-playbook -i inventory/hosts playbooks/audit.yml --list-tags
ansible-playbook -i inventory/hosts playbooks/remediation.yml --list-tags
```
## Comandos Úteis com Ansible
```bash
ansible host1 -i inventory/hosts -m shell -a "uptime"
ansible host1 -i inventory/hosts -m shell -a "df -h"
ansible host1 -i inventory/hosts -m shell -a "systemctl status sshd"
ansible all   -i inventory/hosts -m command -a "cat /etc/os-release"
```

## Logs & Resultado da Auditoria
- Logs são gerados manualmente salvar em `logs/{audit,remediation}/` com timestamp.
- Exeomplo: ansible-playbook -i inventory/hosts playbooks/remediation.yml | tee logs/remed/remediation-$(date +%Y%m%d-%H%M%S).log
            ansible-playbook -i inventory/hosts playbooks/audit.yml | tee logs/audit/audit-$(date +%Y%m%d-%H%M%S).log
            grep "^\[" logs/audit/audit-20250828-114857.log < mostrar ou contar os resultados do log
            # Extrair somente resultados de aprovação/reprovação
            grep -E "^\[|APROVADO|REPROVADO" logs/audit/audit-* | tee logs/audit/audit-result-$(date +%Y%m%d-%H%M%S).log ;
            # Comparar resultados entre hosts
            diff logs/audit/audit-1-result.log logs/audit/audit-2-result.log | tee logs/audit/audit-diff-hrdXfail.log
            
## 🔧 Debug para Auditoria ou Remediação
Adicione uma tarefa temporária no playbook:
```yml
- name: "Exibir resultado detalhado do audit Hitss XX"
  debug:
    msg: "{{ audit_6332_result.stdout_lines }}"
  when: audit_6332_result.stdout is search('REPROVADO')
```
Ou ajuste o ansible.cfg para mais verbosidade:
```ini
[defaults]
stdout_callback = yaml
```
---
