echo -e "\n[1] Verifique se o módulo do kernel do CRAMFS não está disponível"
(modinfo cramfs &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+cramfs\b' && ! lsmod | grep -q cramfs) || (! modinfo cramfs &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[2] Verifique se o módulo do kernel do SQUASHFS não está disponível"
(modinfo squashfs &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+squashfs\b' && ! lsmod | grep -q squashfs) || (! modinfo squashfs &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[3] Verifique se o módulo do kernel do UDF não está disponível"
(modinfo udf &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+udf\b' && ! lsmod | grep -q udf) || (! modinfo udf &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[4] Verifique se o módulo do kernel do HFS não está disponível"
(modinfo hfs &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+hfs\b' && ! lsmod | grep -q hfs) || (! modinfo hfs &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[5] Verifique se o módulo do kernel do HFSPLUS não está disponível"
(modinfo hfsplus &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+hfsplus\b' && ! lsmod | grep -q hfsplus) || (! modinfo hfsplus &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[6] Verifique se o módulo do kernel do JFFS2 não está disponível"
(modinfo jffs2 &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+jffs2\b' && ! lsmod | grep -q jffs2) || (! modinfo jffs2 &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[7] Verifique se o módulo do kernel do FREEVXFS não está disponível"
(modinfo freevxfs &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+freevxfs\b' && ! lsmod | grep -q freevxfs) || (! modinfo freevxfs &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[8] Verifique se o módulo do kernel do OVERLAY não está disponível"
(modinfo overlay &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+overlay\b' && ! lsmod | grep -q overlay) || (! modinfo overlay &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[9] Verifique se o módulo do kernel do USB-STORAGE não está disponível"
(modinfo usb-storage &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+usb_storage\b' && ! lsmod | grep -q usb_storage) || (! modinfo usb-storage &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[10] Verifique se o módulo do kernel do DCCP não está disponível"
(modinfo dccp &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+dccp\b' && ! lsmod | grep -q dccp) || (! modinfo dccp &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[11] Verifique se o módulo do kernel do SCTP não está disponível"
(modinfo sctp &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+sctp\b' && ! lsmod | grep -q sctp) || (! modinfo sctp &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[12] Verifique se o módulo do kernel do RDS não está disponível"
(modinfo rds &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+rds\b' && ! lsmod | grep -q rds) || (! modinfo rds &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[13] Verifique se o módulo do kernel do TIPC não está disponível"
(modinfo tipc &>/dev/null && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+tipc\b' && ! lsmod | grep -q tipc) || (! modinfo tipc &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[14] Verifique se core dumps estão restritos"
(ulimit -c 0 && sysctl -n fs.suid_dumpable | grep -q '^0$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[15] Verifique se ptrace_scope está restrito"
(sysctl -n kernel.yama.ptrace_scope | grep -q '^[1-3]$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[16] Verifique se NX/XD está ativo"
(grep -q 'nx' /proc/cpuinfo && dmesg | grep -qi 'NX.*active') && echo "✅ APROVADO" || echo "⚠️ REPROVADO (Possível ausência no hardware)"

echo -e "\n[17] Verifique se ASLR está habilitado"
(sysctl -n kernel.randomize_va_space | grep -q '^2$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[18] Verifique se IOMMU está ativo"
(grep -q 'iommu=on' /proc/cmdline) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[19] Verifique se perf_event está restrito"
(sysctl -n kernel.perf_event_paranoid | grep -q '^[2-3]$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[20] Verifique se dmesg está restrito"
(sysctl -n kernel.dmesg_restrict | grep -q '^1$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[21] Verifique se user namespace está desabilitado"
( sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[22] Verifique se protected_symlinks está habilitado"
(sysctl -n fs.protected_symlinks | grep -q '^1$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[23] Verifique se protected_hardlinks está habilitado"
(sysctl -n fs.protected_hardlinks | grep -q '^1$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[24] Verifique se suid_dumpable=0"
(sysctl -n fs.suid_dumpable | grep -q '^0$') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
echo -e "\n[25] Partição dedicada para /tmp"
(findmnt -kn /tmp >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[26] Partição dedicada para /dev/shm"
(findmnt -kn /dev/shm >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[27] Partição dedicada para /var"
(findmnt -kn /var >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[28] Partição dedicada para /var/tmp"
(findmnt -kn /var/tmp >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[29] Partição dedicada para /var/log"
(findmnt -kn /var/log >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[30] Partição dedicada para /var/log/audit"
(findmnt -kn /var/log/audit >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[31] Partição dedicada para /home"
(findmnt -kn /home >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[32] Partição dedicada para /historico"
(findmnt -kn /historico >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[33] Partição dedicada para /crash"
(findmnt -kn /crash >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[34] Partição dedicada para /UNIX"
(findmnt -kn /UNIX >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[35] Montagem segura de partições e mídia removível"
(grep -E 'nodev|nosuid|noexec' /etc/fstab >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[36] Opções de montagem seguras em partições críticas"
(findmnt -n /var | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[37] Opções de montagem seguras em /tmp"
(findmnt -n /tmp | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[38] Opções de montagem seguras em /dev/shm"
(findmnt -n /dev/shm | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[39] Opções de montagem seguras em /var/tmp"
(findmnt -n /var/tmp | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[40] Opções de montagem seguras em /var/log"
(findmnt -n /var/log | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[41] Opções de montagem seguras em /var/log/audit"
(findmnt -n /var/log/audit | grep -Eq 'nodev|nosuid|noexec' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[42] Opções de montagem seguras em /home"
(findmnt -n /home | grep -qw nodev && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[43] Opções de montagem seguras em mídias removíveis"
(grep -E 'nodev|nosuid|noexec' /etc/fstab | grep -E '/media|/run/media' >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[44] Sticky bit em diretórios world-writable"
(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep . && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[45] Sticky bit em /tmp"
(stat -c "%A" /tmp | grep -q 't' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[46] Sticky bit em /var/tmp"
(stat -c "%A" /var/tmp | grep -q 't' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[47] Sticky bit em /dev/shm"
(stat -c "%A" /dev/shm | grep -q 't' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[48] Autofs desabilitado"
(systemctl is-enabled autofs &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[49] Senha de bootloader configurada"
(grep -q 'password_pbkdf2' /boot/grub2/grub.cfg 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[50] Permissões seguras no arquivo do bootloader"
(stat -Lc '%a %U %G' /boot/grub2/grub.cfg 2>/dev/null | grep -Eq '^(400|600) root root$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[51] Single user mode com autenticação"
(grep -q '^ExecStart=-/bin/sh' /usr/lib/systemd/system/emergency.service && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[52] MAC (SELinux/AppArmor) ativo"
(getenforce 2>/dev/null | grep -Eq 'Enforcing|Permissive' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[53] Política MAC definida"
(sestatus 2>/dev/null | grep -q 'Loaded policy name' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[54] Serviços unconfined minimizados"
(ps -eZ | grep -q 'unconfined_service_t' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[55] Sem serviços sem restrições MAC"
(ps -eZ | grep -q 'unconfined_t' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[56] Prelink removido"
(rpm -q prelink &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[57] xinetd removido"
(rpm -q xinetd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[58] Sincronização de tempo em uso"
( systemctl is-active --quiet chronyd &>/dev/null || systemctl is-active --quiet ntpd &>/dev/null || systemctl is-active --quiet systemd-timesyncd &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[59] Chrony configurado"
( ! rpm -q chrony &>/dev/null || ( systemctl is-enabled chronyd &>/dev/null && grep -q '^server' /etc/chrony.conf 2>/dev/null ) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[60] NTP configurado"
( ! rpm -q ntp &>/dev/null || ( systemctl is-enabled ntpd &>/dev/null && grep -q '^server' /etc/ntp.conf 2>/dev/null ) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[61] X11 ausente"
(rpm -q xorg-x11-server-common &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[62] Avahi ausente"
(rpm -q avahi &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[63] CUPS ausente"
(rpm -q cups &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[64] DHCP server ausente"
(rpm -q dhcp-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[65] LDAP server ausente"
(rpm -q openldap-servers &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[66] DNS server ausente"
(rpm -q bind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[67] FTP server ausente"
(rpm -q vsftpd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[68] HTTP server ausente"
(rpm -q httpd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[69] IMAP/POP3 server ausente"
(rpm -q dovecot &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[70] Samba ausente"
(rpm -q samba &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[71] Proxy HTTP ausente"
(rpm -q squid &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[72] SNMP ausente"
(rpm -q net-snmp &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[73] NIS server ausente"
(rpm -q ypserv &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[74] Telnet server ausente"
(rpm -q telnet-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[75] MTA em modo local-only"
( [ ! -f /etc/postfix/main.cf ] || grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*(localhost|loopback-only)\b' /etc/postfix/main.cf 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[76] NFS server controlado"
(systemctl is-enabled nfs-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[77] rpcbind controlado"
(systemctl is-enabled rpcbind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[78] rsync daemon controlado"
(systemctl is-enabled rsyncd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[79] Cliente NIS ausente"
(rpm -q ypbind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[80] Cliente rsh ausente"
(rpm -q rsh &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[81] Cliente talk ausente"
(rpm -q talk &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[82] Cliente telnet ausente"
(rpm -q telnet &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[83] Cliente LDAP ausente"
(rpm -q openldap-clients &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[84] Serviços não essenciais removidos/mascarados"
(systemctl list-unit-files --state=enabled | grep -Eq 'avahi|cups|telnet|ftp|nis|tftp|xinetd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[85] TFTP server removido"
(rpm -q tftp-server &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo "[86] PolicyKit endurecido"
( grep -Eq 'polkit.Result.YES|allow' /etc/polkit-1/rules.d/*.rules 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )

echo -e "\n[87] Assinaturas de pacotes habilitadas"
(grep -Eq '^gpgcheck\s*=\s*1' /etc/yum.conf /etc/yum.repos.d/*.repo 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[89] Apenas um daemon de time sync"
( ( systemctl is-active --quiet chronyd &>/dev/null && ! systemctl is-active --quiet ntpd &>/dev/null && ! systemctl is-active --quiet systemd-timesyncd &>/dev/null ) || ( ! systemctl is-active --quiet chronyd &>/dev/null && systemctl is-active --quiet ntpd &>/dev/null && ! systemctl is-active --quiet systemd-timesyncd &>/dev/null ) || ( ! systemctl is-active --quiet chronyd &>/dev/null && ! systemctl is-active --quiet ntpd &>/dev/null && systemctl is-active --quiet systemd-timesyncd &>/dev/null ) ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[90] Cron/at seguros e restritos"
(stat -Lc '%a %U %G' /etc/cron.allow 2>/dev/null | grep -Eq '^640 root (root|crontab)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[91] IP forwarding desabilitado"
(sysctl -n net.ipv4.ip_forward 2>/dev/null | grep -q '^0$' && sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[92] Redirecionamentos de pacotes desabilitados"
(sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[93] Source-routed packets bloqueados"
(sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[94] ICMP redirects bloqueados"
(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q '^0$' && sysctl -n net.ipv4.conf.all.secure_redirects 2>/dev/null | grep -q '^0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[95] Reverse path filtering habilitado"
(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null | grep -Eq '^[12]$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[96] ICMP broadcast ignorado"
(sysctl -n net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[97] Respostas ICMP inválidas ignoradas"
(sysctl -n net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[98] TCP SYN cookies habilitados"
(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[99] IPv6 desabilitado ou endurecido"
(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q '^1$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[100] ICMP timestamp-request drop"
(firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type timestamp-request -j DROP &>/dev/null || nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' || iptables -L INPUT -n 2>/dev/null | grep -qi 'icmp type timestamp-request.*DROP') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[101] ICMP timestamp-reply drop"
(iptables -L INPUT -v -n | grep -q 'icmp type timestamp-reply.*DROP' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[101-1] ICMP timestamp-reply drop"
( firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type timestamp-reply -j DROP 2>/dev/null || nft list ruleset 2>/dev/null | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' || iptables -L INPUT -n 2>/dev/null | grep -qi 'icmp type timestamp-reply.*DROP' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[102] Wireless/Bluetooth desabilitados"
(lsmod | grep -Eq 'bluetooth|iwlwifi' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[103] Firewall com política default deny"
(iptables -L INPUT   -n 2>/dev/null | grep -q "policy DROP" && iptables -L FORWARD -n 2>/dev/null | grep -q "policy DROP" && iptables -L OUTPUT  -n 2>/dev/null | grep -q "policy DROP") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[104] Apenas uma solução de firewall ativa"
( [ "$(printf "%s\n" "$(systemctl is-active firewalld >/dev/null 2>&1 && echo F)" "$(iptables -L >/dev/null 2>&1 && echo F)" "$(ip6tables -L >/dev/null 2>&1 && echo F)" | grep -c F)" -eq 1 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO" )

echo -e "\n[105] Regras básicas de firewall"
(iptables -L INPUT -n 2>/dev/null | grep -q "lo .* ACCEPT" && iptables -L INPUT -n | grep -Eq "ESTABLISHED|RELATED" && iptables -L OUTPUT -n | grep -q "ACCEPT") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[106] Regras explícitas para portas abertas"
(ss -tuln | awk 'NR>1 {print $5}' | sed 's/.*://g' | sort -u | grep -v '^$' | while read P; do iptables -L INPUT -n 2>/dev/null | grep -q ":${P} " || exit 1; done && exit 0) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[107] Regras de firewall persistentes"
(iptables-save 2>/dev/null | grep -q ".") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[108] TLS mínimo 1.2/1.3"
(grep -Eq "(TLSv1\.2|TLSv1\.3)" /etc/crypto-policies/config 2>/dev/null || grep -Eq "(MinProtocol.*TLSv1\.2|ssl_protocol.*TLSv1\.2)" /etc/httpd/conf.d/* 2>/dev/null || grep -Eq "(ssl_protocol.*TLSv1\.2)" /etc/nginx/* 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[109] Permissões seguras em sshd_config e chaves"
( stat -c %a /etc/ssh/sshd_config | grep -Eq '^(600|400)$' && [ "$(stat -c %U:%G /etc/ssh)" = "root:root" ] ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#Em POSIX, permissões não são ordenáveis semanticamente por número

echo -e "\n[110] Controle de acesso via Allow/Deny"
(grep -Eq '^[[:space:]]*(AllowUsers|DenyUsers|AllowGroups|DenyGroups)' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[111] LogLevel adequado"
(grep -Eq '^[[:space:]]*LogLevel[[:space:]]+(INFO|VERBOSE)' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[112] X11Forwarding desabilitado"
(grep -Eq '^[[:space:]]*X11Forwarding[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[113] MaxAuthTries limitado"
(grep -Eq '^[[:space:]]*MaxAuthTries[[:space:]]+[1-4]$' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[114] IgnoreRhosts habilitado"
(grep -Eq '^[[:space:]]*IgnoreRhosts[[:space:]]+yes' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[115] HostbasedAuthentication desabilitado"
(grep -Eq '^[[:space:]]*HostbasedAuthentication[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[116] PermitRootLogin restrito/desabilitado"
(grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+(no|prohibit-password)' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[117] PermitEmptyPasswords desabilitado"
(grep -Eq '^[[:space:]]*PermitEmptyPasswords[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[118] PermitUserEnvironment desabilitado"
(grep -Eq '^[[:space:]]*PermitUserEnvironment[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[119] UsePAM habilitado"
(grep -Eq '^[[:space:]]*UsePAM[[:space:]]+yes' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[120] Idle timeout configurado"
(grep -Eq '^[[:space:]]*ClientAliveInterval[[:space:]]+([1-9][0-9]|[1-2][0-9]{2}|300)$' /etc/ssh/sshd_config \
 && grep -Eq '^[[:space:]]*ClientAliveCountMax[[:space:]]+[1-3]$' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[121] LoginGraceTime curto"
(grep -Eq '^[[:space:]]*LoginGraceTime[[:space:]]+([1-9][0-9]|[1-5][0-9]{2})s?$' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[122] MaxStartups/MaxSessions limitados"
(grep -Eq '^[[:space:]]*MaxStartups[[:space:]]+.+$' /etc/ssh/sshd_config \
 && grep -Eq '^[[:space:]]*MaxSessions[[:space:]]+[1-9]+' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[123] AllowTcpForwarding restrito"
(grep -Eq '^[[:space:]]*AllowTcpForwarding[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[124] Banner legal configurado"
(grep -Eq '^[[:space:]]*Banner[[:space:]]+/.*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[125] Ciphers fortes"
(grep -Eq '^[[:space:]]*Ciphers[[:space:]]+.*(chacha20|aes256).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[126] MACs fortes"
(grep -Eq '^[[:space:]]*MACs[[:space:]]+.*(hmac-sha2|umac).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[127] KexAlgorithms fortes"
(grep -Eq '^[[:space:]]*KexAlgorithms[[:space:]]+.*(curve25519|diffie-hellman-group-exchange-sha256).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[128] Preferência moderna - double check"
(grep -Eq '^[[:space:]]*(Ciphers|KexAlgorithms)[[:space:]]+.*(chacha20|curve25519).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[129] ForceCommand/Chroot"
(grep -Eq '^[[:space:]]*(ForceCommand|ChrootDirectory)[[:space:]]+' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[130] pwquality habilitado"
grep -Eq 'pam_pwquality\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[132] pam_faillock habilitado"
grep -Eq 'pam_faillock\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[133] pam_tally2 NÃO deve existir em RHEL 8/9"
! grep -Eq 'pam_tally2\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[134] pam_pwhistory habilitado"
grep -Eq 'pam_pwhistory\.so' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[135] minlen ≥ 14"
grep -Psiq '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]+)' /etc/security/pwquality.conf* && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[136] minclass ≥ 4"
grep -Psiq '^\s*minclass\s*=\s*[4-9]' /etc/security/pwquality.conf* && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[137] maxrepeat & maxsequence = 3"
grep -Psiq '^\s*maxrepeat\s*=\s*3\b'   /etc/security/pwquality.conf* &&
grep -Psiq '^\s*maxsequence\s*=\s*3\b' /etc/security/pwquality.conf* && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[138] dictcheck != 0"
! grep -Psiq '^\s*dictcheck\s*=\s*0\b' /etc/security/pwquality.conf* && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[139] Hashing sha512/yescrypt"
grep -Eq 'pam_unix\.so.*(sha512|yescrypt)' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[140] pwhistory remember ≥ 5"
grep -Eq 'pam_pwhistory\.so.*remember=[5-9]' /etc/pam.d/*auth && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[141] deny ≥ 5 (faillock)"
grep -Pi '^\s*deny\s*=\s*([5-9]|[1-9][0-9]+)' /etc/security/faillock.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[142] unlock_time ≥ 900"
grep -Pi '^\s*unlock_time\s*=\s*(9[0-9]{2}|[1-9][0-9]{3,})\b' /etc/security/faillock.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[143] PASS_MAX_DAYS ≤ 365"
val=$(awk '$1=="PASS_MAX_DAYS"{print $2; exit}' /etc/login.defs); [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -le 365 ]] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[144] PASS_MIN_DAYS ≥ 1"
grep -Eq '^\s*PASS_MIN_DAYS\s+[1-9][0-9]*' /etc/login.defs && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[145] PASS_WARN_AGE ≥ 7"
grep -Eq '^\s*PASS_WARN_AGE\s+([7-9]|[1-9][0-9]+)' /etc/login.defs && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[146] inactive ≥ 30 (para contas válidas)"
awk -F: '$2~/^\$/{print $1}' /etc/shadow | xargs -r -I{} chage -l {} | grep -Eq 'Inactive.*(3[0-9]|[4-9][0-9]+)' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[147] campo 3 != 0"
awk -F: '$2~/^\$/{if($3==""||$3==0) exit 1} END{exit 0}' /etc/shadow && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[148] Root é o único UID 0"
awk -F: '($3==0 && $1!="root"){found=1} END{if(found) exit 1}' /etc/passwd && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[149] Root é o único GID 0"
[ "$(awk -F: '/^root:/ {print $4}' /etc/passwd)" = "0" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[150] Contas de sistema com shell interativo"
awk -F: '($3<1000 && $1!="root" && $7 ~ /(bash|sh|zsh)$/){exit 1} END{exit 0}' /etc/passwd && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[152] PATH do root configurado corretamente"
grep -Eq '^PATH=\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin' /root/.bash_profile && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[153] umask global configurado como 027"
grep -Rqs '^\s*umask\s\+027\b' /etc/profile /etc/bashrc /etc/profile.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[154] TMOUT configurado como 900 ou mais"
grep -Rqs '^\s*TMOUT\s*=\s*(900|9[0-9]{2}|[1-9][0-9]{3,})' /etc/profile /etc/bashrc /etc/profile.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[155] Ausência de regras amplas (%grupo ALL=(ALL))"
grep -RqsE '^%.*ALL=\(ALL\)' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[156] sudo usa pty"
grep -Rqs 'Defaults\s\+use_pty' /etc/sudoers /etc/sudoers.d && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[157] sudo tem logfile configurado"
grep -Rqs 'Defaults\s\+logfile=' /etc/sudoers /etc/sudoers.d && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[158] !authenticate não está presente"
grep -Rqs 'Defaults\s\+!authenticate' /etc/sudoers /etc/sudoers.d && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[159] timestamp_timeout = 5"
grep -Rqs 'timestamp_timeout=5' /etc/sudoers /etc/sudoers.d && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[160] su restrito ao grupo wheel"
grep -Eq '^auth\s+(required|requisite)\s+pam_wheel\.so' /etc/pam.d/su && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[161] Stack de logs racionalizado"
( systemctl is-active rsyslog &>/dev/null || systemctl is-active systemd-journald &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[162] Journald configurado"
( systemd-analyze cat-config systemd/journald.conf* 2>/dev/null | grep -Eq 'SystemMaxUse=' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[163] Rsyslog instalado e ativo"
( rpm -q rsyslog &>/dev/null && systemctl is-active rsyslog &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[164] Logrotate para rsyslog"
( grep -Eq 'rsyslog' /etc/logrotate.d/* 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[165] auditd instalado e rodando"
( rpm -q audit audit-libs &>/dev/null && systemctl is-active auditd &>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[166] Auditoria antes do auditd"
( grep -Eq 'grubby.*audit=1' /etc/default/grub /etc/sysconfig/grub 2>/dev/null || grep -Eq '\baudit=1\b' /proc/cmdline ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[167] Tamanho de armazenamento de audit log"
( grep -Eq '^\s*max_log_file\s*=\s*[1-9]' /etc/audit/auditd.conf ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[168] Logs de auditoria não excluídos automaticamente"
( grep -Eq '^\s*max_log_file_action\s*=\s*(keep_logs|rotate)' /etc/audit/auditd.conf ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[169] Auditoria de alterações em data/hora"
( auditctl -l 2>/dev/null | grep -Eq 'adjtimex|settimeofday|clock_settime' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[170] Auditoria de alterações em contas/grupos"
( auditctl -l 2>/dev/null | grep -Eq '/etc/(passwd|shadow|group|gshadow)' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[171] Auditoria de alterações no ambiente de rede"
( auditctl -l 2>/dev/null | grep -Eq 'sethostname|setdomainname|/etc/hosts|/etc/hostname' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[172] Auditoria de eventos MAC"
( auditctl -l 2>/dev/null | grep -Eq 'mac_policy|MAC_POLICY_LOAD' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[173] Auditoria de login/logout"
( auditctl -l 2>/dev/null | grep -Eq '/var/log/faillog|/var/log/lastlog|/var/run/utmp' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[174] Auditoria de permissões DAC"
( auditctl -l 2>/dev/null | grep -Eq 'chmod|chown|fchmod|fchown' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[175] Auditoria de acessos não autorizados"
( auditctl -l 2>/dev/null | grep -Eq 'EACCES|EPERM' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[176] Auditoria de comandos privilegiados"
( find / -xdev -perm -4000 2>/dev/null | xargs -r -I{} auditctl -l 2>/dev/null | grep -q {} ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[177] Auditoria de mount/unmount"
( auditctl -l 2>/dev/null | grep -Eq 'mount|umount' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[178] Auditoria de deleção de arquivos"
( auditctl -l 2>/dev/null | grep -Eq 'unlink|rename|rmdir|unlinkat|renameat' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[179] Auditoria de kernel modules"
( auditctl -l 2>/dev/null | grep -Eq 'init_module|finit_module|delete_module' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[180] Auditoria de sudoers/logs de sudo"
( auditctl -l 2>/dev/null | grep -Eq '/etc/sudoers|/etc/sudoers.d' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[181] Configuração de auditoria imutável"
( auditctl -l 2>/dev/null | grep -Eq '^-e 2' ) && echo "⚠️ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[182] AIDE instalado e inicializado"
( rpm -q aide &>/dev/null && [ -f /var/lib/aide/aide.db.gz ] ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[183] Verificação de integridade agendada"
( grep -Ersq 'aide(\.wrapper)? .*(--check|--update|\$AIDEARGS)' /etc/cron.* /etc/crontab /var/spool/cron 2>/dev/null || systemctl list-timers --all 2>/dev/null | grep -qi aime ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[184] Proteção dos binários de auditoria"
( stat -Lc "%a %U %G" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules 2>/dev/null | awk '{if($1+0>750 || $2!="root" || $3!="root") exit 1}' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[185] Verificar permissões de /etc/passwd"
( [ -f /etc/passwd ] && stat -Lc "%a %u %g" /etc/passwd | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[186] Verificar permissões de /etc/passwd-"
( [ -f /etc/passwd- ] && stat -Lc "%a %u %g" /etc/passwd- | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[187] Verificar permissões de /etc/shadow"
( [ -f /etc/shadow ] && stat -Lc "%a %u %g" /etc/shadow | grep -Eq '^0+ 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[188] Verificar permissões de /etc/shadow-"
( [ -f /etc/shadow- ] && stat -Lc "%a %u %g" /etc/shadow- | grep -Eq '^0+ 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[189] Verificar permissões de /etc/gshadow-"
( [ -f /etc/gshadow- ] && stat -Lc "%a %u %g" /etc/gshadow- | grep -Eq '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[190] Verificar permissões de /etc/gshadow"
( [ -f /etc/gshadow ] && stat -Lc "%a %u %g" /etc/gshadow | grep -Eq '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[191] Verificar permissões de /etc/group"
( [ -f /etc/group ] && stat -Lc "%a %u %g" /etc/group | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[192] Verificar permissões de /etc/group-"
( [ -f /etc/group- ] && stat -Lc "%a %u %g" /etc/group- | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[193] Verificar se /etc/shells não lista nologin"
( grep -Eq 'nologin' /etc/shells ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[194] Verificar permissões de /etc/security/opasswd"
( [ -f /etc/security/opasswd ] && stat -Lc "%a %u %g" /etc/security/opasswd | grep -Eq '^600 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[195] Verificar existência de arquivos órfãos (UID/GID sem dono)"
( find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[196] Verificar world-writable fora de áreas permitidas"
( find / -xdev -not -path "/tmp/*" -not -path "/var/tmp/*" -not -path "/dev/shm/*" -perm -0002 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[197] Verificar arquivos/diretórios sem owner ou group"
( find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[198] Verificar binários SUID/SGID"
( find / -xdev \( -perm -4000 -o -perm -2000 \) 2>/dev/null | grep -q . ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[199] Verificar se usuários possuem diretório home válido"
( awk -F: '$3>=1000 && $1!="nfsnobody" {print $6}' /etc/passwd | while read h; do [ -d "$h" ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[200] Verificar ownership das homes dos usuários"
( awk -F: '$3>=1000 && $1!="nfsnobody" {print $1,$6}' /etc/passwd | while read u h; do [ -d "$h" ] && [ "$(stat -Lc %U "$h")" = "$u" ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[201] Verificar permissões das homes (<=750)"
( awk -F: '$3>=1000 && $1!="nfsnobody"{print $6}' /etc/passwd | while read h; do [ -d "$h" ] && [ "$(stat -Lc %a "$h")" -le 750 ] || exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[202] Verificar dotfiles inseguros nas homes"
( awk -F: '$3>=1000 && $1!="nfsnobody"{print $6}' /etc/passwd | while read h; do find "$h" -maxdepth 1 -type f -name ".*" -perm /022 2>/dev/null | grep -q . && exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[203] Verificar arquivos .forward/.netrc/.rhosts nas homes"
( awk -F: '$3>=1000 && $1!="nfsnobody"{print $6}' /etc/passwd | while read h; do [ -e "$h/.forward" ] || [ -e "$h/.netrc" ] || [ -e "$h/.rhosts" ] && exit 1; done ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
