# HITSS AWX 1.2.2

Hardening Ansible baseado na arquitetura do `awx_prod-1_2_0`, atualizado com
o conteúdo técnico das automações mais recentes em `BASES/DEB_v1.2.3` e
`BASES/RHEL_V1.3.6`.

## Princípio do projeto

Os shellscripts em `BASES` são a fonte técnica usada na construção. Eles não
são copiados para o host e nenhum `executor.sh` é chamado. O AWX executa os
controles por meio dos roles e tasks deste projeto.

```text
Gather facts
  -> common detecta Debian ou RedHat
  -> seleciona DEB v1.2.3 ou RHEL v1.3.6
  -> audit executa somente as regras daquela família
  -> remediation, em playbook separado, carrega os 18 grupos daquela família
```

## Baselines

| Família | Fonte técnica | Catálogo | Regras de audit |
| --- | --- | --- | ---: |
| DEB-like | `BASES/DEB_v1.2.3` | `catalogs/baseline_deb.csv` | 158 |
| RHEL-like | `BASES/RHEL_V1.3.6` | `catalogs/baseline_rhel.csv` | 174 |

Os IDs e suas lacunas são preservados; não há renumeração artificial.

## Pipeline de auditoria

```bash
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml
```

1. coleta facts;
2. `roles/common` valida e classifica a família;
3. `roles/audit` carrega `rules/deb.yml` ou `rules/rhel.yml`;
4. cada ID executa seu comando de validação sem marcar mudança;
5. a saída é comparada à expressão esperada;
6. o Job Output mostra APROVADO/REPROVADO por ID e o resumo.

O audit não inclui o role de remediação, não copia scripts e não altera
parâmetros de hardening. Apenas o `post_task` registra a execução em
`/var/log/hitss-hardening.log`.

Por família ou host:

```bash
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml --limit deb_like
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml --limit rhel_like
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml --limit rhel9-lab
```

## Pipeline de remediação

```bash
ansible-playbook -i inventories/prod/hosts playbooks/remediation.yml \
  -e hitss_remediation_confirm=true
```

A remediação é bloqueada sem confirmação explícita, usa `serial: 1`, detecta
a família e inclui somente os 18 grupos correspondentes. Ela altera o host;
revise variáveis, exceções e janela antes do uso em produção.

## Pipeline completo

```bash
ansible-playbook -i inventories/prod/hosts playbooks/full.yml \
  -e hitss_remediation_confirm=true
```

Ordem: audit inicial, remediação e audit final. Sem a confirmação, para antes
de qualquer remediação.

## Estrutura relevante

```text
playbooks/audit.yml                 entrada somente de auditoria
playbooks/remediation.yml           entrada de mudança protegida
playbooks/full.yml                  audit -> remediation -> audit
roles/common/tasks/main.yml         seleção da família/baseline
roles/audit/tasks/family.yml        executor Ansible dos controles
roles/audit/rules/deb.yml           158 regras DEB
roles/audit/rules/rhel.yml          174 regras RHEL
roles/remediation/tasks/deb/        18 grupos DEB
roles/remediation/tasks/rhel/       18 grupos RHEL
catalogs/                           rastreabilidade dos IDs
BASES/                              fontes usadas na engenharia reversa
IAC/Vagrantfile                     laboratório .11 RHEL e .12 DEB
```

`playbooks/tenable_agent.yml` é independente do hardening.

## Testes locais sem aplicar hardening

Conectividade:

```bash
ansible -i inventories/prod/hosts hardening_lab -m ansible.builtin.ping
```

Validação estática, sem conectar às VMs:

```bash
python3 tools/validate_project.py
ansible-playbook -i inventories/prod/hosts playbooks/audit.yml --syntax-check
ansible-playbook -i inventories/prod/hosts playbooks/remediation.yml --syntax-check
ansible-playbook -i inventories/prod/hosts playbooks/full.yml --syntax-check
```
