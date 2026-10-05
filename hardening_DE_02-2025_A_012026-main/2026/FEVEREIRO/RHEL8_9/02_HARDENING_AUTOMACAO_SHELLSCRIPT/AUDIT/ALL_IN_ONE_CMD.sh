(modinfo cramfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+cramfs\b' && ! lsmod | grep -q cramfs) || (! modinfo cramfs )
(modinfo squashfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+squashfs\b' && ! lsmod | grep -q squashfs) || (! modinfo squashfs )
(modinfo udf  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+udf\b' && ! lsmod | grep -q udf) || (! modinfo udf )
(modinfo hfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+hfs\b' && ! lsmod | grep -q hfs) || (! modinfo hfs )
(modinfo hfsplus  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+hfsplus\b' && ! lsmod | grep -q hfsplus) || (! modinfo hfsplus )
(modinfo jffs2  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+jffs2\b' && ! lsmod | grep -q jffs2) || (! modinfo jffs2 )
(modinfo freevxfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+freevxfs\b' && ! lsmod | grep -q freevxfs) || (! modinfo freevxfs )
(modinfo overlay  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+overlay\b' && ! lsmod | grep -q overlay) || (! modinfo overlay )
(modinfo usb-storage  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+usb_storage\b' && ! lsmod | grep -q usb_storage) || (! modinfo usb-storage )
(modinfo dccp  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+dccp\b' && ! lsmod | grep -q dccp) || (! modinfo dccp )
(modinfo sctp  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+sctp\b' && ! lsmod | grep -q sctp) || (! modinfo sctp )
(modinfo rds  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+rds\b' && ! lsmod | grep -q rds) || (! modinfo rds )
(modinfo tipc  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+tipc\b' && ! lsmod | grep -q tipc) || (! modinfo tipc )
(ulimit -c 0 && sysctl -n fs.suid_dumpable | grep -q '^0$')
(sysctl -n kernel.yama.ptrace_scope | grep -q '^[1-3]$')
(grep -q 'nx' /proc/cpuinfo && dmesg | grep -qi 'NX.*active')
(sysctl -n kernel.randomize_va_space | grep -q '^2$')
(grep -q 'iommu=on' /proc/cmdline)
(sysctl -n kernel.perf_event_paranoid | grep -q '^[2-3]$')
(sysctl -n kernel.dmesg_restrict | grep -q '^1$')
(sysctl -n kernel.unprivileged_userns_clone | grep -q '^0$' )
(sysctl -n fs.protected_symlinks | grep -q '^1$')
(sysctl -n fs.protected_hardlinks | grep -q '^1$')
(sysctl -n fs.suid_dumpable | grep -q '^0$')
(findmnt -kn /tmp );
(findmnt -kn /dev/shm );
(findmnt -kn /var );
(findmnt -kn /var/tmp );
(findmnt -kn /var/log );
(findmnt -kn /var/log/audit );
(findmnt -kn /home );
(findmnt -kn /historico );
(findmnt -kn /crash );
(findmnt -kn /UNIX );
(grep -E 'nodev|nosuid|noexec' /etc/fstab )
(findmnt -n /var | grep -Eq 'nodev|nosuid|noexec')
(findmnt -n /tmp | grep -Eq 'nodev|nosuid|noexec')
(findmnt -n /dev/shm | grep -Eq 'nodev|nosuid|noexec')
(findmnt -n /var/tmp | grep -Eq 'nodev|nosuid|noexec')
(findmnt -n /var/log | grep -Eq 'nodev|nosuid|noexec')
(findmnt -n /var/log/audit | grep -Eq 'nodev|nosuid|noexec')
(findmnt -n /home | grep -qw nodev)
(grep -E 'nodev|nosuid|noexec' /etc/fstab | grep -E '/media|/run/media' )
(find / -xdev -type d -perm -0002 ! -perm -1000 | grep .)
(stat -c "%A" /tmp | grep -q 't')
(stat -c "%A" /var/tmp | grep -q 't')
(stat -c "%A" /dev/shm | grep -q 't')
(systemctl is-enabled autofs )
(grep -q 'password_pbkdf2' /boot/grub2/grub.cfg)
(stat -Lc '%a %U %G' /boot/grub2/grub.cfg | grep -Eq '^(400|600) root root$')
(grep -q '^ExecStart=-/bin/sh' /usr/lib/systemd/system/emergency.service)
(getenforce | grep -Eq 'Enforcing|Permissive')
(sestatus | grep -q 'Loaded policy name')
(ps -eZ | grep -q 'unconfined_service_t')
(ps -eZ | grep -q 'unconfined_t')
(rpm -q prelink )
(rpm -q xinetd )
( systemctl is-active --quiet chronyd  || systemctl is-active --quiet ntpd  || systemctl is-active --quiet systemd-timesyncd  )
( ! rpm -q chrony  || ( systemctl is-enabled chronyd  && grep -q '^server' /etc/chrony.conf ) )
( ! rpm -q ntp  || ( systemctl is-enabled ntpd  && grep -q '^server' /etc/ntp.conf ) )
(rpm -q xorg-x11-server-common )
(rpm -q avahi )
(rpm -q cups )
(rpm -q dhcp-server )
(rpm -q openldap-servers )
(rpm -q bind )
(rpm -q vsftpd )
(rpm -q httpd )
(rpm -q dovecot )
(rpm -q samba )
(rpm -q squid )
(rpm -q net-snmp )
(rpm -q ypserv )
(rpm -q telnet-server )
( [ ! -f /etc/postfix/main.cf ] || grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*(localhost|loopback-only)\b' /etc/postfix/main.cf )
(systemctl is-enabled nfs-server )
(systemctl is-enabled rpcbind )
(systemctl is-enabled rsyncd )
(rpm -q ypbind )
(rpm -q rsh )
(rpm -q talk )
(rpm -q telnet )
(rpm -q openldap-clients )
(systemctl list-unit-files --state=enabled | grep -Eq 'avahi|cups|telnet|ftp|nis|tftp|xinetd')
(rpm -q tftp-server )
( grep -Eq 'polkit.Result.YES|allow' /etc/polkit-1/rules.d/*.rules)
(grep -Eq '^gpgcheck\s*=\s*1' /etc/yum.conf /etc/yum.repos.d/*.repo)
(dnf check-update --security )
( ( systemctl is-active --quiet chronyd  && ! systemctl is-active --quiet ntpd  && ! systemctl is-active --quiet systemd-timesyncd  ) || ( ! systemctl is-active --quiet chronyd  && systemctl is-active --quiet ntpd  && ! systemctl is-active --quiet systemd-timesyncd  ) || ( ! systemctl is-active --quiet chronyd  && ! systemctl is-active --quiet ntpd  && systemctl is-active --quiet systemd-timesyncd  ) )
(stat -Lc '%a %U %G' /etc/cron.allow | grep -Eq '^640 root (root|crontab)$')
(sysctl -n net.ipv4.ip_forward | grep -q '^0$' && sysctl -n net.ipv6.conf.all.forwarding | grep -q '^0$')
(sysctl -n net.ipv4.conf.all.send_redirects | grep -q '^0$')
(sysctl -n net.ipv4.conf.all.accept_source_route | grep -q '^0$')
(sysctl -n net.ipv4.conf.all.accept_redirects | grep -q '^0$' && sysctl -n net.ipv4.conf.all.secure_redirects | grep -q '^0$')
(sysctl -n net.ipv4.conf.all.rp_filter | grep -Eq '^[12]$')
(sysctl -n net.ipv4.icmp_echo_ignore_broadcasts | grep -q '^1$')
(sysctl -n net.ipv4.icmp_ignore_bogus_error_responses | grep -q '^1$')
(sysctl -n net.ipv4.tcp_syncookies | grep -q '^1$')
(sysctl -n net.ipv6.conf.all.disable_ipv6 | grep -q '^1$')
(firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type timestamp-request -j DROP  || nft list ruleset | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-request[[:space:]]+drop' || iptables -L INPUT -n | grep -qi 'icmp type timestamp-request.*DROP')
(iptables -L INPUT -v -n | grep -q 'icmp type timestamp-reply.*DROP')
( firewall-cmd --direct --query-rule ipv4 filter INPUT 0 -p icmp --icmp-type timestamp-reply -j DROP || nft list ruleset | grep -Eqi 'icmp[[:space:]]+type[[:space:]]+timestamp-reply[[:space:]]+drop' || iptables -L INPUT -n | grep -qi 'icmp type timestamp-reply.*DROP' )
(lsmod | grep -Eq 'bluetooth|iwlwifi')
(iptables -L INPUT   -n | grep -q "policy DROP" && iptables -L FORWARD -n | grep -q "policy DROP" && iptables -L OUTPUT  -n | grep -q "policy DROP")
( [ "$(printf "%s\n" "$(systemctl is-active firewalld  2>&1 && echo F)" "$(iptables -L  2>&1 && echo F)" "$(ip6tables -L  2>&1 && echo F)" | grep -c F)" -eq 1 ] )
(iptables -L INPUT -n | grep -q "lo .* ACCEPT" && iptables -L INPUT -n | grep -Eq "ESTABLISHED|RELATED" && iptables -L OUTPUT -n | grep -q "ACCEPT")
(ss -tuln | awk 'NR>1 {print $5}' | sed 's/.*://g' | sort -u | grep -v '^$' | while read P; do iptables -L INPUT -n | grep -q ":${P} " || exit 1; done && exit 0)
(iptables-save | grep -q ".")
(grep -Eq "(TLSv1\.2|TLSv1\.3)" /etc/crypto-policies/config || grep -Eq "(MinProtocol.*TLSv1\.2|ssl_protocol.*TLSv1\.2)" /etc/httpd/conf.d/* || grep -Eq "(ssl_protocol.*TLSv1\.2)" /etc/nginx/*)
( stat -c %a /etc/ssh/sshd_config | grep -Eq '^(600|400)$' && [ "$(stat -c %U:%G /etc/ssh)" = "root:root" ] )
(grep -Eq '^[[:space:]]*(AllowUsers|DenyUsers|AllowGroups|DenyGroups)' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*LogLevel[[:space:]]+(INFO|VERBOSE)' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*X11Forwarding[[:space:]]+no' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*MaxAuthTries[[:space:]]+[1-4]$' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*IgnoreRhosts[[:space:]]+yes' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*HostbasedAuthentication[[:space:]]+no' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+(no|prohibit-password)' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*PermitEmptyPasswords[[:space:]]+no' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*PermitUserEnvironment[[:space:]]+no' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*UsePAM[[:space:]]+yes' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*ClientAliveInterval[[:space:]]+([1-9][0-9]|[1-2][0-9]{2}|300)$' /etc/ssh/sshd_config && grep -Eq '^[[:space:]]*ClientAliveCountMax[[:space:]]+[1-3]$' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*LoginGraceTime[[:space:]]+([1-9][0-9]|[1-5][0-9]{2})s?$' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*MaxStartups[[:space:]]+.+$' /etc/ssh/sshd_config && grep -Eq '^[[:space:]]*MaxSessions[[:space:]]+[1-9]+' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*AllowTcpForwarding[[:space:]]+no' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*Banner[[:space:]]+/.*' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*Ciphers[[:space:]]+.*(chacha20|aes256).*' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*MACs[[:space:]]+.*(hmac-sha2|umac).*' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*KexAlgorithms[[:space:]]+.*(curve25519|diffie-hellman-group-exchange-sha256).*' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*(Ciphers|KexAlgorithms)[[:space:]]+.*(chacha20|curve25519).*' /etc/ssh/sshd_config)
(grep -Eq '^[[:space:]]*(ForceCommand|ChrootDirectory)[[:space:]]+' /etc/ssh/sshd_config)
grep -Eq 'pam_pwquality\.so' /etc/pam.d/*auth
grep -Eq 'pam_faillock\.so' /etc/pam.d/*auth
! grep -Eq 'pam_tally2\.so' /etc/pam.d/*auth
grep -Eq 'pam_pwhistory\.so' /etc/pam.d/*auth
grep -Psiq '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]+)' /etc/security/pwquality.conf*
grep -Psiq '^\s*minclass\s*=\s*[4-9]' /etc/security/pwquality.conf*
grep -Psiq '^\s*maxrepeat\s*=\s*3\b'   /etc/security/pwquality.conf*
grep -Psiq '^\s*maxsequence\s*=\s*3\b' /etc/security/pwquality.conf*
! grep -Psiq '^\s*dictcheck\s*=\s*0\b' /etc/security/pwquality.conf*
grep -Eq 'pam_unix\.so.*(sha512|yescrypt)' /etc/pam.d/*auth
grep -Eq 'pam_pwhistory\.so.*remember=[5-9]' /etc/pam.d/*auth
grep -Pi '^\s*deny\s*=\s*([5-9]|[1-9][0-9]+)' /etc/security/faillock.conf
grep -Pi '^\s*unlock_time\s*=\s*(9[0-9]{2}|[1-9][0-9]{3,})\b' /etc/security/faillock.conf
val=$(awk '$1=="PASS_MAX_DAYS"{print $2; exit}' /etc/login.defs); [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -le 365 ]]
grep -Eq '^\s*PASS_MIN_DAYS\s+[1-9][0-9]*' /etc/login.defs
grep -Eq '^\s*PASS_WARN_AGE\s+([7-9]|[1-9][0-9]+)' /etc/login.defs
awk -F: '$2~/^\$/{print $1}' /etc/shadow | xargs -r -I{} chage -l {} | grep -Eq 'Inactive.*(3[0-9]|[4-9][0-9]+)'
awk -F: '$2~/^\$/{if($3==""||$3==0) exit 1} END{exit 0}' /etc/shadow
awk -F: '($3==0 && $1!="root"){found=1} END{if(found) exit 1}' /etc/passwd
[ "$(awk -F: '/^root:/ {print $4}' /etc/passwd)" = "0" ]
awk -F: '($3<1000 && $1!="root" && $7 ~ /(bash|sh|zsh)$/){exit 1} END{exit 0}' /etc/passwd
grep -Eq '^PATH=\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin' /root/.bash_profile
grep -Rqs '^\s*umask\s\+027\b' /etc/profile /etc/bashrc /etc/profile.d
grep -Rqs '^\s*TMOUT\s*=\s*(900|9[0-9]{2}|[1-9][0-9]{3,})' /etc/profile /etc/bashrc /etc/profile.d
grep -RqsE '^%.*ALL=\(ALL\)' /etc/sudoers /etc/sudoers.d
grep -Rqs 'Defaults\s\+use_pty' /etc/sudoers /etc/sudoers.d
grep -Rqs 'Defaults\s\+logfile=' /etc/sudoers /etc/sudoers.d
grep -Rqs 'Defaults\s\+!authenticate' /etc/sudoers /etc/sudoers.d
grep -Rqs 'timestamp_timeout=5' /etc/sudoers /etc/sudoers.d
grep -Eq '^auth\s+(required|requisite)\s+pam_wheel\.so' /etc/pam.d/su
( systemctl is-active rsyslog  || systemctl is-active systemd-journald  )
( systemd-analyze cat-config systemd/journald.conf* | grep -Eq 'SystemMaxUse=' )
( rpm -q rsyslog  && systemctl is-active rsyslog  )
( grep -Eq 'rsyslog' /etc/logrotate.d/* )
( rpm -q audit audit-libs  && systemctl is-active auditd  )
( grep -Eq 'grubby.*audit=1' /etc/default/grub /etc/sysconfig/grub || grep -Eq '\baudit=1\b' /proc/cmdline )
( grep -Eq '^\s*max_log_file\s*=\s*[1-9]' /etc/audit/auditd.conf )
( grep -Eq '^\s*max_log_file_action\s*=\s*(keep_logs|rotate)' /etc/audit/auditd.conf )
( auditctl -l | grep -Eq 'adjtimex|settimeofday|clock_settime' )
( auditctl -l | grep -Eq '/etc/(passwd|shadow|group|gshadow)' )
( auditctl -l | grep -Eq 'sethostname|setdomainname|/etc/hosts|/etc/hostname' )
( auditctl -l | grep -Eq 'mac_policy|MAC_POLICY_LOAD' )
( auditctl -l | grep -Eq '/var/log/faillog|/var/log/lastlog|/var/run/utmp' )
( auditctl -l | grep -Eq 'chmod|chown|fchmod|fchown' )
( auditctl -l | grep -Eq 'EACCES|EPERM' )
( find / -xdev -perm -4000 | xargs -r -I{} auditctl -l | grep -q {} )
( auditctl -l | grep -Eq 'mount|umount' )
( auditctl -l | grep -Eq 'unlink|rename|rmdir|unlinkat|renameat' )
( auditctl -l | grep -Eq 'init_module|finit_module|delete_module' )
( auditctl -l | grep -Eq '/etc/sudoers|/etc/sudoers.d' )
( auditctl -l | grep -Eq '^-e 2' )
( rpm -q aide  && [ -f /var/lib/aide/aide.db.gz ] )
( grep -Ersq 'aide(\.wrapper)? .*(--check|--update|\$AIDEARGS)' /etc/cron.* /etc/crontab /var/spool/cron || systemctl list-timers --all | grep -qi aime )
( stat -Lc "%a %U %G" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules | awk '{if($1+0>750 || $2!="root" || $3!="root") exit 1}' )
( [ -f /etc/passwd ] && stat -Lc "%a %u %g" /etc/passwd | grep -Eq '^64[0-9] 0 0$' )
( [ -f /etc/passwd- ] && stat -Lc "%a %u %g" /etc/passwd- | grep -Eq '^64[0-9] 0 0$' )
( [ -f /etc/shadow ] && stat -Lc "%a %u %g" /etc/shadow | grep -Eq '^0+ 0 0$' )
( [ -f /etc/shadow- ] && stat -Lc "%a %u %g" /etc/shadow- | grep -Eq '^0+ 0 0$' )
( [ -f /etc/gshadow- ] && stat -Lc "%a %u %g" /etc/gshadow- | grep -Eq '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' )
( [ -f /etc/gshadow ] && stat -Lc "%a %u %g" /etc/gshadow | grep -Eq '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' )
( [ -f /etc/group ] && stat -Lc "%a %u %g" /etc/group | grep -Eq '^64[0-9] 0 0$' )
( [ -f /etc/group- ] && stat -Lc "%a %u %g" /etc/group- | grep -Eq '^64[0-9] 0 0$' )
( grep -Eq 'nologin' /etc/shells )
( [ -f /etc/security/opasswd ] && stat -Lc "%a %u %g" /etc/security/opasswd | grep -Eq '^600 0 0$' )
( find / -xdev \( -nouser -o -nogroup \) | grep -q . )
( find / -xdev -not -path "/tmp/*" -not -path "/var/tmp/*" -not -path "/dev/shm/*" -perm -0002 | grep -q . )
( find / -xdev \( -nouser -o -nogroup \) | grep -q . )
( find / -xdev \( -perm -4000 -o -perm -2000 \) | grep -q . )
( awk -F: '$3>=1000 && $1!="nfsnobody" {print $6}' /etc/passwd | while read h; do [ -d "$h" ] || exit 1; done )
( awk -F: '$3>=1000 && $1!="nfsnobody" {print $1,$6}' /etc/passwd | while read u h; do [ -d "$h" ] && [ "$(stat -Lc %U "$h")" = "$u" ] || exit 1; done )
( awk -F: '$3>=1000 && $1!="nfsnobody"{print $6}' /etc/passwd | while read h; do [ -d "$h" ] && [ "$(stat -Lc %a "$h")" -le 750 ] || exit 1; done )
( awk -F: '$3>=1000 && $1!="nfsnobody"{print $6}' /etc/passwd | while read h; do find "$h" -maxdepth 1 -type f -name ".*" -perm /022 | grep -q . && exit 1; done )
( awk -F: '$3>=1000 && $1!="nfsnobody"{print $6}' /etc/passwd | while read h; do [ -e "$h/.forward" ] || [ -e "$h/.netrc" ] || [ -e "$h/.rhosts" ] && exit 1; done )
