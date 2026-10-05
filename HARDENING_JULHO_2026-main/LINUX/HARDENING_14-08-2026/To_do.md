Questões por arquivo
Arquivo	Avaliação
executor.sh	Estrutura razoável, mas não exige root, não usa lock e pode sobrescrever logs com o mesmo timestamp da sessão.
audit.sh	Sintaxe válida; possui falsos positivos, verificações parciais e um erro lógico confirmado no item 147.
01_kernel.sh	Bloqueio de overlay e mudança de boot/IOMMU exigem validação por perfil. Item perf_event aparece duplicado.
02_filesystem.sh	Alteração de fstab e noexec em /var são de alto risco.
03_boot.sh	Conservador; caminho do GRUB não cobre todas as variantes BIOS/UEFI.
04_system.sh	Sticky bit global pode alterar diretórios de aplicações sem análise.
05_legacy_software.sh	Baixo risco; apenas informa e não remove.
06_time_sync.sh	Baixo risco; apenas avalia, mas não resolve as falhas.
07_services.sh	Conservador; detecção de PolicyKit por texto pode gerar falsos positivos.
08_package_integrity.sh	Pode adicionar gpgcheck=1 fora da seção correta de um .repo.
09_access_scheduling.sh	Criar cron.allow somente com root bloqueia cron para todos os demais usuários.
10_network.sh	Pode quebrar roteadores, VPNs, hosts multihomed e redes assimétricas.
11_wireless.sh	Descarrega módulos em runtime; risco de perda de conectividade.
12_crypto_policy.sh	Conservador; não altera a política automaticamente.
13_ssh.sh	Alto risco de lockout; reload não está condicionado à validação.
14_auth_policy.sh	Crítico; edição PAM manual e fora do fluxo recomendado do RHEL.
15_accounts_shell_sudo.sh	Crítico; altera shells e adiciona requiretty; contradiz o audit.
16_logging_audit_integrity.sh	Torna audit imutável e cria regra de execve potencialmente muito volumosa.
17_sensitive_file_permissions.sh	Modos 0000 seguem um baseline rígido, mas devem ser validados contra aplicações e política local.
18_home_file_hygiene.sh	Crítico; remove SUID/SGID legítimos e renomeia arquivos de usuários.