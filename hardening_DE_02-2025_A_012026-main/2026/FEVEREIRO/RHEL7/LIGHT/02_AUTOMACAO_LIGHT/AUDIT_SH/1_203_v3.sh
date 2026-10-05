#!/bin/bash
echo -e "\n 1 Bloquear módulo cramfs persistentemente via modprobe.d e remover se carregado."
( ! modinfo cramfs &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+cramfs[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+cramfs\b' && ! lsmod | awk '{print $1}' | grep -qx cramfs ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 2 Bloquear módulo squashfs persistentemente via modprobe.d e remover se carregado."
( ! modinfo squashfs &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+squashfs[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+squashfs\b' && ! lsmod | awk '{print $1}' | grep -qx squashfs ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 3 Bloquear módulo udf persistentemente via modprobe.d e remover se carregado."
( ! modinfo udf &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+udf[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+udf\b' && ! lsmod | awk '{print $1}' | grep -qx udf ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 4 Bloquear módulo hfs persistentemente via modprobe.d e remover se carregado."
( ! modinfo hfs &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+hfs[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+hfs\b' && ! lsmod | awk '{print $1}' | grep -qx hfs ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 5 Bloquear módulo hfsplus persistentemente via modprobe.d e remover se carregado."
( ! modinfo hfsplus &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+hfsplus[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+hfsplus\b' && ! lsmod | awk '{print $1}' | grep -qx hfsplus ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 6 Bloquear módulo jffs2 persistentemente via modprobe.d e remover se carregado."
( ! modinfo jffs2 &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+jffs2[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+jffs2\b' && ! lsmod | awk '{print $1}' | grep -qx jffs2 ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 7 Bloquear módulo freevxfs persistentemente via modprobe.d e remover se carregado."
( ! modinfo freevxfs &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+freevxfs[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+freevxfs\b' && ! lsmod | awk '{print $1}' | grep -qx freevxfs ) ) && echo "PASS" || echo "FAIL"

echo -e "\n 9 Bloquear módulo usb_storage persistentemente."
( ! modinfo usb_storage &>/dev/null || ( modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*install[[:space:]]+usb_storage[[:space:]]+/(bin|sbin)/(true|false)\b' && modprobe --showconfig 2>/dev/null | grep -Eq '^[[:space:]]*blacklist[[:space:]]+usb_storage\b' && ! lsmod | awk '{print $1}' | grep -qx usb_storage ) ) && echo "PASS" || echo "FAIL"

echo -e "\n15 Configurar fs.suid_dumpable=0 persistentemente."
( sysctl -n fs.suid_dumpable 2>/dev/null | grep -qx 0 && grep -REq '^\s*fs\.suid_dumpable\s*=\s*0\b' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n18 Configurar ASLR completo via sysctl persistente."
( sysctl -n kernel.randomize_va_space 2>/dev/null | grep -qx 2 && grep -REq '^\s*kernel\.randomize_va_space\s*=\s*2\b' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n20 Configurar perf_event_paranoid restritivo via sysctl persistente."
( sysctl -n kernel.perf_event_paranoid 2>/dev/null | grep -Eq '^[23]$' && grep -REq '^\s*kernel\.perf_event_paranoid\s*=\s*[23]\b' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n21 Configurar dmesg_restrict=1 via sysctl persistente."
( sysctl -n kernel.dmesg_restrict 2>/dev/null | grep -qx 1 && grep -REq '^\s*kernel\.dmesg_restrict\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n23 Configurar fs.protected_symlinks=1 persistentemente."
( sysctl -n fs.protected_symlinks 2>/dev/null | grep -qx 1 && grep -REq '^\s*fs\.protected_symlinks\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n24 Configurar fs.protected_hardlinks=1 persistentemente."
( sysctl -n fs.protected_hardlinks 2>/dev/null | grep -qx 1 && grep -REq '^\s*fs\.protected_hardlinks\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n35 Ajustar opções nodev,nosuid,noexec para mídias removíveis no fstab."
( grep -E '^[^#].*\s/(media|mnt)\s' /etc/fstab | grep -Eq '\bnodev\b' && grep -E '^[^#].*\s/(media|mnt)\s' /etc/fstab | grep -Eq '\bnosuid\b' && grep -E '^[^#].*\s/(media|mnt)\s' /etc/fstab | grep -Eq '\bnoexec\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n36 Ajustar opções nodev,nosuid para partições críticas."
( grep -E '^[^#].*\s/(var|home|tmp|var/tmp|var/log|var/log/audit)\s' /etc/fstab | grep -Eq '\bnodev\b' && grep -E '^[^#].*\s/(var|home|tmp|var/tmp|var/log|var/log/audit)\s' /etc/fstab | grep -Eq '\bnosuid\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n40 Configurar /var/log com nodev,nosuid."
( findmnt -n /var/log -o OPTIONS 2>/dev/null | grep -Eq '\bnodev\b' && findmnt -n /var/log -o OPTIONS 2>/dev/null | grep -Eq '\bnosuid\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n41 Configurar /var/log/audit com nodev,nosuid."
( findmnt -n /var/log/audit -o OPTIONS 2>/dev/null | grep -Eq '\bnodev\b' && findmnt -n /var/log/audit -o OPTIONS 2>/dev/null | grep -Eq '\bnosuid\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n42 Configurar /home com nodev quando aplicável."
( findmnt -n /home -o OPTIONS 2>/dev/null | grep -Eq '\bnodev\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n44 Aplicar sticky bit em diretórios world writable locais."
( ! df --local -P | awk 'NR>1{print $6}' | xargs -I{} find {} -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -q . ) && echo "PASS" || echo "FAIL"

echo -e "\n45 Aplicar sticky bit em /tmp."
( stat -c '%a' /tmp 2>/dev/null | grep -Eq '^1[0-7][0-7][0-7]$' ) && echo "PASS" || echo "FAIL"

echo -e "\n46 Aplicar sticky bit em /var/tmp."
( stat -c '%a' /var/tmp 2>/dev/null | grep -Eq '^1[0-7][0-7][0-7]$' ) && echo "PASS" || echo "FAIL"

echo -e "\n47 Aplicar sticky bit em /dev/shm quando aplicável."
( stat -c '%a' /dev/shm 2>/dev/null | grep -Eq '^1[0-7][0-7][0-7]$' ) && echo "PASS" || echo "FAIL"

echo -e "\n56 Remover prelink quando presente."
( ! rpm -q prelink &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n57 Desabilitar ou remover xinetd quando não requerido."
( ! systemctl is-enabled xinetd 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n58 Habilitar serviço de sincronização de tempo aprovado."
( systemctl is-enabled chronyd 2>/dev/null | grep -qx enabled && systemctl is-active chronyd 2>/dev/null | grep -qx active ) && echo "PASS" || echo "FAIL"

echo -e "\n59 Configurar fontes de tempo confiáveis."
( grep -Eq '^[[:space:]]*server[[:space:]]+\S+' /etc/chrony.conf 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n60 Garantir sincronização automática em execução."
( systemctl is-active chronyd 2>/dev/null | grep -qx active ) && echo "PASS" || echo "FAIL"

echo -e "\n61 Remover componentes X11 quando não necessários."
( ! rpm -qa | grep -Eq '^xorg-x11' ) && echo "PASS" || echo "FAIL"

echo -e "\n62 Desabilitar avahi quando não requerido."
( ! systemctl is-enabled avahi-daemon 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n63 Desabilitar CUPS quando não requerido."
( ! systemctl is-enabled cups 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n69 Remover serviços IMAP/POP3 quando não aplicáveis."
( ! rpm -qa | grep -Eq '^(dovecot|cyrus-imapd)' ) && echo "PASS" || echo "FAIL"

echo -e "\n70 Remover Samba quando não aplicável."
( ! rpm -q samba &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n71 Remover proxy HTTP quando não aplicável."
( ! rpm -qa | grep -Eq '^squid' ) && echo "PASS" || echo "FAIL"

echo -e "\n72 Desabilitar SNMP quando não requerido."
( ! systemctl is-enabled snmpd 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n73 Remover servidor NIS quando não aplicável."
( ! rpm -q ypserv &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n74 Remover servidor Telnet."
( ! rpm -q telnet-server &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n75 Configurar MTA para modo local only quando aplicável."
( ! rpm -q postfix &>/dev/null || postconf -n 2>/dev/null | grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*localhost\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n76 Desabilitar NFS server quando não aplicável."
( ! systemctl is-enabled nfs-server 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n77 Desabilitar rpcbind quando não requerido."
( ! systemctl is-enabled rpcbind 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n78 Desabilitar rsync daemon quando não requerido."
( ! systemctl is-enabled rsyncd 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n79 Remover cliente NIS."
( ! rpm -q ypbind &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n80 Remover cliente rsh."
( ! rpm -qa | grep -Eq '^rsh(-|$)' ) && echo "PASS" || echo "FAIL"

echo -e "\n81 Remover cliente talk."
( ! rpm -qa | grep -Eq '^talk(-|$)' ) && echo "PASS" || echo "FAIL"

echo -e "\n82 Remover cliente telnet."
( ! rpm -q telnet &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n83 Remover cliente LDAP quando não requerido."
( ! rpm -q openldap-clients &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n84 Serviços não essenciais habilitados"
( systemctl list-unit-files --state=enabled 2>/dev/null | grep -Eq '^(avahi-daemon|cups|telnet|vsftpd|xinetd|tftp)' && echo "FAIL" || echo "PASS" )

echo -e "\n85 Remover servidor TFTP."
( ! rpm -q tftp-server &>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n86 PolicyKit endurecido"
( grep -REq 'polkit\.Result\.YES|allow' /etc/polkit-1/rules.d/*.rules 2>/dev/null && echo "FAIL" || echo "PASS" )

echo -e "\n87 Habilitar gpgcheck em todos os repositórios."
#( ! grep -L '^[[:space:]]*gpgcheck[[:space:]]*=[[:space:]]*1\b' /etc/yum.repos.d/*.repo 2>/dev/null | grep -q . ) && echo "PASS" || echo "FAIL"
grep -q 'gpgcheck=1' /etc/yum.repos.d/*.repo 2>/dev/null && echo PASS || echo FAIL


echo -e "\n88 Aplicar atualizações de segurança pendentes."
( yum -q check-update >/dev/null 2>&1; rc=$?; [ "$rc" -eq 0 ] ) && echo "PASS" || echo "FAIL"

echo -e "\n89 Manter apenas um mecanismo de sincronização ativo."
( chrony_active=$(systemctl is-active chronyd 2>/dev/null | grep -c '^active$'); ntpd_active=$(systemctl is-active ntpd 2>/dev/null | grep -c '^active$'); if [ "$chrony_active" -eq 1 ] && [ "$ntpd_active" -eq 0 ]; then echo "PASS"; elif [ "$chrony_active" -eq 0 ] && [ "$ntpd_active" -eq 1 ]; then echo "PASS"; else echo "FAIL"; fi )

echo -e "\n90 Restringir cron e at a usuários autorizados."
( [ -f /etc/cron.allow ] && [ -f /etc/at.allow ] && grep -qx root /etc/cron.allow && grep -qx root /etc/at.allow ) && echo "PASS" || echo "FAIL"

echo -e "\n92 Desabilitar redirects de pacotes via sysctl persistente."
( sysctl -n net.ipv4.conf.all.send_redirects | grep -qx 0 && sysctl -n net.ipv4.conf.default.send_redirects | grep -qx 0 && grep -REq 'net\.ipv4\.conf\.(all|default)\.send_redirects *= *0' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n93 Desabilitar source routed packets via sysctl persistente."
( sysctl -n net.ipv4.conf.all.accept_source_route | grep -qx 0 && sysctl -n net.ipv4.conf.default.accept_source_route | grep -qx 0 && grep -REq 'net\.ipv4\.conf\.(all|default)\.accept_source_route *= *0' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n94 Desabilitar ICMP redirects via sysctl persistente."
( sysctl -n net.ipv4.conf.all.accept_redirects | grep -qx 0 && sysctl -n net.ipv4.conf.default.accept_redirects | grep -qx 0 && grep -REq 'net\.ipv4\.conf\.(all|default)\.accept_redirects *= *0' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n95 Habilitar reverse path filtering via sysctl persistente."
( sysctl -n net.ipv4.conf.all.rp_filter | grep -qx 1 && sysctl -n net.ipv4.conf.default.rp_filter | grep -qx 1 && grep -REq 'net\.ipv4\.conf\.(all|default)\.rp_filter *= *1' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n96 Habilitar ignore broadcast ICMP via sysctl persistente."
( sysctl -n net.ipv4.icmp_echo_ignore_broadcasts | grep -qx 1 && grep -REq 'net\.ipv4\.icmp_echo_ignore_broadcasts *= *1' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n97 Habilitar ignore bogus ICMP responses via sysctl persistente."
( sysctl -n net.ipv4.icmp_ignore_bogus_error_responses | grep -qx 1 && grep -REq 'net\.ipv4\.icmp_ignore_bogus_error_responses *= *1' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n98 Habilitar tcp_syncookies via sysctl persistente."
( sysctl -n net.ipv4.tcp_syncookies | grep -qx 1 && grep -REq 'net\.ipv4\.tcp_syncookies *= *1' /etc/sysctl.conf /etc/sysctl.d/ ) && echo "PASS" || echo "FAIL"

echo -e "\n100 Bloquear ICMP timestamp request no firewall."
( iptables-save 2>/dev/null | grep -q -- "--icmp-type 13" ) && echo "PASS" || echo "FAIL"

echo -e "\n101 Bloquear ICMP timestamp reply no firewall."
( iptables-save 2>/dev/null | grep -q -- "--icmp-type 14" ) && echo "PASS" || echo "FAIL"

echo -e "\n102 Desabilitar interfaces wireless ou bluetooth quando não necessárias."
( ! lsmod | grep -Eq '^(iwlwifi|bluetooth)\b' ) && echo "PASS" || echo "FAIL"

echo -e "\n104 Manter apenas uma solução de firewall ativa."
( fw_active=$(systemctl is-active firewalld 2>/dev/null | grep -c '^active$'); ipt_active=$(systemctl is-active iptables 2>/dev/null | grep -c '^active$'); if [ "$fw_active" -eq 1 ] && [ "$ipt_active" -eq 0 ]; then echo "PASS"; elif [ "$fw_active" -eq 0 ] && [ "$ipt_active" -eq 1 ]; then echo "PASS"; else echo "FAIL"; fi )

#echo -e "\n105 Permitir loopback e conexões ESTABLISHED,RELATED no firewall - iptables."
#( iptables -L INPUT -n 2>/dev/null | grep -Eq 'ACCEPT.*lo' && iptables -L INPUT -n 2>/dev/null | grep -Eq 'ESTABLISHED,RELATED' ) && echo "PASS" || echo "FAIL"
#( iptables-save 2>/dev/null | grep -q -- "-i lo -j ACCEPT" && iptables-save 2>/dev/null | grep -q -- "ESTABLISHED,RELATED" ) && echo "PASS" || echo "FAIL"

echo -e "\n107 Garantir persistência das regras de firewall após reboot."
( [ -f /etc/sysconfig/iptables ] || systemctl is-enabled firewalld 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n109 Ajustar permissões de sshd_config e diretório /etc/ssh."
( stat -c '%a %U %G' /etc/ssh/sshd_config 2>/dev/null | grep -Eq '^(600|640) root root$' && \
  stat -c '%a %U %G' /etc/ssh 2>/dev/null | grep -Eq '^(700|750) root root$' ) && echo "PASS" || echo "FAIL"

echo -e "\n111 Configurar SyslogFacility AUTHPRIV."
( grep -Eiq '^[[:space:]]*SyslogFacility[[:space:]]+AUTHPRIV\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n112 Desabilitar X11Forwarding quando não requerido."
( grep -Eiq '^[[:space:]]*X11Forwarding[[:space:]]+no\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n113 Configurar MaxAuthTries de forma restritiva."
( grep -Eiq '^[[:space:]]*MaxAuthTries[[:space:]]+[1-4]\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n114 Configurar IgnoreRhosts yes."
( grep -Eiq '^[[:space:]]*IgnoreRhosts[[:space:]]+yes\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n115 Configurar HostbasedAuthentication no."
( grep -Eiq '^[[:space:]]*HostbasedAuthentication[[:space:]]+no\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n116 Configurar PermitRootLogin conforme política."
( grep -Eiq '^[[:space:]]*PermitRootLogin[[:space:]]+(no|prohibit-password)\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n117 Configurar PermitEmptyPasswords no."
( grep -Eiq '^[[:space:]]*PermitEmptyPasswords[[:space:]]+no\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n118 Configurar PermitUserEnvironment no."
( grep -Eiq '^[[:space:]]*PermitUserEnvironment[[:space:]]+no\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n119 Configurar UsePAM yes."
( grep -Eiq '^[[:space:]]*UsePAM[[:space:]]+yes\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n120 Ajustar ClientAliveInterval e ClientAliveCountMax."
( grep -Eiq '^[[:space:]]*ClientAliveInterval[[:space:]]+[1-9][0-9]*\b' /etc/ssh/sshd_config && \
  grep -Eiq '^[[:space:]]*ClientAliveCountMax[[:space:]]+[1-9][0-9]*\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n121 Configurar LoginGraceTime restritivo."
( grep -Eiq '^[[:space:]]*LoginGraceTime[[:space:]]+[1-9][0-9]*\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n122 Configurar MaxStartups e MaxSessions restritivos."
( grep -Eiq '^[[:space:]]*MaxStartups[[:space:]]+[0-9:]+\b' /etc/ssh/sshd_config && \
  grep -Eiq '^[[:space:]]*MaxSessions[[:space:]]+[0-9]+\b' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n124 Configurar Banner legal quando exigido."
( grep -Eiq '^[[:space:]]*Banner[[:space:]]+\S+' /etc/ssh/sshd_config ) && echo "PASS" || echo "FAIL"

echo -e "\n130 Incluir módulo de complexidade na stack PAM."
( grep -Eq '\bpam_pwquality\.so\b' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n131 Configurar pam_pwquality conforme baseline."
( grep -Eq 'pam_pwquality\.so.*(minlen=|dcredit=|ucredit=|lcredit=|ocredit=)' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n134 Configurar pam_pwhistory."
( grep -Eq '\bpam_pwhistory\.so\b' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n135 Definir tamanho mínimo de senha."
( grep -Eq 'minlen=[1-9][0-9]+' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n136 Configurar complexidade mínima de senha."
( grep -Eq '(dcredit|ucredit|lcredit|ocredit)=-?[1-9]+' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n137 Configurar limites de repetição e sequência."
( grep -Eq '^[[:space:]]*(maxrepeat|maxsequence)[[:space:]]*=[[:space:]]*[1-9]+' /etc/security/pwquality.conf ) && echo "PASS" || echo "FAIL"

echo -e "\n138 Habilitar verificação de dicionário quando aplicável."
( grep -Eq '^[[:space:]]*dictcheck[[:space:]]*=[[:space:]]*1\b' /etc/security/pwquality.conf ) && echo "PASS" || echo "FAIL"

echo -e "\n139 Configurar algoritmo de hashing forte."
( grep -Eq 'pam_unix\.so.*\bsha512\b' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n140 Configurar histórico de senha."
( grep -Eq 'pam_pwhistory\.so.*remember=[1-9]+' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n142 Configurar tempo de desbloqueio conforme política."
( grep -Eq 'pam_faillock\.so.*unlock_time=[1-9]+' /etc/pam.d/system-auth ) && echo "PASS" || echo "FAIL"

echo -e "\n143 Configurar PASS_MAX_DAYS."
( grep -Eq '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+[1-9][0-9]+' /etc/login.defs ) && echo "PASS" || echo "FAIL"

echo -e "\n144 Configurar PASS_MIN_DAYS."
( grep -Eq '^[[:space:]]*PASS_MIN_DAYS[[:space:]]+[0-9]+' /etc/login.defs ) && echo "PASS" || echo "FAIL"

echo -e "\n145 Configurar PASS_WARN_AGE."
( grep -Eq '^[[:space:]]*PASS_WARN_AGE[[:space:]]+[1-9][0-9]*' /etc/login.defs ) && echo "PASS" || echo "FAIL"

echo -e "\n146 Configurar parâmetro INACTIVE para contas locais."
( useradd -D 2>/dev/null | grep -Eq '^INACTIVE=[1-9][0-9]*' ) && echo "PASS" || echo "FAIL"

echo -e "\n147 Corrigir datas inconsistentes de troca de senha."
( ! awk -F: '($2!~/^(!|\*)/ && $2!="" && $5==0){print}' /etc/shadow | grep -q . ) && echo "PASS" || echo "FAIL"

echo -e "\n148 Garantir apenas root com UID 0."
( awk -F: '$3==0{print}' /etc/passwd | wc -l | grep -qx 1 ) && echo "PASS" || echo "FAIL"

echo -e "\n149 Garantir apenas grupo root com GID 0."
( awk -F: '$3==0{print}' /etc/group | wc -l | grep -qx 1 ) && echo "PASS" || echo "FAIL"

echo -e "\n150 Bloquear contas de sistema com shell inválido."
( awk -F: '($3>0 && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print}' /etc/passwd | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n151 Remover shells inválidos de /etc/shells."
( grep -Ev '^(#|/bin/bash|/bin/sh|/sbin/nologin|/bin/false)$' /etc/shells | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n152 Ajustar PATH do root removendo diretórios inseguros."
( su - root -c 'echo "$PATH"' 2>/dev/null | grep -Eq '(^|:)\.(:|$)' && echo "FAIL" || echo "PASS" )

echo -e "\n153 Configurar umask restritiva padrão."
( grep -REq '^[[:space:]]*umask[[:space:]]+0[2-7][2-7]\b' /etc/profile /etc/bashrc 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n154 Configurar timeout de shell."
( grep -REq '^[[:space:]]*TMOUT=[1-9][0-9]+' /etc/profile /etc/bashrc 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n155 Restringir administração privilegiada via sudo."
( grep -Eq '^[[:space:]]*%wheel[[:space:]]+ALL=\(ALL\)[[:space:]]+ALL\b' /etc/sudoers ) && echo "PASS" || echo "FAIL"

echo -e "\n156 Configurar sudo para uso de pseudo tty."
( grep -Eq '^[[:space:]]*Defaults[[:space:]]+requiretty\b' /etc/sudoers ) && echo "PASS" || echo "FAIL"

echo -e "\n157 Habilitar logging de sudo."
( grep -Eq '^[[:space:]]*Defaults[[:space:]]+logfile=' /etc/sudoers ) && echo "PASS" || echo "FAIL"

echo -e "\n159 Configurar timeout de autenticação sudo."
( grep -Eq '^[[:space:]]*Defaults[[:space:]]+timestamp_timeout=[1-9][0-9]*\b' /etc/sudoers ) && echo "PASS" || echo "FAIL"

echo -e "\n160 Restringir uso de su a grupo autorizado."
(grep -q '^auth[[:space:]]\+required[[:space:]]\+pam_wheel\.so' /etc/pam.d/su) && echo "PASS" || echo "FAIL"

echo -e "\n161 Ajustar arquitetura de logs evitando duplicidade."
( systemctl is-enabled rsyslog 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n162 Configurar journald com persistência quando aplicável."
( grep -Eq '^[[:space:]]*Storage=persistent\b' /etc/systemd/journald.conf ) && echo "PASS" || echo "FAIL"

echo -e "\n163 Instalar e ativar rsyslog quando requerido."
( systemctl is-enabled rsyslog 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n164 Configurar rotação de logs."
( grep -Eq '^[[:space:]]*rotate[[:space:]]+[1-9][0-9]*' /etc/logrotate.conf ) && echo "PASS" || echo "FAIL"

echo -e "\n165 Instalar e habilitar auditd."
( systemctl is-enabled auditd 2>/dev/null | grep -qx enabled ) && echo "PASS" || echo "FAIL"

echo -e "\n166 Garantir auditd inicializa antes de serviços críticos."
( systemctl show auditd -p Before 2>/dev/null | grep -q sysinit.target ) && echo "PASS" || echo "FAIL"

echo -e "\n167 Configurar tamanho máximo de log de auditoria."
( grep -Eq '^[[:space:]]*max_log_file[[:space:]]*=[[:space:]]*[1-9][0-9]*' /etc/audit/auditd.conf ) && echo "PASS" || echo "FAIL"

echo -e "\n169 Configurar auditoria de alteração de data e hora."
( grep -REq '\b(adjtimex|settimeofday|clock_settime)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n170 Configurar auditoria de alteração de contas e grupos."
( grep -REq '(/etc/passwd|/etc/group|/etc/shadow)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n171 Configurar auditoria de alterações de rede."
( grep -REq '(/etc/sysconfig/network|/etc/hosts|/etc/resolv\.conf)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n172 Configurar auditoria de eventos MAC quando aplicável."
( grep -REq '\b(setenforce|/etc/selinux|selinux-policy)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n173 Configurar auditoria de login e logout."
( grep -REq '\b(login|logout|session)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n174 Configurar auditoria de permissões DAC."
( grep -REq '\b(chmod|chown|setxattr|fchmod)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n175 Configurar auditoria de tentativas de acesso não autorizado."
( grep -REq '\b(EACCES|EPERM)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n176 Configurar auditoria de execuções privilegiadas."
( grep -REq '\bexecve\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n177 Configurar auditoria de mount e unmount."
( grep -REq '\b(mount|umount2)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n178 Configurar auditoria de deleção de arquivos."
( grep -REq '\b(unlink|rename|rmdir|unlinkat|renameat)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n179 Configurar auditoria de carga e descarga de módulos de kernel."
( grep -REq '\b(init_module|delete_module|finit_module)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n180 Configurar auditoria de sudo e sudoers."
( grep -REq '(/etc/sudoers|/etc/sudoers\.d|sudo\.log)\b' /etc/audit/rules.d 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n183 Agendar verificação periódica de integridade."
( grep -REq '\baide\b' /etc/cron.* 2>/dev/null ) && echo "PASS" || echo "FAIL"

echo -e "\n185 Ajustar permissões de /etc/passwd."
( stat -c '%a' /etc/passwd | grep -Eq '^[0-6]44$' ) && echo "PASS" || echo "FAIL"

echo -e "\n186 Ajustar permissões de /etc/passwd-."
( stat -c '%a' /etc/passwd- 2>/dev/null | grep -Eq '^[0-6]44$' ) && echo "PASS" || echo "FAIL"

echo -e "\n187 Ajustar permissões de /etc/shadow."
( stat -c '%a %U %G' /etc/shadow 2>/dev/null | grep -Eq '^(000|400|600|640) root root$' ) && echo "PASS" || echo "FAIL"

echo -e "\n188 Ajustar permissões de /etc/shadow-."
( stat -c '%a %U %G' /etc/shadow- 2>/dev/null | grep -Eq '^(000|400|600|640) root root$' ) && echo "PASS" || echo "FAIL"

echo -e "\n189 Ajustar permissões de /etc/gshadow-."
( stat -c '%a %U %G' /etc/gshadow- 2>/dev/null | grep -Eq '^(000|400|600|640) root root$' ) && echo "PASS" || echo "FAIL"

echo -e "\n190 Ajustar permissões de /etc/gshadow."
( stat -c '%a %U %G' /etc/gshadow 2>/dev/null | grep -Eq '^(000|400|600|640) root root$' ) && echo "PASS" || echo "FAIL"

echo -e "\n191 Ajustar permissões de /etc/group."
( stat -c '%a' /etc/group | grep -Eq '^[0-6]44$' ) && echo "PASS" || echo "FAIL"

echo -e "\n192 Ajustar permissões de /etc/group-."
( stat -c '%a' /etc/group- 2>/dev/null | grep -Eq '^[0-6]44$' ) && echo "PASS" || echo "FAIL"

echo -e "\n194 Proteger /etc/security/opasswd contra acesso não autorizado."
( stat -c '%a %U %G' /etc/security/opasswd 2>/dev/null | grep -Eq '^(600|640) root root$' ) && echo "PASS" || echo "FAIL"

echo -e "\n195 Corrigir arquivos órfãos sem owner válido."
( find / -xdev -nouser 2>/dev/null | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n196 Garantir sticky bit em diretórios world writable."
( ! find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -q . ) && echo "PASS" || echo "FAIL"

echo -e "\n197 Corrigir arquivos sem owner ou grupo válido."
( find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n199 Verificar usuários sem diretório home."
( awk -F: '($3>=1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1":"$6}' /etc/passwd | while IFS=: read u d; do [ -d "$d" ] || echo "$u"; done | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n200 Ajustar ownership dos diretórios home para o respectivo usuário."
( awk -F: '($3>=1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1":"$6}' /etc/passwd | while IFS=: read u d; do [ -d "$d" ] && [ "$(stat -c %U "$d")" = "$u" ] || echo "$u"; done | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n201 Ajustar permissões de home para 750 ou mais restritivas."
( find /home -mindepth 1 -maxdepth 1 -type d -perm /027 2>/dev/null | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n202 Ajustar permissões de dotfiles removendo escrita indevida."
( find /home -maxdepth 2 -type f -name ".*" -perm -002 2>/dev/null | grep -q . && echo "FAIL" || echo "PASS" )

echo -e "\n203 Remover ou proteger arquivos forward, netrc e rhosts conforme política."
( find /home -maxdepth 2 -type f \( -name ".forward" -o -name ".netrc" -o -name ".rhosts" \) 2>/dev/null | grep -q . && echo "FAIL" || echo "PASS" )
