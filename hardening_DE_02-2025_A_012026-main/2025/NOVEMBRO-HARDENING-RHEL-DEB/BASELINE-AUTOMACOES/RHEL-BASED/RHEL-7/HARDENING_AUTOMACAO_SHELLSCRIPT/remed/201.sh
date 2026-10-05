#!/usr/bin/env bash
echo "[201–204] Políticas de senha e bloqueio (pwquality, faillock, PAM)"

# Função simples de backup
backup_file() {
    [[ -f "$1" ]] && cp -p "$1" "${1}.bak.$(date +%F_%H%M%S)" && echo "🗂️ Backup: $1 salvo"
}

# 201 - pwquality.conf
file_pwq="/etc/security/pwquality.conf"
if [[ -f "$file_pwq" ]]; then
    backup_file "$file_pwq"
    grep -q "^minlen" "$file_pwq" && sed -i 's/^minlen.*/minlen = 14/' "$file_pwq" || echo "minlen = 14" >> "$file_pwq"
    grep -q "^minclass" "$file_pwq" && sed -i 's/^minclass.*/minclass = 4/' "$file_pwq" || echo "minclass = 4" >> "$file_pwq"
    echo "✅ Parâmetros de complexidade atualizados em $file_pwq"
else
    echo "⚠️ Arquivo $file_pwq não encontrado"
fi

# 202 - faillock.conf
echo "[202] Configurar bloqueio após falhas de senha (deny <= 5)"
arquivo="/etc/security/faillock.conf"
parametro="deny"
valor_desejado=5
if [[ ! -f "$arquivo" ]]; then
  echo "❗ Arquivo $arquivo não encontrado — ajuste manual necessário"
  exit 0
fi
bk="${arquivo}.bak.$(date +%Y%m%d%H%M%S)"
cp "$arquivo" "$bk" && echo "🗂️ Backup criado: $bk"
if grep -qE "^#?\s*$parametro\s*=" "$arquivo"; then
  sed -i "s/^#\?\s*$parametro\s*=.*/$parametro = $valor_desejado/" "$arquivo"
  echo "✅ '$parametro' ajustado para $valor_desejado em $arquivo"
else
  echo "$parametro = $valor_desejado" >> "$arquivo"
  echo "✅ '$parametro' adicionado em $arquivo"
fi

# 203 - SHA-512 no PAM
for file in /etc/pam.d/system-auth /etc/pam.d/password-auth; do
    [[ -f "$file" ]] || continue
    backup_file "$file"
    if grep -q "pam_unix.so" "$file"; then
        sed -i '/pam_unix.so/ s/\<md5\>//g; /pam_unix.so/ s/$/ sha512/' "$file"
        echo "✅ SHA-512 garantido em $file"
    fi
done

# 204 - Histórico de senhas (remember)
for file in /etc/pam.d/system-auth /etc/pam.d/password-auth; do
    [[ -f "$file" ]] || continue
    backup_file "$file"
    if grep -q "pam_pwhistory.so" "$file"; then
        sed -i 's/\(pam_pwhistory\.so.*\)remember=[0-9]\+/\1remember=5/' "$file"
    else
        sed -i '/pam_pwquality.so/a password required pam_pwhistory.so use_authtok remember=5 retry=3' "$file"
    fi
    echo "✅ Histórico de senhas configurado em $file"
done

echo "⚠️ Reinicie serviços PAM/SSSD conforme necessário"
echo "[ℹ️ FIM]"
exit 0