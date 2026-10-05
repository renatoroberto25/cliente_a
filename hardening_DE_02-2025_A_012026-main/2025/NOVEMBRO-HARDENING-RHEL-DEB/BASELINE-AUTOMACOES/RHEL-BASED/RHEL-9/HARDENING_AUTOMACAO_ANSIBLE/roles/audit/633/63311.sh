#!/usr/bin/env bash
echo "255 Ensure session initiation information is collected"

files_to_check=()
[[ -f /etc/audit/audit.rules ]] && files_to_check+=("/etc/audit/audit.rules")
[[ -d /etc/audit/rules.d ]] && files_to_check+=("/etc/audit/rules.d/"*.rules)

check_file_rule() {
  local file=$1
  local rules=$2

echo "$rules" | grep -E "\-w\s+$file" | grep -E "\-p\s*[rwa]*[wa][rwa]*" | grep -E "key=| -k " > /dev/null
}

echo "Verificando regras no disco..."

DISK_ALL=$(cat "${files_to_check[@]}" 2>/dev/null)
RESULT_DISK_OK=true

for f in /var/run/utmp /var/log/wtmp /var/log/btmp; do
  if check_file_rule "$f" "$DISK_ALL"; then
echo "✅ $f OK no disco"
  else
echo "⚠️ $f ausente ou incompleto no disco"
    RESULT_DISK_OK=false
  fi
done

echo ""
echo "Verificando regras carregadas (runtime)..."

RUNTIME_ALL=$(auditctl -l 2>/dev/null)
RESULT_RUNTIME_OK=true

for f in /var/run/utmp /var/log/wtmp /var/log/btmp; do
  if check_file_rule "$f" "$RUNTIME_ALL"; then
echo "✅ $f OK carregado"
  else
echo "⚠️ $f ausente ou incompleto carregado"
    RESULT_RUNTIME_OK=false
  fi
done