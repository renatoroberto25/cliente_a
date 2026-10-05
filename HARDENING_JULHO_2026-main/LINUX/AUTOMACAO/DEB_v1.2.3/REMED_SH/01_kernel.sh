#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

block_module() { local id="$1" name="$2" mod="$3" file=/etc/modprobe.d/99-hitss-hardening.conf; echo "[$id] $name"; ensure_file "$file" || { echo "WARN: $file"; return; }; backup_file "$file"; ensure_line "$file" "install $mod /bin/false" && ensure_line "$file" "blacklist $mod" && echo "OK: $mod bloqueado" || echo "WARN: $mod"; }

block_module 2 'Bloqueio squashfs' squashfs
block_module 3 'Bloqueio udf' udf
block_module 4 'Bloqueio hfs' hfs
block_module 5 'Bloqueio hfsplus' hfsplus
block_module 6 'Bloqueio jffs2' jffs2
block_module 7 'Bloqueio freevxfs' freevxfs
block_module 8 'Desabilitar o módulo overlayfs' overlay
block_module 9 'Bloqueio usb_storage' usb_storage
block_module 10 'Bloqueio DCCP' dccp
block_module 11 'Bloqueio SCTP' sctp
block_module 12 'Bloqueio RDS' rds
block_module 13 'Bloqueio TIPC' tipc
set_sysctl 14 'Core dumps restritos' fs.suid_dumpable 0
set_sysctl 15 'SUID dump off' fs.suid_dumpable 0
manual 16 'NX/XD ativo' 'Validar NX/XD no firmware e no kernel; reiniciar somente em janela aprovada.'
set_sysctl 17 'ASLR habilitado' kernel.randomize_va_space 2
set_sysctl 18 'ASLR completo' kernel.randomize_va_space 2
set_sysctl 19 'perf_event restrito' kernel.perf_event_paranoid 2
set_sysctl 20 'dmesg restrito' kernel.dmesg_restrict 1
set_sysctl 21 'Symlinks protegidos' fs.protected_symlinks 1
set_sysctl 22 'Hardlinks protegidos' fs.protected_hardlinks 1
