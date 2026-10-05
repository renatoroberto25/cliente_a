#!/usr/bin/env bash
# [287] Remediação - Configurar AIDE para proteger ferramentas de auditoria

AIDE_CONF="/etc/aide/aide.conf"
TOOLS="$(readlink -f /sbin)"
BACKUP="${AIDE_CONF}.bak_$(date +%Y%m%d_%H%M%S)"

# Backup se existir
[ -f "$AIDE_CONF" ] && cp "$AIDE_CONF" "$BACKUP" && echo "✔ Backup criado: $BACKUP"

# Linhas esperadas
BLOCK=$(cat <<EOF

# Audit Tools (HITSS Remediação 287)
${TOOLS}/auditctl   p+i+n+u+g+s+b+acl+xattrs+sha512
${TOOLS}/auditd     p+i+n+u+g+s+b+acl+xattrs+sha512
${TOOLS}/ausearch   p+i+n+u+g+s+b+acl+xattrs+sha512
${TOOLS}/aureport   p+i+n+u+g+s+b+acl+xattrs+sha512
${TOOLS}/autrace    p+i+n+u+g+s+b+acl+xattrs+sha512
${TOOLS}/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512
EOF
)

# Se já não existir, adiciona
if ! grep -q "Audit Tools (HITSS Remediação 287)" "$AIDE_CONF" 2>/dev/null; then
    echo "$BLOCK" >> "$AIDE_CONF"
    echo "✔ Bloco adicionado ao $AIDE_CONF"
else
    echo "✔ Bloco já presente em $AIDE_CONF"
fi