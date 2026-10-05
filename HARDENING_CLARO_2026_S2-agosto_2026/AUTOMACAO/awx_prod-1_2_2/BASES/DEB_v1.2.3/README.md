# Hardening HITSS — Debian-like v1.0.3

Automação de auditoria e remediação dos 158 controles do baseline Debian-like. Destinada a Debian 11 ou superior e Ubuntu compatível.

## Requisitos

- Bash, systemd, dpkg/APT e utilitários padrão do sistema;
- execução como `root` para remediação, fluxo completo e rollback;
- janela de mudança, acesso administrativo alternativo e backup externo recomendado.

## Uso

```bash
./executor.sh                              # menu interativo
./executor.sh precheck full                # valida prontidão
./executor.sh audit                        # somente auditoria
./executor.sh remed                        # backup e remediação
./executor.sh full                         # fluxo completo
./executor.sh report                       # falhas do último audit
./executor.sh status                       # resumo do último audit
./executor.sh backups                      # lista backups
./executor.sh rollback [ID|latest]         # restaura uma execução
```

O modo `full` executa:

```text
Pre-check → Audit pré → Backup → Remediação → Audit pós → Relatório
```

O pre-check valida sistema e versão, privilégios, sintaxe dos scripts, comandos obrigatórios, espaço livre, SSH e sudoers. As operações de alteração usam lock exclusivo.

## Resultados

```text
logs/audit/                 audits pré, pós e avulsos
logs/remed/                 execução dos remediadores
logs/reports/<RUN_ID>/      comparison.csv, summary.csv e precheck.csv
/var/backups/hitss-hardening/  backups transacionais
```

O relatório compara cada controle por ID e classifica a transição como `FIXED`, `UNCHANGED`, `REGRESSION` ou `ERROR`. O status final pode ser `SUCCESS`, `PARTIAL` ou `FAILED`.

## Rollback

Cada remediação registra o estado anterior de arquivos, metadados, sysctl, unidades systemd e pacotes. O rollback ocorre em ordem inversa e mantém o backup para auditoria.

A reinstalação de pacotes depende dos repositórios APT. Mudanças que dependem de boot ou validação operacional podem exigir reinicialização e novo audit.

Remoção de pacotes é bloqueada por padrão:

```bash
REMED_ALLOW_PACKAGE_REMOVAL=1 ./executor.sh remed
```

A restrição de `su` exige grupo aprovado:

```bash
REMED_SU_GROUP=sudo ./executor.sh remed
```

Controles dependentes do papel do servidor, allowlists ou decisão arquitetural retornam `SKIP`.
