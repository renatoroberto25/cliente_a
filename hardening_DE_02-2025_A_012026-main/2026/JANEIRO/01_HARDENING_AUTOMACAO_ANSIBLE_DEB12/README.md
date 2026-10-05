.
├── inventory/        # Arquivos de inventário Ansible (hosts)
├── logs/             # Logs gerados durante auditorias e remediações
│   ├── audit/        # Logs das auditorias
│   └── remed/        # Logs das remediações
├── playbooks/        # Playbooks principais
│   ├── audit.yml     # Orquestra auditorias
│   └── remed.yml     # Orquestra remediações
├── roles/            # Roles Ansible (audit e remed)
├── ansible.cfg       # Configuração mínima do Ansible
├── README.md         # Documentação do projeto
└── TODO              # Lista de tarefas pendentes

Execução Auditoria:
ansible-playbook -i inventory/hosts playbooks/audit.yml \
  --tags "audit_hitss_11.x,audit_hitss_12.x" -l debian12-fail \
  | tee logs/audit/audit-$(date +%Y%m%d-%H%M%S).log

Filtrar resultados:
grep -E "^[|APROVADO|REPROVADO" logs/audit/audit-* \
  | tee logs/audit/audit-hrd-result-$(date +%Y%m%d-%H%M%S).log

Execução Remediação:
ansible-playbook -i inventory/hosts playbooks/remed.yml \
  --tags "remed_hitss_11.x,remed_hitss_12.x" -l debian12-fail \
  | tee logs/remed/remed-$(date +%Y%m%d-%H%M%S).log

Instalação Tenable Agent:
curl -H 'X-Key: KEY_SOLICITAR' \
"https://sensor.cloud.tenable.com/install/agent?name='$(hostname)'&groups=GRUPO_SE_EXISTIR" | bash