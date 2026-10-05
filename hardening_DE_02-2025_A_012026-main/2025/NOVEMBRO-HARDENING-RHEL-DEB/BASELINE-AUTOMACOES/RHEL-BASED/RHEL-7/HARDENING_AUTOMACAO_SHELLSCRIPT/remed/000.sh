#!/usr/bin/env bash
# [Audit Rules] Remediação segura e idempotente de regras auditctl/augenrules
# Política: backup → adiciona só se necessário → mantém execução até o fim

set -uo pipefail
TS="$(date +%Y%m%d-%H%M%S)"
RULE_FILE="/etc/audit/rules.d/hardening.rules"

log(){ echo "✔ $1"; }
warn(){ echo "⚠️ $1"; }
fail(){ echo "✖ $1"; }

backup_file(){
  local f="$1"
  [ -e "$f" ] || { warn "$f ausente (ignorado)"; return 0; }
  cp -a -- "$f" "${f}.bkp-${TS}" && log "Backup: ${f}.bkp-${TS}" || warn "Falha backup $f"
}

add_audit_rule(){
  local lbl="$1" rule="$2"
  echo "[$lbl] Verificando regra: $rule"
  grep -qF -- "$rule" "$RULE_FILE" 2>/dev/null && { log "Regra já presente"; return 0; }
  backup_file "$RULE_FILE"
  echo "$rule" >> "$RULE_FILE" && log "Regra adicionada" || fail "Falha ao adicionar regra"
}

echo "[Audit Rules] Remediação iniciada"

# Exemplo de regras (adaptável conforme baseline HITSS ou CVE)
add_audit_rule 301 '-a always,exit -F path=/usr/bin/chcon -F perm=x -F auid>=1000 -F auid!=4294967295 -k perm_mod'
add_audit_rule 302 '-a always,exit -F path=/usr/bin/setfacl -F perm=x -F auid>=1000 -F auid!=4294967295 -k perm_mod'
add_audit_rule 303 '-a always,exit -F path=/usr/bin/chacl -F perm=x -F auid>=1000 -F auid!=4294967295 -k perm_mod'
add_audit_rule 304 '-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=1000 -F auid!=4294967295 -k user_mod'
add_audit_rule 305 '-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access_denied'
add_audit_rule 306 '-a always,exit -F arch=b64 -S open,openat,creat -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access_denied'

echo "[Audit Rules] Aplicando regras com augenrules"
augenrules --load && log "Regras aplicadas com sucesso" || fail "Erro ao aplicar regras"

echo "✔ Remediação de regras de auditoria concluída"
exit 0