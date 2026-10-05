#!/usr/bin/env bash

echo "[205–209] Políticas globais de expiração e bloqueio de senha – persistentes com /etc/login.defs.local"

arquivo="/etc/login.defs"
bk="${arquivo}.bak.$(date +%Y%m%d%H%M%S)"
cp -p "$arquivo" "$bk" && echo "🗂️ Backup criado: $bk"

# --- 205-207 Persistência de PASS_* ---
echo "--- Garantindo parâmetros em /etc/login.defs e login.defs.local ---"

# Cria override local
cat <<'EOF' > /etc/login.defs.local
PASS_MAX_DAYS 365
PASS_MIN_DAYS 1
PASS_WARN_AGE 7
EOF

# Garante inclusão no arquivo principal
grep -q "^#include /etc/login.defs.local" "$arquivo" || echo "#include /etc/login.defs.local" >> "$arquivo"

# Ajusta também o arquivo principal para refletir o estado atual
for param in PASS_MAX_DAYS PASS_MIN_DAYS PASS_WARN_AGE; do
  case "$param" in
    PASS_MAX_DAYS) valor=365 ;;
    PASS_MIN_DAYS) valor=1 ;;
    PASS_WARN_AGE) valor=7 ;;
  esac
  if grep -qE "^#?\s*$param" "$arquivo"; then
    sed -i "s|^#\?\s*$param\s\+[0-9]\+|$param $valor|" "$arquivo"
  else
    echo "$param $valor" >> "$arquivo"
  fi
done
echo "✅ PASS_* configurado e persistente via /etc/login.defs.local"

# --- 208 INACTIVE 30 ---
echo "--- Aplicando INACTIVE padrão e atualizando contas existentes ---"
useradd -D -f 30
awk -F: '($3 >= 1000 && $2~/^\$.+\$/) { system("chage --inactive 30 " $1) }' /etc/shadow
echo "✅ INACTIVE configurado para 30 dias (UID >= 1000)"

# --- 209 Datas futuras ---
echo "--- Corrigindo datas de alteração de senha futuras (se existirem) ---"
awk -F: '($3 >= 1000 && $2~/^\$.+\$/) {print $1}' /etc/shadow | while read -r usuario; do
  data=$(chage -l "$usuario" | grep '^Last password change' | cut -d: -f2- | xargs)
  if [[ -n "$data" && "$data" != "never" ]]; then
    if date -d "$data" >/dev/null 2>&1; then
      ts_data=$(date -d "$data" +%s)
      ts_hoje=$(date +%s)
      if (( ts_data > ts_hoje )); then
        chage -d 0 "$usuario"
        echo "⚠️ Corrigido: $usuario tinha data futura ($data)"
      fi
    fi
  fi
done
echo "[ℹ️ FIM]"
exit 0