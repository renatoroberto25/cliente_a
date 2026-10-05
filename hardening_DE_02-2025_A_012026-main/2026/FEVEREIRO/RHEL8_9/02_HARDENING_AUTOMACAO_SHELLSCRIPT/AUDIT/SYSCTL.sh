(ulimit -c 0 && sysctl -n fs.suid_dumpable | grep -q '^0$') 

cmd    : "ulimit -c; sysctl -n fs.suid_dumpable"
expect : "(?m)^0\\s*$"

(sysctl -n kernel.yama.ptrace_scope | grep -q '^[1-3]$') 

cmd    : "sysctl -n kernel.yama.ptrace_scope"
expect : "^[1-3]$"

(grep -q 'nx' /proc/cpuinfo && dmesg | grep -qi 'NX.*active')

cmd    : "grep -w nx /proc/cpuinfo && dmesg | grep -i 'NX.*active'"
expect : "(?i)nx.*active"

(sysctl -n kernel.randomize_va_space | grep -q '^2$') 

cmd    : "sysctl -n kernel.randomize_va_space"
expect : "^2$"

(grep -q 'iommu=on' /proc/cmdline) 

cmd    : "cat /proc/cmdline"
expect : "\\biommu=on\\b"

(sysctl -n kernel.perf_event_paranoid | grep -q '^[2-3]$') 

cmd    : "sysctl -n kernel.perf_event_paranoid"
expect : "^[2-3]$"

(sysctl -n kernel.dmesg_restrict | grep -q '^1$') 

cmd    : "sysctl -n kernel.dmesg_restrict"
expect : "^1$"

(sysctl -n kernel.unprivileged_userns_clone | grep -q '^0$' ) 

cmd    : "sysctl -n kernel.unprivileged_userns_clone 2>/dev/null || echo absent"
expect : "^(0|absent)$"

(sysctl -n fs.protected_symlinks | grep -q '^1$') 

cmd    : "sysctl -n fs.protected_symlinks"
expect : "^1$"

(sysctl -n fs.protected_hardlinks | grep -q '^1$') 

cmd    : "sysctl -n fs.protected_hardlinks"
expect : "^1$"

(sysctl -n fs.suid_dumpable | grep -q '^0$')

cmd    : "sysctl -n fs.suid_dumpable"
expect : "^0$"
