#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"

echo "[185 - 194] Remediação – Permissões de arquivos sensíveis"

backup_file() {
    local f="$1"
    [ -f "$f" ] && cp -a "$f" "${f}.bkp-${TS}"
}

fix_file() {
    local lbl="$1"
    local file="$2"
    local mode="$3"
    local owner="$4"
    local group="$5"

    echo -e "\n[$lbl] Remediando $file"

    [ -f "$file" ] || { echo "⚠️ $file ausente — ignorado"; return 0; }

    # backup seguro
    backup_file "$file"

    # permissão atual
    local cur_mode cur_owner cur_group
    cur_mode="$(stat -Lc '%a' "$file" 2>/dev/null || echo "")"
    cur_owner="$(stat -Lc '%u' "$file" 2>/dev/null || echo "")"
    cur_group="$(stat -Lc '%g' "$file" 2>/dev/null || echo "")"

    # altera só quando necessário
    [ "$cur_mode"  != "$mode" ]  && chmod "$mode"  "$file"
    [ "$cur_owner" -ne "$owner" ] && chown "$owner" "$file"
    [ "$cur_group" -ne "$group" ] && chgrp "$group" "$file"

    # restaurar contextos quando SELinux está presente
    command -v restorecon &>/dev/null && restorecon "$file" &>/dev/null || true

    echo "✔ $file ajustado"
}

fix_file 185 /etc/passwd       644 0 0
fix_file 186 /etc/passwd-      644 0 0
fix_file 187 /etc/shadow       000 0 0
fix_file 188 /etc/shadow-      000 0 0
fix_file 189 /etc/gshadow-     600 0 0
fix_file 190 /etc/gshadow      600 0 0
fix_file 191 /etc/group        644 0 0
fix_file 192 /etc/group-       644 0 0

echo -e "\n[193] Removendo nologin de /etc/shells"
if [ -f /etc/shells ] && grep -q 'nologin' /etc/shells; then
    backup_file /etc/shells
    sed -i '/nologin/d' /etc/shells
    echo "✔ /etc/shells ajustado"
else
    echo "✔ Nenhuma ocorrência encontrada"
fi

echo -e "\n[194] Remediando /etc/security/opasswd"
fix_file 194 /etc/security/opasswd 600 0 0

echo
echo "✔ Remediação 185–194 finalizada"
exit 0
