#!/bin/bash
(( ! modinfo cramfs &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+cramfs\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+cramfs\b' && ! lsmod | awk '{print $1}' | grep -qx cramfs )) && echo PASS || echo FAIL
(( ! modinfo squashfs &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+squashfs\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+squashfs\b' && ! lsmod | awk '{print $1}' | grep -qx squashfs )) && echo PASS || echo FAIL
(( ! modinfo udf &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+udf\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+udf\b' && ! lsmod | awk '{print $1}' | grep -qx udf )) && echo PASS || echo FAIL
(( ! modinfo hfs &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+hfs\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+hfs\b' && ! lsmod | awk '{print $1}' | grep -qx hfs )) && echo PASS || echo FAIL
(( ! modinfo hfsplus &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+hfsplus\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+hfsplus\b' && ! lsmod | awk '{print $1}' | grep -qx hfsplus )) && echo PASS || echo FAIL
(( ! modinfo jffs2 &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+jffs2\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+jffs2\b' && ! lsmod | awk '{print $1}' | grep -qx jffs2 )) && echo PASS || echo FAIL
(( ! modinfo freevxfs &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+freevxfs\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+freevxfs\b' && ! lsmod | awk '{print $1}' | grep -qx freevxfs )) && echo PASS || echo FAIL
(( ! modinfo usb_storage &>/dev/null ) || ( modprobe --showconfig | grep -P '^\s*install\s+usb_storage\s+/(bin|sbin)/(true|false)\b' && modprobe --showconfig | grep -P '^\s*blacklist\s+usb_storage\b' && ! lsmod | awk '{print $1}' | grep -qx usb_storage )) && echo PASS || echo FAIL
( sysctl -n fs.suid_dumpable 2>/dev/null | grep -qx 0 && grep -REq '^\s*fs\.suid_dumpable\s*=\s*0\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n kernel.randomize_va_space 2>/dev/null | grep -qx 2 && grep -REq '^\s*kernel\.randomize_va_space\s*=\s*2\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n kernel.perf_event_paranoid 2>/dev/null | grep -Eq '^[23]$' && grep -REq '^\s*kernel\.perf_event_paranoid\s*=\s*[23]\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n kernel.dmesg_restrict 2>/dev/null | grep -qx 1 && grep -REq '^\s*kernel\.dmesg_restrict\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n fs.protected_symlinks 2>/dev/null | grep -qx 1 && grep -REq '^\s*fs\.protected_symlinks\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n fs.protected_hardlinks 2>/dev/null | grep -qx 1 && grep -REq '^\s*fs\.protected_hardlinks\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( grep -E '\s/(media|mnt)\s' /etc/fstab | grep -Eq '\bnodev\b' ) && echo PASS || echo FAIL
( grep -E '\s/(var|home|tmp|var/tmp|var/log|var/log/audit)\s' /etc/fstab | grep -Eq '\bnodev\b' && grep -E '\s/(var|home|tmp|var/tmp|var/log|var/log/audit)\s' /etc/fstab | grep -Eq '\bnosuid\b' ) && echo PASS || echo FAIL
( findmnt -n /var/log -o OPTIONS | grep -Eq '\bnodev\b' && findmnt -n /var/log -o OPTIONS | grep -Eq '\bnosuid\b' ) && echo PASS || echo FAIL
( findmnt -n /var/log/audit -o OPTIONS | grep -Eq '\bnodev\b' && findmnt -n /var/log/audit -o OPTIONS | grep -Eq '\bnosuid\b' ) && echo PASS || echo FAIL
( findmnt -n /home -o OPTIONS | grep -Eq '\bnodev\b' ) && echo PASS || echo FAIL
( ! df --local -P | awk 'NR>1{print $6}' | xargs -I{} find {} -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -q . ) && echo PASS || echo FAIL
( stat -c '%a' /tmp 2>/dev/null | grep -Eq '1[0-7][0-7][0-7]' ) && echo PASS || echo FAIL
( stat -c '%a' /var/tmp 2>/dev/null | grep -Eq '1[0-7][0-7][0-7]' ) && echo PASS || echo FAIL
( stat -c '%a' /dev/shm 2>/dev/null | grep -Eq '1[0-7][0-7][0-7]' ) && echo PASS || echo FAIL
( ! rpm -q prelink &>/dev/null ) && echo PASS || echo FAIL
( systemctl is-enabled xinetd 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( systemctl is-enabled chronyd 2>/dev/null | grep -qx enabled ) && echo PASS || echo FAIL
( grep -Eq '^\s*server\s+\S+' /etc/chrony.conf 2>/dev/null ) && echo PASS || echo FAIL
( systemctl is-enabled chronyd 2>/dev/null | grep -qx enabled ) && echo PASS || echo FAIL
( ! rpm -qa | grep -Eq '^(xorg-x11|xorg-x11-server)' ) && echo PASS || echo FAIL
( systemctl is-enabled avahi-daemon 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( systemctl is-enabled cups 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( ! rpm -qa | grep -Eq '^(dovecot|cyrus-imapd)' ) && echo PASS || echo FAIL
( ! rpm -q samba &>/dev/null ) && echo PASS || echo FAIL
( ! rpm -qa | grep -Eq '^squid' ) && echo PASS || echo FAIL
( systemctl is-enabled snmpd 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( ! rpm -q ypserv &>/dev/null ) && echo PASS || echo FAIL
( ! rpm -q telnet-server &>/dev/null ) && echo PASS || echo FAIL
( postconf -n 2>/dev/null | grep -Eq '^\s*inet_interfaces\s*=\s*localhost\b' ) && echo PASS || echo FAIL
( systemctl is-enabled nfs-server 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( systemctl is-enabled rpcbind 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( systemctl is-enabled rsyncd 2>/dev/null | grep -qx disabled ) && echo PASS || echo FAIL
( ! rpm -q ypbind &>/dev/null ) && echo PASS || echo FAIL
( ! rpm -qa | grep -Eq '^rsh(-|$)' ) && echo PASS || echo FAIL
( ! rpm -qa | grep -Eq '^talk(-|$)' ) && echo PASS || echo FAIL
( ! rpm -q telnet &>/dev/null ) && echo PASS || echo FAIL
( ! rpm -q openldap-clients &>/dev/null ) && echo PASS || echo FAIL
( ! systemctl list-unit-files --type=service | awk '$2!~/^(enabled|disabled|static|masked)$/ {print}' | grep -q . ) && echo PASS || echo FAIL
( ! rpm -q tftp-server &>/dev/null ) && echo PASS || echo FAIL
( grep -REq '^[^#].+' /etc/polkit-1/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( ! grep -L '^\s*gpgcheck\s*=\s*1\b' /etc/yum.repos.d/*.repo 2>/dev/null | grep -q . ) && echo PASS || echo FAIL
( yum check-update -q >/dev/null 2>&1; [ $? -eq 0 ] ) && echo PASS || echo FAIL
( [ "$(systemctl list-unit-files | awk '$1=="chronyd.service" && $2=="enabled"' | wc -l)" -eq 1 ] ) && echo PASS || echo FAIL
( [ -f /etc/cron.allow ] && [ -f /etc/at.allow ] && grep -qx root /etc/cron.allow && grep -qx root /etc/at.allow ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null | grep -qx 0 && sysctl -n net.ipv4.conf.default.send_redirects 2>/dev/null | grep -qx 0 && grep -REq 'net\.ipv4\.conf\.(all|default)\.send_redirects\s*=\s*0\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -qx 0 && sysctl -n net.ipv4.conf.default.accept_source_route 2>/dev/null | grep -qx 0 && grep -REq 'net\.ipv4\.conf\.(all|default)\.accept_source_route\s*=\s*0\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -qx 0 && sysctl -n net.ipv4.conf.default.accept_redirects 2>/dev/null | grep -qx 0 && grep -REq 'net\.ipv4\.conf\.(all|default)\.accept_redirects\s*=\s*0\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null | grep -qx 1 && sysctl -n net.ipv4.conf.default.rp_filter 2>/dev/null | grep -qx 1 && grep -REq 'net\.ipv4\.conf\.(all|default)\.rp_filter\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -qx 1 && grep -REq 'net\.ipv4\.icmp_echo_ignore_broadcasts\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.icmp_ignore_bogus_error_responses 2>/dev/null | grep -qx 1 && grep -REq 'net\.ipv4\.icmp_ignore_bogus_error_responses\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( sysctl -n net.ipv4.tcp_syncookies 2>/dev/null | grep -qx 1 && grep -REq 'net\.ipv4\.tcp_syncookies\s*=\s*1\b' /etc/sysctl.conf /etc/sysctl.d/* ) && echo PASS || echo FAIL
( iptables -L INPUT -n 2>/dev/null | grep -Eq 'icmp.*timestamp-request.*(DROP|REJECT)' ) && echo PASS || echo FAIL
( iptables -L INPUT -n 2>/dev/null | grep -Eq 'icmp.*timestamp-reply.*(DROP|REJECT)' ) && echo PASS || echo FAIL
( ! nmcli -t -f TYPE device status 2>/dev/null | grep -Eq '^(wifi|bluetooth)$' ) && echo PASS || echo FAIL
( [ "$(systemctl is-enabled firewalld 2>/dev/null)" = "enabled" ] && [ "$(systemctl is-enabled iptables 2>/dev/null)" != "enabled" ] || [ "$(systemctl is-enabled firewalld 2>/dev/null)" != "enabled" ] && [ "$(systemctl is-enabled iptables 2>/dev/null)" = "enabled" ] ) && echo PASS || echo FAIL
( iptables -L INPUT -n 2>/dev/null | grep -Eq 'ACCEPT\s+all\s+--\s+lo\s' && iptables -L INPUT -n 2>/dev/null | grep -Eq 'ESTABLISHED,RELATED' ) && echo PASS || echo FAIL
( [ -f /etc/sysconfig/iptables ] || systemctl is-enabled firewalld 2>/dev/null | grep -qx enabled ) && echo PASS || echo FAIL
( stat -c '%a %U %G' /etc/ssh/sshd_config 2>/dev/null | grep -Eq '^(600|640) root root$' && stat -c '%a %U %G' /etc/ssh 2>/dev/null | grep -Eq '^(700|750) root root$' ) && echo PASS || echo FAIL
( grep -Eiq '^\s*SyslogFacility\s+AUTHPRIV\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*X11Forwarding\s+no\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*MaxAuthTries\s+[1-4]\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*IgnoreRhosts\s+yes\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*HostbasedAuthentication\s+no\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*PermitRootLogin\s+(no|prohibit-password)\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*PermitEmptyPasswords\s+no\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*PermitUserEnvironment\s+no\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*UsePAM\s+yes\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*ClientAliveInterval\s+[1-9][0-9]*\b' /etc/ssh/sshd_config && grep -Eiq '^\s*ClientAliveCountMax\s+[1-9][0-9]*\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*LoginGraceTime\s+[1-9][0-9]*\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*MaxStartups\s+[0-9:]+\b' /etc/ssh/sshd_config && grep -Eiq '^\s*MaxSessions\s+[0-9]+\b' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eiq '^\s*Banner\s+\S+' /etc/ssh/sshd_config ) && echo PASS || echo FAIL
( grep -Eq '\bpam_pwquality\.so\b' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq 'pam_pwquality\.so.*(minlen=|dcredit=|ucredit=|lcredit=|ocredit=)' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq '\bpam_pwhistory\.so\b' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq 'minlen=[1-9][0-9]+' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq '(dcredit|ucredit|lcredit|ocredit)=-?[1-9]+' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq '^\s*(maxrepeat|maxsequence)\s*=\s*[1-9]+' /etc/security/pwquality.conf ) && echo PASS || echo FAIL
( grep -Eq '^\s*dictcheck\s*=\s*1\b' /etc/security/pwquality.conf ) && echo PASS || echo FAIL
( grep -Eq '^\s*password\s+(sufficient|required)\s+pam_unix\.so.*\bsha512\b' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq 'pam_pwhistory\.so.*remember=[1-9]+' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq 'pam_faillock\.so.*unlock_time=[1-9]+' /etc/pam.d/system-auth ) && echo PASS || echo FAIL
( grep -Eq '^\s*PASS_MAX_DAYS\s+[1-9][0-9]+' /etc/login.defs ) && echo PASS || echo FAIL
( grep -Eq '^\s*PASS_MIN_DAYS\s+[0-9]+' /etc/login.defs ) && echo PASS || echo FAIL
( grep -Eq '^\s*PASS_WARN_AGE\s+[1-9][0-9]*' /etc/login.defs ) && echo PASS || echo FAIL
( useradd -D 2>/dev/null | grep -Eq '^INACTIVE=[1-9][0-9]*' ) && echo PASS || echo FAIL
( ! awk -F: '($2!~/^(!|\*)/ && $2!="" && $5==0){print}' /etc/shadow | grep -q . ) && echo PASS || echo FAIL
( awk -F: '$3==0{print}' /etc/passwd | wc -l | grep -qx 1 ) && echo PASS || echo FAIL
( awk -F: '$3==0{print}' /etc/group | wc -l | grep -qx 1 ) && echo PASS || echo FAIL
( awk -F: '($3>0 && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print}' /etc/passwd | grep -q . && echo FAIL || echo PASS )
( grep -Ev '^(#|/bin/bash|/bin/sh|/sbin/nologin|/bin/false)$' /etc/shells | grep -q . && echo FAIL || echo PASS )
( sudo -l >/dev/null 2>&1; sudo env | grep -E '^PATH=' | cut -d= -f2 | grep -Eq '(^|:)\.(:|$)' && echo FAIL || echo PASS )
( grep -REq '^\s*umask\s+0[2-7][2-7]\b' /etc/profile /etc/bashrc 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '^\s*TMOUT=[1-9][0-9]+' /etc/profile /etc/bashrc 2>/dev/null ) && echo PASS || echo FAIL
( grep -Eq '^\s*%wheel\s+ALL=\(ALL\)\s+ALL\b' /etc/sudoers ) && echo PASS || echo FAIL
( grep -Eq '^\s*Defaults\s+requiretty\b' /etc/sudoers ) && echo PASS || echo FAIL
( grep -Eq '^\s*Defaults\s+logfile=' /etc/sudoers ) && echo PASS || echo FAIL
( grep -Eq '^\s*Defaults\s+timestamp_timeout=[1-9][0-9]*\b' /etc/sudoers ) && echo PASS || echo FAIL
( grep -Eq '^\s*auth\s+required\s+pam_wheel\.so' /etc/pam.d/su ) && echo PASS || echo FAIL
( systemctl is-enabled rsyslog 2>/dev/null | grep -qx enabled ) && echo PASS || echo FAIL
( grep -Eq '^\s*Storage=persistent\b' /etc/systemd/journald.conf ) && echo PASS || echo FAIL
( systemctl is-enabled rsyslog 2>/dev/null | grep -qx enabled ) && echo PASS || echo FAIL
( grep -Eq '^\s*rotate\s+[1-9][0-9]*' /etc/logrotate.conf ) && echo PASS || echo FAIL
( systemctl is-enabled auditd 2>/dev/null | grep -qx enabled ) && echo PASS || echo FAIL
( systemctl list-dependencies multi-user.target 2>/dev/null | grep -qx auditd.service ) && echo PASS || echo FAIL
( grep -Eq '^\s*max_log_file\s*=\s*[1-9][0-9]*' /etc/audit/auditd.conf ) && echo PASS || echo FAIL
( grep -REq '\b(adjtimex|settimeofday|clock_settime)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '(/etc/passwd|/etc/group|/etc/shadow)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '(/etc/sysconfig/network|/etc/hosts|/etc/resolv\.conf)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(setenforce|/etc/selinux|selinux-policy)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(login|logout|session)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(chmod|chown|setxattr|fchmod)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(EACCES|EPERM)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\bexecve\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(mount|umount2)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(unlink|rename|rmdir|unlinkat|renameat)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\b(init_module|delete_module|finit_module)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '(/etc/sudoers|/etc/sudoers\.d|sudo\.log)\b' /etc/audit/rules.d 2>/dev/null ) && echo PASS || echo FAIL
( grep -REq '\baide\b' /etc/cron.* 2>/dev/null ) && echo PASS || echo FAIL
( stat -c '%a' /etc/passwd | grep -Eq '^[0-6]44$' ) && echo PASS || echo FAIL
( stat -c '%a' /etc/passwd- 2>/dev/null | grep -Eq '^[0-6]44$' ) && echo PASS || echo FAIL
( stat -c '%a %U %G' /etc/shadow | grep -Eq '^000 root root$' ) && echo PASS || echo FAIL
( stat -c '%a %U %G' /etc/shadow- 2>/dev/null | grep -Eq '^000 root root$' ) && echo PASS || echo FAIL
( stat -c '%a %U %G' /etc/gshadow- 2>/dev/null | grep -Eq '^000 root root$' ) && echo PASS || echo FAIL
( stat -c '%a %U %G' /etc/gshadow | grep -Eq '^000 root root$' ) && echo PASS || echo FAIL
( stat -c '%a' /etc/group | grep -Eq '^[0-6]44$' ) && echo PASS || echo FAIL
( stat -c '%a' /etc/group- 2>/dev/null | grep -Eq '^[0-6]44$' ) && echo PASS || echo FAIL
( stat -c '%a %U %G' /etc/security/opasswd 2>/dev/null | grep -Eq '^(600|640) root root$' ) && echo PASS || echo FAIL
( find / -xdev -nouser 2>/dev/null | grep -q . && echo FAIL || echo PASS )
( ! find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -q . ) && echo PASS || echo FAIL
( find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | grep -q . && echo FAIL || echo PASS )
( awk -F: '($3>=1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1":"$6}' /etc/passwd | while IFS=: read u d; do [ -d "$d" ] || echo "$u"; done | grep -q . && echo FAIL || echo PASS )
( awk -F: '($3>=1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1":"$6}' /etc/passwd | while IFS=: read u d; do [ -d "$d" ] && [ "$(stat -c %U "$d")" = "$u" ] || echo "$u"; done | grep -q . && echo FAIL || echo PASS )
( find /home -mindepth 1 -maxdepth 1 -type d -perm /027 2>/dev/null | grep -q . && echo FAIL || echo PASS )
( find /home -maxdepth 2 -type f -name ".*" -perm -002 2>/dev/null | grep -q . && echo FAIL || echo PASS )
( find /home -maxdepth 2 -type f \( -name ".forward" -o -name ".netrc" -o -name ".rhosts" \) 2>/dev/null | grep -q . && echo FAIL || echo PASS )

