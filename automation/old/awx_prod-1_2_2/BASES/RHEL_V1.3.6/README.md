# Hardening HITSS para RHEL 7, 8 e 9

Auditoria e remediação dos 174 controles do baseline RHEL 1.3.5. Suporta RHEL e derivados homologados, incluindo Oracle Linux.

## Antes de executar
- Mantenha acesso administrativo alternativo ao servidor.
- Faça backup externo dos dados e das configurações críticas.
- Execute como `root` para remediar, executar o fluxo completo ou restaurar um snapshot.

O processo pode alterar configurações de boot, kernel, rede, SSH, PAM, sudo, logs, auditoria e permissões. Controles que dependem do papel do servidor ou de uma decisão do ambiente são marcados como `SKIP`.

## Execução

```bash
./executor.sh                         # menu interativo
./executor.sh precheck full           # valida o ambiente
./executor.sh audit                   # executa somente a auditoria
./executor.sh remed                   # cria snapshot e remedia
./executor.sh full                    # executa o fluxo completo
./executor.sh report                  # lista falhas do último audit
./executor.sh status                  # resume o último audit
./executor.sh rollback [snapshot]     # restaura o snapshot informado ou o mais recente
```

O modo `full` executa:

```text
Pre-check -> Audit inicial -> Snapshot -> Remediação -> Audit final -> Relatório
```

## Saídas

```text
logs/audit/                 resultados das auditorias
logs/remed/                 logs de remediação
logs/backups/               snapshots e manifestos
logs/reports/<RUN_ID>/      relatório consolidado do fluxo completo
```

No comparativo por controle, as transições são `FIXED`, `UNCHANGED`, `REGRESSION` ou `ERROR`. O resultado geral é `SUCCESS`, `PARTIAL` ou `FAILED`.

## Rollback

O snapshot inclui os arquivos gerenciados, repositórios YUM/DNF e entradas BLS em `/boot/loader/entries`. O rollback restaura arquivos alterados e remove os arquivos que a automação criou.

Mudanças já carregadas no kernel, em `sysctl` ou no `auditd` podem exigir reload ou reinicialização. Após restaurar parâmetros de boot, reinicie o servidor e execute uma nova auditoria.
