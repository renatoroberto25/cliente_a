# Hardening HITSS — Debian-like v1.2.3 LIGHT

Versão reduzida por retirada de itens, sem renumerar ou reformular os controles mantidos. Fonte: `baselines/02_Hardening_2026_DEB_LIKE_PADRAO_FULL.xlsx`, na raiz do projeto. O ID corresponde à coluna **Tópico** da planilha DEB; não usar a numeração RHEL.

## Escopo

- FULL: **168 controles**. LIGHT: **118 controles**. Retirados: **50 (29,8%)**.
- Os **26 controles já marcados Light** na planilha foram preservados. Os demais foram selecionados pelo mesmo critério operacional do LIGHT RHEL, mantendo a redução entre 20% e 30%; não foi aplicado um filtro exclusivo da coluna Perfil.
- Referência local: `baseline_deb_light_resumido.csv`, cópia do CSV em `baselines/`.
- Lista para exclusão no Jira e motivos: `baselines/baseline_deb_light_excluir_jira.csv`.
- Retirados controles de particionamento/montagem, bloqueios de componentes dependentes do ambiente, remoção de serviços de aplicação, restrições de acesso dependentes da operação e auditoria/integridade mais exigentes.
- A referência Claro TI é específica de RHEL: não foram transpostos comandos RPM, authselect ou valores do cliente para Debian. A retirada do ID 96 segue o critério de compatibilidade do acesso administrativo; não determina que login root seja habilitado.

## Cobertura e ausências anteriores

Audit e remediação tinham **158 IDs cada**. Foram retirados **50** de cada conjunto, restando **108 IDs em cada**.

Os IDs **1, 80, 106, 107, 108, 109, 110, 114, 115 e 130** pertencem ao LIGHT, mas já estavam ausentes tanto do audit quanto da remediação. Permanecem documentados; nenhuma implementação nova foi criada.

Foi excluído `02_filesystem.sh`, cujo conteúdo inteiro excedia o LIGHT. Os grupos `09_access_scheduling.sh` e `12_crypto_policy.sh` já estavam vazios e também foram retirados. O executor percorre os scripts existentes, sem lista fixa desses arquivos.

O mapeamento abaixo resulta da leitura estática do código. “Presente” significa chamada existente no audit; “Ação existente” indica código de alteração sujeito às condições do script. `MANUAL`, `SKIP` e verificações não são correções automáticas. Presença não comprova conformidade nem homologação.

## Particularidades herdadas

Mantidas sem reformulação durante a retirada de excedentes:

- **76:** os scripts denominam o controle “PolicyKit sem autorizações locais irrestritas”; a remediação é manual.
- **83:** os scripts tratam redirects em `all` e interfaces ativas, preservando os valores `default` para revisão.
- **100:** o audit verifica `ClientAliveInterval` e `ClientAliveCountMax`; a remediação configura apenas o intervalo.
- **113:** a chamada de remediação para hash forte retorna `SKIP`.
- **167:** a remediação aplica `go-rwx`, mais restritivo que a máscara `0027` verificada pelo audit.
- Alguns audits possuem condições repetidas e aceitam `NA` como resultado conforme. Esses comportamentos anteriores foram preservados.

A retirada de código não desfaz configurações já aplicadas em servidores.

## Mapeamento completo

