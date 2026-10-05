#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
echo "[196 - 200] Configurar contas de root e de sistema/ambiente"

# --- [196] Default group do root ---
echo -e "\n[196] Verificar GID primário do root"
gid_root=$(getent passwd root | cut -d: -f4)
if [[ "$gid_root" -eq 0 ]]; then
    echo "✅ root já possui GID 0"
else
    echo "⚠️ root com GID $gid_root — ajuste manual recomendado: usermod -g 0 root"
fi

# --- [197] Root umask ---
echo -e "\n[197] Garantir umask do root = 027"
UMASK_VALUE="027"
FILES=("/root/.bash_profile" "/root/.bashrc")
for f in "${FILES[@]}"; do
    if [[ -f "$f" ]]; then
        if grep -Eq "^\s*umask\s+$UMASK_VALUE\b" "$f"; then
            echo "✅ $f já possui umask $UMASK_VALUE"
        else
            cp -p "$f" "$f.bak_${TS}"
            sed -i '/^\s*umask\s\+/d' "$f"
            echo "umask $UMASK_VALUE" >> "$f"
            echo "⚠️ Ajustado umask para $UMASK_VALUE em $f"
        fi
    else
        echo "⚠️ $f não existe — criando com umask $UMASK_VALUE"
        echo "umask $UMASK_VALUE" > "$f"
    fi
done

# --- [198] Contas de sistema ---
echo -e "\n[198] Verificar contas de sistema com shell indevido"
uid_min=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
uid_min="${uid_min:-1000}"
bad_sys_accts=$(awk -F: -v umin="$uid_min" \
  '($1!~/^(root|halt|sync|shutdown|nfsnobody)$/ && ($3<umin || $3==65534) && $7!~/nologin$/){print $1}' /etc/passwd)
if [[ -z "$bad_sys_accts" ]]; then
    echo "✅ Todas as contas de sistema usam nologin"
else
    echo "⚠️ Contas de sistema com shell indevido encontradas:"
    echo "$bad_sys_accts"
    echo "    → ajuste manual recomendado (usermod -s /sbin/nologin <user>)"
fi

# --- [199] Senha do root ---
echo -e "\n[199] Verificar se senha do root está definida"
if passwd -S root 2>/dev/null | awk '{print $2}' | grep -q '^P'; then
    echo "✅ Senha do root já definida"
else
    echo "⚠️ Conta root sem senha — defina manualmente: passwd root"
fi

# --- [200] /nologin em /etc/shells ---
echo -e "\n[200] Verificar se /nologin está listado em /etc/shells"
if grep -Eq '^[^#].*/nologin([[:space:]]|$)' /etc/shells 2>/dev/null; then
    echo "⚠️ /nologin listado em /etc/shells — avalie necessidade antes de remover"
else
    echo "✅ /nologin não está listado em /etc/shells"
fi

exit 0