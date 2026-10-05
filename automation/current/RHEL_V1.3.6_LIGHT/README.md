# Hardening HITSS LIGHT para RHEL 7, 8 e 9

Escopo definido pelos 122 IDs de `baseline_rhel_light_resumido.csv`, copiado de `baselines/` na raiz do projeto. Foram retirados do audit e das remediações os IDs fora desse conjunto, sem reformular os controles mantidos.

O audit original tinha 174 IDs, mas um conjunto diferente da planilha FULL: foram removidos 60 e restaram 114. Os IDs 59, 60, 100, 101, 124, 163, 165 e 172 constam no LIGHT e já estavam ausentes do audit original. A filtragem não implementa controles ausentes nem transforma remediações `SKIP` em correções automáticas.

Divergências herdadas que permanecem após o filtro:

| ID | Baseline LIGHT | Automação existente |
|---|---|---|
| 15 | SUID dump off | ptrace_scope |
| 18 | ASLR completo | IOMMU, inclusive alteração de boot via grubby |
| 21 | dmesg restrito | User namespace |
| 24 | Hardlinks protegidos | suid_dumpable |
| 111 | SyslogFacility AUTHPRIV | Audit verifica LogLevel; remediação configura ambos |
| 196 | Sticky bit em diretórios world writable | Audit verifica arquivos e diretórios world writable fora de temporários |

Essas divergências impedem afirmar aderência integral à planilha apenas pela coincidência dos IDs. Permanecem para uma revisão separada. Os arquivos FULL/Tenable e CSVs antigos presentes nesta pasta são referências herdadas e não definem o escopo dos scripts LIGHT.

A retirada de código não desfaz configurações FULL já aplicadas em servidores.

## Mapeamento do escopo LIGHT

Mapeamento estático do código, sem executar audit ou remediação. A manutenção desta versão consiste somente em retirar excedentes. Ausências anteriores ficam documentadas, sem criar novas implementações.

- Baseline: **122 IDs**.
- Audit: **114 IDs presentes**; ausentes: **59, 60, 100, 101, 124, 163, 165, 172**.
- Remediação: **114 IDs com ação, verificação ou mensagem explícita**; sem implementação específica: **100, 101, 124, 131, 133, 163, 165, 172**.
- Os IDs **131 e 133** aparecem somente na faixa do cabeçalho `[130-134]`; isso não implementa seus requisitos. O **172** também aparece somente na faixa do cabeçalho das regras auditd, sem regra SELinux correspondente.
- Foram excluídos integralmente `02_filesystem.sh` e `12_crypto_policy.sh`, pois seus controles ficaram fora do LIGHT.

“Presente” indica uma chamada no audit; “Ação existente” indica código de alteração na remediação, sujeito às condições do script. Não significam equivalência integral ao baseline nem homologação. `SKIP`, verificações e mensagens `INFO` não são remediação automática. As divergências herdadas estão descritas acima.

