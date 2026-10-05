#!/usr/bin/env bash

echo -e "\n[197] Verificar políticas globais de expiração de senha (/etc/login.defs e useradd -D)"

# --- 197 Ensure password expiration is configured ---
echo "--- Verificando PASS_MAX_DAYS ---"
arquivo="/etc/login.defs"
parametro="PASS_MAX_DAYS"
valor=$(grep -E "^\s*${parametro}\s+[0-9]+" "$arquivo" | awk '{print $2}' | head -n1)

if [[ -n "$valor" && "$valor" -le 365 && "$valor" -gt 0 ]]; then
  echo "✅ [APROVADO]: $parametro=$valor em $arquivo"
elif [[ -n "$valor" ]]; then
  echo "⚠️ [REPROVADO]: $parametro=$valor inválido em $arquivo (esperado: 1–365)"
else
  echo "❗ Parâmetro $parametro não encontrado em $arquivo"
fi

# --- 198 Ensure minimum password days is configured ---
echo "--- Verificando PASS_MIN_DAYS ---"
parametro="PASS_MIN_DAYS"
valor=$(grep -E "^\s*${parametro}\s+[0-9]+" "$arquivo" | awk '{print $2}' | head -n1)

if [[ -n "$valor" && "$valor" -ge 1 ]]; then
  echo "✅ [APROVADO]: $parametro=$valor em $arquivo"
else
  echo "⚠️ [REPROVADO]: $parametro=$valor inválido ou ausente (esperado: >=1)"
fi

# --- 199 Ensure password expiration warning days is configured ---
echo "--- Verificando PASS_WARN_AGE ---"
parametro="PASS_WARN_AGE"
valor=$(grep -E "^\s*${parametro}\s+[0-9]+" "$arquivo" | awk '{print $2}' | head -n1)

if [[ -n "$valor" && "$valor" -ge 7 ]]; then
  echo "✅ [APROVADO]: $parametro=$valor em $arquivo"
else
  echo "⚠️ [REPROVADO]: $parametro=$valor inválido ou ausente (esperado: >=7)"
fi

# --- 200 Ensure strong password hashing algorithm is configured ---
echo "--- Verificando ENCRYPT_METHOD ---"
parametro="ENCRYPT_METHOD"
if grep -Eq "^\s*${parametro}\s+(SHA512|YESCRYPT)\b" "$arquivo"; then
  echo "✅ [APROVADO]: Algoritmo forte de hash configurado em $arquivo"
else
  echo "⚠️ [REPROVADO]: $parametro não definido como SHA512 ou YESCRYPT"
fi

# --- 201 Ensure inactive password lock is configured ---
echo "--- Verificando INACTIVE padrão do useradd ---"
parametro="INACTIVE"
valor=$(useradd -D | grep "$parametro" | awk -F= '{print $2}' | tr -d '[:space:]')

if [[ -n "$valor" && "$valor" -ge 0 && "$valor" -le 45 ]]; then
  echo "✅ [APROVADO]: $parametro=$valor dentro do esperado (0–45)"
else
  echo "⚠️ [REPROVADO]: $parametro=$valor inválido ou ausente"
fi

# --- 202 Ensure all users last password change date is in the past ---
echo "--- Verificando datas de alteração de senha dos usuários ---"
awk -F: '$2~/^\$.+\$/{print $1}' /etc/shadow | while read -r usuario; do
  data=$(chage -l "$usuario" | grep '^Last password change' | cut -d: -f2- | sed 's/^\s*//')
  if [[ "$data" == "never" || -z "$data" ]]; then
    echo "⚠️ [REPROVADO]: Usuário $usuario nunca alterou a senha"
  else
    if date -d "$data" >/dev/null 2>&1; then
      ts_data=$(date -d "$data" +%s)
      ts_hoje=$(date +%s)
      if (( ts_data > ts_hoje )); then
        echo "⚠️ [REPROVADO]: Usuário $usuario com data futura: $data"
      else
        echo "✅ [APROVADO]: Usuário $usuario com data válida: $data"
      fi
    else
      echo "❗ Erro ao processar data do usuário $usuario"
    fi
  fi
done

echo "✅ Auditoria finalizada"
exit 0