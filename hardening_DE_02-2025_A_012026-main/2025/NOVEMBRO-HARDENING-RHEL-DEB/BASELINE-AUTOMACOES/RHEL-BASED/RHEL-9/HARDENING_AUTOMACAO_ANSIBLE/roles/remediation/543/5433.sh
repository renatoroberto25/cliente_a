#!/usr/bin/env bash

echo "[213] Garantir umask padrão do sistema (027)"

UMASK_SEGURA="027"
ARQ_UMASK="/etc/profile.d/50-systemwide_umask.sh"
BACKUP="${ARQ_UMASK}.bak.$(date +%Y%m%d%H%M%S)"

# Backup se existir
if [ -f "$ARQ_UMASK" ]; then
  cp -p "$ARQ_UMASK" "$BACKUP" && echo "🗂️ Backup criado: $BACKUP"
fi

# Garante a linha final segura
echo "umask $UMASK_SEGURA" > "$ARQ_UMASK"
chmod 644 "$ARQ_UMASK"
echo "✅ umask configurada como $UMASK_SEGURA em $ARQ_UMASK"

# Comentário preventivo em arquivos que contenham umask permissivo
find /etc/profile.d/ -type f -name '*.sh' -exec sed -i.bak -E '/^\s*umask\s+[0-6][0-6][0-6]/s/^/# /' {} \;

for file in /etc/profile /etc/bashrc /etc/login.defs /etc/default/login; do
  if grep -qE '^\s*umask\s+[0-6][0-6][0-6]' "$file"; then
    cp -p "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
    sed -i -E 's/^\s*umask\s+[0-6][0-6][0-6]/# &/' "$file"
    echo "⚠️ Comentado umask permissivo em $file"
  fi
done

echo "✅ Remediação finalizada"
exit 0