| ID | Controle do baseline | Audit | Remediação | Arquivo em REMED_SH |
|---|---|---|---|---|
| 1 | Bloqueio cramfs | Ausente | Ausente | — |
| 4 | Bloqueio hfs | Presente | Ação existente | 01_kernel.sh |
| 5 | Bloqueio hfsplus | Presente | Ação existente | 01_kernel.sh |
| 6 | Bloqueio jffs2 | Presente | Ação existente | 01_kernel.sh |
| 7 | Bloqueio freevxfs | Presente | Ação existente | 01_kernel.sh |
| 10 | Bloqueio DCCP | Presente | Ação existente | 01_kernel.sh |
| 12 | Bloqueio RDS | Presente | Ação existente | 01_kernel.sh |
| 13 | Bloqueio TIPC | Presente | Ação existente | 01_kernel.sh |
| 14 | Core dumps restritos | Presente | Ação existente | 01_kernel.sh |
| 15 | SUID dump off | Presente | Ação existente | 01_kernel.sh |
| 16 | NX/XD ativo | Presente | MANUAL | 01_kernel.sh |
| 17 | ASLR habilitado | Presente | Ação existente | 01_kernel.sh |
| 18 | ASLR completo | Presente | Ação existente | 01_kernel.sh |
| 20 | dmesg restrito | Presente | Ação existente | 01_kernel.sh |
| 21 | Symlinks protegidos | Presente | Ação existente | 01_kernel.sh |
| 22 | Hardlinks protegidos | Presente | Ação existente | 01_kernel.sh |
| 38 | Sticky world-writable | Presente | MANUAL | 04_system.sh |
| 39 | Sticky /tmp | Presente | Ação existente | 04_system.sh |
| 40 | Sticky /var/tmp | Presente | Ação existente | 04_system.sh |
| 41 | Sticky /dev/shm | Presente | Ação existente | 04_system.sh |
| 44 | Permissões seguras no arquivo do bootloader | Presente | Ação existente | 03_boot.sh |
| 45 | Single user mode com autenticação | Presente | MANUAL | 03_boot.sh |
| 46 | Prelink removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 05_legacy_software.sh |
| 47 | xinetd removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 05_legacy_software.sh |
| 48 | Time sync ativo | Presente | Ação existente | 06_time_sync.sh |
| 49 | Fontes NTP confiáveis | Presente | MANUAL | 06_time_sync.sh |
| 50 | NTP desde o boot | Presente | Ação existente | 06_time_sync.sh |
| 63 | Servidor NIS removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 64 | Servidor Telnet removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 65 | MTA local only | Presente | MANUAL | 07_services.sh |
| 69 | Cliente NIS removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 70 | Cliente rsh removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 71 | Cliente talk removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 72 | Cliente telnet removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 75 | Servidor TFTP removido | Presente | Ação condicionada a REMED_ALLOW_PACKAGE_REMOVAL | 07_services.sh |
| 76 | PolicyKit endurecido | Presente | MANUAL | 07_services.sh |
| 77 | Assinaturas dos repositórios APT verificadas | Presente | MANUAL | 08_package_integrity.sh |
| 78 | Atualizações de segurança aplicadas | Presente | MANUAL | 08_package_integrity.sh |
| 79 | Sincronização de tempo única | Presente | Verificação / SKIP | 06_time_sync.sh |
| 80 | Cron e at restritos | Ausente | Ausente | — |
| 81 | Redirects desabilitados | Presente | Ação existente | 10_network.sh |
| 82 | Source-route bloqueado | Presente | Ação existente | 10_network.sh |
| 83 | ICMP redirects desabilitados | Presente | Ação existente | 10_network.sh |
| 85 | Broadcast ICMP ignorado | Presente | Ação existente | 10_network.sh |
| 86 | ICMP bogus responses ignorado | Presente | Ação existente | 10_network.sh |
| 87 | TCP syncookies habilitado | Presente | Ação existente | 10_network.sh |
| 89 | Wireless e bluetooth ausentes | Presente | Ação existente | 11_wireless.sh |
| 90 | Permissões do SSH | Presente | Ação existente | 13_ssh.sh |
| 91 | SyslogFacility do SSH seguro | Presente | Ação existente | 13_ssh.sh |
| 93 | MaxAuthTries restritivo | Presente | Ação existente | 13_ssh.sh |
| 94 | IgnoreRhosts habilitado | Presente | Ação existente | 13_ssh.sh |
| 95 | HostbasedAuthentication desabilitado | Presente | Ação existente | 13_ssh.sh |
| 97 | PermitEmptyPasswords desabilitado | Presente | Ação existente | 13_ssh.sh |
| 98 | PermitUserEnvironment desabilitado | Presente | Ação existente | 13_ssh.sh |
| 99 | UsePAM habilitado | Presente | Ação existente | 13_ssh.sh |
| 100 | ClientAlive configurado | Presente | Ação existente | 13_ssh.sh |
| 101 | LoginGraceTime restrito | Presente | Ação existente | 13_ssh.sh |
| 102 | MaxStartups restrito | Presente | Ação existente | 13_ssh.sh |
| 105 | PAM complexidade | Presente | MANUAL | 14_auth_policy.sh |
| 106 | pwquality configurado | Ausente | Ausente | — |
| 107 | pam_faillock habilitado | Ausente | Ausente | — |
| 108 | pwhistory configurado | Ausente | Ausente | — |
| 109 | Senha mínima | Ausente | Ausente | — |
| 110 | Complexidade mínima | Ausente | Ausente | — |
| 111 | Sem repetição/sequência | Presente | Ação existente | 14_auth_policy.sh |
| 112 | Dicionário ativo | Presente | Ação existente | 14_auth_policy.sh |
| 113 | Hash forte | Presente | SKIP | 14_auth_policy.sh |
| 114 | Histórico de senhas | Ausente | Ausente | — |
| 115 | Tempo desbloqueio | Ausente | Ausente | — |
| 116 | PASS_MAX_DAYS | Presente | Ação existente | 14_auth_policy.sh |
| 117 | PASS_MIN_DAYS | Presente | Ação existente | 14_auth_policy.sh |
| 118 | PASS_WARN_AGE | Presente | Ação existente | 14_auth_policy.sh |
| 119 | INACTIVE configurado | Presente | Ação existente | 14_auth_policy.sh |
| 120 | Datas de senha consistentes | Presente | MANUAL | 14_auth_policy.sh |
| 121 | Apenas root com UID 0 | Presente | MANUAL | 15_accounts_shell_sudo.sh |
| 122 | Apenas grupo root com GID 0 | Presente | MANUAL | 15_accounts_shell_sudo.sh |
| 123 | Contas de sistema com shell inválido bloqueadas | Presente | MANUAL | 15_accounts_shell_sudo.sh |
| 124 | /etc/shells validado | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 125 | PATH do root sem diretório inseguro | Presente | MANUAL | 15_accounts_shell_sudo.sh |
| 126 | Umask padrão restritiva | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 127 | Timeout de shell | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 128 | Administração privilegiada via sudo restrita | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 129 | Sudo com pseudo-TTY | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 130 | Logging de sudo habilitado | Ausente | Ausente | — |
| 131 | Timeout de autenticação sudo | Presente | Ação existente | 15_accounts_shell_sudo.sh |
| 133 | Journald persistente | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 134 | Rsyslog habilitado | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 135 | Rotação de logs configurada | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 136 | auditd habilitado | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 137 | Auditoria habilitada desde o boot | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 138 | max_log_file configurado | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 139 | Auditoria de data e hora | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 140 | Auditoria de contas e grupos | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 141 | Auditoria de rede | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 142 | Auditoria de login | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 143 | Auditoria de permissões | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 144 | Auditoria de EACCES e EPERM | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 146 | Auditoria de mount | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 147 | Auditoria de unlink e rename | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 148 | Auditoria de módulos kernel | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 149 | Auditoria de sudo e sudoers | Presente | Ação existente | 16_logging_audit_integrity.sh |
| 152 | Permissões de /etc/passwd | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 153 | Permissões de /etc/passwd- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 154 | Permissões de /etc/shadow | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 155 | Permissões de /etc/shadow- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 156 | Permissões de /etc/gshadow- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 157 | Permissões de /etc/gshadow | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 158 | Permissões de /etc/group | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 159 | Permissões de /etc/group- | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 160 | Proteção de /etc/security/opasswd | Presente | Ação existente | 17_sensitive_file_permissions.sh |
| 161 | Arquivos órfãos inexistentes | Presente | SKIP | 18_home_file_hygiene.sh |
| 162 | Sticky bit em diretórios world writable | Presente | Ação existente | 18_home_file_hygiene.sh |
| 163 | Sem arquivos sem owner ou grupo | Presente | SKIP | 18_home_file_hygiene.sh |
| 165 | Usuários sem home inexistentes | Presente | SKIP | 18_home_file_hygiene.sh |
| 166 | Ownership correto dos homes | Presente | Ação existente | 18_home_file_hygiene.sh |
| 167 | Permissões de home restritivas | Presente | Ação existente | 18_home_file_hygiene.sh |
| 168 | Dotfiles sem permissão world writable | Presente | Ação existente | 18_home_file_hygiene.sh |
| 169 | Sem arquivos .forward .netrc e .rhosts | Presente | SKIP | 18_home_file_hygiene.sh |

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

Controles dependentes do papel do servidor, allowlists ou decisão arquitetural retornam `SKIP`.

## Audit Tenable LIGHT

Arquivo: `audits/COMPLIANCE_SENSORES_DEB_LIGHT_PRE_V1.2.2_110820261048.audit`, na raiz do projeto.

Origem: `COMPLIANCE_SENSORES_DEB_FULL_PRE_V1.2.2_110820261048.audit`. Este arquivo contém os 168 IDs e nomes do baseline FULL, além do controle 104 e do utilitário 999.

A versão LIGHT foi criada somente retirando `custom_item`: os 50 controles da lista de exclusão, o ID 104 (ausente do baseline atual) e o utilitário 999. Os 118 blocos mantidos foram preservados literalmente. A versão e o timestamp do nome são herdados da origem.

O `.audit` cobre os 118 IDs do baseline LIGHT. O `AUDIT_SH/audit.sh` possui 108 desses IDs, sem excedentes. As 10 ausências anteriores do shell estão mapeadas neste README. Os comandos das duas implementações não foram reescritos nem equiparados nesta etapa. Validação por leitura e comparação de blocos, sem executar o audit.