| ID | Controle do baseline | Audit | Remediação | Arquivo em REMED_SH |
|---|---|---|---|---|
| 1 | Bloqueio cramfs | Presente | Ação existente | 01_kernel.sh |
| 4 | Bloqueio hfs | Presente | Ação existente | 01_kernel.sh |
| 5 | Bloqueio hfsplus | Presente | Ação existente | 01_kernel.sh |
| 6 | Bloqueio jffs2 | Presente | Ação existente | 01_kernel.sh |
| 7 | Bloqueio freevxfs | Presente | Ação existente | 01_kernel.sh |
| 10 | Bloqueio DCCP | Presente | Ação existente | 01_kernel.sh |
| 12 | Bloqueio RDS | Presente | Ação existente | 01_kernel.sh |
| 13 | Bloqueio TIPC | Presente | Ação existente | 01_kernel.sh |
| 14 | Core dumps restritos | Presente | Ação existente | 01_kernel.sh |
| 15 | SUID dump off | Presente | Ação existente | 01_kernel.sh |
| 16 | NX/XD ativo | Presente | SKIP | 01_kernel.sh |
| 17 | ASLR habilitado | Presente | Ação existente | 01_kernel.sh |
| 18 | ASLR completo | Presente | Ação existente | 01_kernel.sh |
| 21 | dmesg restrito | Presente | SKIP | 01_kernel.sh |
| 22 | Symlinks protegidos | Presente | Ação existente | 01_kernel.sh |
| 24 | Hardlinks protegidos | Presente | Ação existente | 01_kernel.sh |
| 44 | Sticky world-writable | Presente | Ação existente | 04_system.sh |
| 45 | Sticky /tmp | Presente | Ação existente | 04_system.sh |
| 46 | Sticky /var/tmp | Presente | Ação existente | 04_system.sh |
| 47 | Sticky /dev/shm | Presente | Ação existente | 04_system.sh |
| 50 | Permissões seguras no arquivo do bootloader | Presente | Ação existente | 03_boot.sh |
| 51 | Single user mode com autenticação | Presente | Verificação / SKIP | 03_boot.sh |
| 56 | Prelink removido | Presente | Verificação / SKIP | 05_legacy_software.sh |
| 57 | xinetd removido | Presente | Verificação / SKIP | 05_legacy_software.sh |
| 58 | Time sync ativo | Presente | Verificação / SKIP | 06_time_sync.sh |
| 59 | Fontes NTP confiáveis | Ausente | Verificação / SKIP | 06_time_sync.sh |
| 60 | NTP desde o boot | Ausente | Verificação / SKIP | 06_time_sync.sh |
| 73 | Servidor NIS removido | Presente | Verificação / SKIP | 07_services.sh |
| 74 | Servidor Telnet removido | Presente | Verificação / SKIP | 07_services.sh |
| 75 | MTA local only | Presente | Verificação / SKIP | 07_services.sh |
| 79 | Cliente NIS removido | Presente | Verificação / SKIP | 07_services.sh |
| 80 | Cliente rsh removido | Presente | Verificação / SKIP | 07_services.sh |
| 81 | Cliente talk removido | Presente | Verificação / SKIP | 07_services.sh |
| 82 | Cliente telnet removido | Presente | Verificação / SKIP | 07_services.sh |
| 85 | Servidor TFTP removido | Presente | Verificação / SKIP | 07_services.sh |
| 86 | PolicyKit endurecido | Presente | Verificação / SKIP | 07_services.sh |
| 87 | GPG check habilitado | Presente | Ação existente | 08_package_integrity.sh |
| 89 | Sincronização de tempo única | Presente | SKIP | 09_access_scheduling.sh |
| 90 | Cron e at restritos | Presente | Ação existente | 09_access_scheduling.sh |
| 92 | Redirects desabilitados | Presente | Ação existente | 10_network.sh |
| 93 | Source-route bloqueado | Presente | Ação existente | 10_network.sh |
| 94 | ICMP redirects desabilitados | Presente | Ação existente | 10_network.sh |
| 96 | Broadcast ICMP ignorado | Presente | Ação existente | 10_network.sh |
| 97 | ICMP bogus responses ignorado | Presente | Ação existente | 10_network.sh |
| 98 | TCP syncookies habilitado | Presente | Ação existente | 10_network.sh |
| 100 | ICMP timestamp request bloqueado | Ausente | Ausente | — |
| 101 | ICMP timestamp reply bloqueado | Ausente | Ausente | — |
| 102 | Wireless e bluetooth ausentes | Presente | Ação existente | 11_wireless.sh |
| 109 | Permissões do SSH | Presente | Ação existente | 13_ssh.sh |
| 111 | SyslogFacility AUTHPRIV | Presente | Ação existente | 13_ssh.sh |
| 113 | MaxAuthTries restritivo | Presente | Ação existente | 13_ssh.sh |
| 114 | IgnoreRhosts habilitado | Presente | Ação existente | 13_ssh.sh |
| 115 | HostbasedAuthentication desabilitado | Presente | Ação existente | 13_ssh.sh |
| 117 | PermitEmptyPasswords desabilitado | Presente | Ação existente | 13_ssh.sh |
| 118 | PermitUserEnvironment desabilitado | Presente | Ação existente | 13_ssh.sh |
| 119 | UsePAM habilitado | Presente | Ação existente | 13_ssh.sh |
| 120 | ClientAlive configurado | Presente | Ação existente | 13_ssh.sh |
| 121 | LoginGraceTime restrito | Presente | Ação existente | 13_ssh.sh |
| 122 | MaxStartups restrito | Presente | Ação existente | 13_ssh.sh |
| 124 | Banner legal | Ausente | Ausente | — |
| 130 | PAM complexidade | Presente | Verificação / SKIP | 14_auth_policy.sh |
| 131 | pwquality configurado | Presente | Ausente | — |
| 132 | pam_faillock habilitado | Presente | Verificação / SKIP | 14_auth_policy.sh |
| 133 | pam_tally2 inexistente | Presente | Ausente | — |
| 134 | pwhistory configurado | Presente | Verificação / SKIP | 14_auth_policy.sh |
| 135 | Senha mínima | Presente | Ação existente | 14_auth_policy.sh |
| 136 | Complexidade mínima | Presente | Ação existente | 14_auth_policy.sh |
| 137 | Sem repetição/sequência | Presente | Ação existente | 14_auth_policy.sh |
| 138 | Dicionário ativo | Presente | Ação existente | 14_auth_policy.sh |
| 139 | Hash forte | Presente | Ação existente | 14_auth_policy.sh |
| 140 | Histórico de senhas | Presente | INFO; não aplica remember | 14_auth_policy.sh |
| 142 | Tempo desbloqueio | Presente | Ação existente | 14_auth_policy.sh |
| 143 | PASS_MAX_DAYS | Presente | Ação existente | 14_auth_policy.sh |
| 144 | PASS_MIN_DAYS | Presente | Ação existente | 14_auth_policy.sh |
| 145 | PASS_WARN_AGE | Presente | Ação existente | 14_auth_policy.sh |
| 146 | INACTIVE configurado | Presente | Ação existente | 14_auth_policy.sh |
| 147 | Datas de senha consistentes | Presente | SKIP | 14_auth_policy.sh |
| 148 | Apenas root com UID 0 | Presente | SKIP | 15_accounts_shell_sudo.sh |
| 149 | Apenas grupo root com GID 0 | Presente | SKIP | 15_accounts_shell_sudo.sh |
| 150 | Contas de sistema com shell inválido bloqueadas | Presente | SKIP | 15_accounts_shell_sudo.sh |
| 151 | /etc/shells validado | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 152 | PATH do root sem diretório inseguro | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 153 | Umask padrão restritiva | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 154 | Timeout de shell | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 155 | Administração privilegiada via sudo restrita | Presente | INFO; preserva delegações | 15_accounts_shell_sudo.sh |
| 156 | Sudo com pseudo tty | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 157 | Logging de sudo habilitado | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 159 | Timeout de autenticação sudo | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 162 | Journald persistente | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 163 | Rsyslog habilitado | Ausente | Ausente | — |
| 164 | Rotação de logs configurada | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 165 | auditd habilitado | Ausente | Ausente | — |
| 166 | auditd antes de serviços críticos | Presente | SKIP | 16_logging_audit_integrity.sh |
| 167 | max_log_file configurado | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 169 | Auditoria de data e hora | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 170 | Auditoria de contas e grupos | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 171 | Auditoria de rede | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 172 | Auditoria de eventos SELinux | Ausente | Ausente | — |
| 173 | Auditoria de login | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 174 | Auditoria de permissões | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 175 | Auditoria de EACCES e EPERM | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 177 | Auditoria de mount | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 178 | Auditoria de unlink e rename | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 179 | Auditoria de módulos kernel | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 180 | Auditoria de sudo e sudoers | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 185 | Permissões de /etc/passwd | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 186 | Permissões de /etc/passwd- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 187 | Permissões de /etc/shadow | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 188 | Permissões de /etc/shadow- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 189 | Permissões de /etc/gshadow- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 190 | Permissões de /etc/gshadow | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 191 | Permissões de /etc/group | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 192 | Permissões de /etc/group- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 194 | Proteção de /etc/security/opasswd | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 195 | Arquivos órfãos inexistentes | Presente | SKIP | 18_home_file_hygiene.sh |
| 196 | Sticky bit em diretórios world writable | Presente | Ação existente | 18_home_file_hygiene.sh |
| 197 | Sem arquivos sem owner ou grupo | Presente | SKIP | 18_home_file_hygiene.sh |
| 199 | Usuários sem home inexistentes | Presente | SKIP | 18_home_file_hygiene.sh |
| 200 | Ownership correto dos homes | Presente | SKIP | 18_home_file_hygiene.sh |
| 201 | Permissões de home restritivas | Presente | SKIP | 18_home_file_hygiene.sh |
| 202 | Dotfiles sem permissão world writable | Presente | SKIP | 18_home_file_hygiene.sh |
| 203 | Sem arquivos .forward .netrc e .rhosts | Presente | Verificação / SKIP | 18_home_file_hygiene.sh |

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

## Audit Tenable LIGHT

Arquivo: `audits/COMPLIANCE_SENSORES_RHEL7-9_LIGHT_PRE_V1.3.5_110820261048.audit`, na raiz do projeto.

Derivado do `COMPLIANCE_SENSORES_RHEL7-9_FULL_PRE_V1.3.5_110820261048.audit` somente por retirada de `custom_item`: 52 controles excluídos do baseline e o utilitário 999, que não pertence aos 122 IDs LIGHT. Os 122 blocos restantes foram preservados literalmente. A versão e o timestamp no nome foram herdados do arquivo de origem.

O `.audit` contém os 122 IDs do baseline. O `AUDIT_SH/audit.sh` contém 114 desses IDs, sem excedentes; os 8 já ausentes e as divergências anteriores permanecem mapeados neste README. Os comandos do `.audit` e do shell não foram reescritos nem equiparados nesta etapa.
