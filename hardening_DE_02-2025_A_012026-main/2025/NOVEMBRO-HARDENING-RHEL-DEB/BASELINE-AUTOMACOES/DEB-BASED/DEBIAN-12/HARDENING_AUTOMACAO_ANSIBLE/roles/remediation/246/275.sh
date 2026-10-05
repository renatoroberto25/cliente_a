#!/usr/bin/env bash
echo "[275–284] Remediação de permissões e propriedade do auditd"

LOG_DIR="$(dirname $(awk -F= '/^\s*log_file/{print $2}' /etc/audit/auditd.conf 2>/dev/null | xargs))"
AUDIT_TOOLS="/sbin/auditctl /sbin/auditd /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/augenrules /usr/sbin/auditctl /usr/sbin/auditd"

# 275 – audit log files mode
if [ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ]; then
  find "$LOG_DIR" -maxdepth 1 -type f -exec chmod 640 {} +
  echo "✔ Corrigido: permissões dos arquivos de log"
fi

# 276 – owner root
[ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && find "$LOG_DIR" -maxdepth 1 -type f ! -user root -exec chown root {} +

# 277 – group root ou adm
[ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && find "$LOG_DIR" -maxdepth 1 -type f ! -group root ! -group adm -exec chgrp root {} +

# 278 – diretório
[ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ] && chmod 750 "$LOG_DIR" && echo "✔ Corrigido: permissões do diretório de log"

# 279–281 – config files
find /etc/audit -type f \( -name "*.conf" -o -name "*.rules" \) -exec chmod 640 {} +
find /etc/audit -type f \( -name "*.conf" -o -name "*.rules" \) ! -user root -exec chown root {} +
find /etc/audit -type f \( -name "*.conf" -o -name "*.rules" \) ! -group root -exec chgrp root {} +

# 282–284 – audit tools
for tool in $AUDIT_TOOLS; do
  [ -e "$tool" ] || continue
  chmod 755 "$tool"
  chown root:root "$tool"
done
echo "✔ Ferramentas auditd corrigidas"