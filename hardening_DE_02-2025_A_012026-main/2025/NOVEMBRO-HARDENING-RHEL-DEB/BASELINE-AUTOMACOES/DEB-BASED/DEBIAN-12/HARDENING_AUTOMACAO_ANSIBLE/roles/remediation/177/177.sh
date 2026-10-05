#!/usr/bin/env bash
echo "[177 - 183] Remediação - Sudo e Su"

TS="$(date +%F_%H%M%S)"
SUDOERS_FILE="/etc/sudoers"
SUDOERS_BACKUP="${SUDOERS_FILE}.bak_${TS}"

# Função para editar sudoers de forma segura
edit_sudoers() {
  local key="$1"
  local value="$2"
  if egrep -i "^\s*Defaults\s+.*${key}" "$SUDOERS_FILE"; then
    sed -i "s/^\s*Defaults\s\+.*${key}.*/Defaults    ${value}/" "$SUDOERS_FILE"
  else
    echo "Defaults    ${value}" >> "$SUDOERS_FILE"
  fi
}

# 177 - sudo instalado
echo -e "\n[177] Garantindo instalação do sudo"
if ! command -v sudo >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y sudo
  echo "✅ sudo instalado"
else
  echo "✅ sudo já está instalado"
fi

# 178 - use_pty
echo -e "\n[178] Garantindo use_pty"
cp "$SUDOERS_FILE" "$SUDOERS_BACKUP"
edit_sudoers "use_pty" "use_pty"
echo "✅ Configurado use_pty"

# 179 - logfile
echo -e "\n[179] Garantindo logfile do sudo"
LOGFILE="/var/log/sudo.log"
touch "$LOGFILE"
chmod 600 "$LOGFILE"
chown root:root "$LOGFILE"
edit_sudoers "logfile" "logfile=${LOGFILE}"
echo "✅ Logfile configurado em $LOGFILE"

# 180 - exigir senha
echo -e "\n[180] Garantindo autenticação no sudo"
# Remove '!authenticate' se existir
sed -i 's/!authenticate/authenticate/' "$SUDOERS_FILE"
# Garante que authenticate está presente
edit_sudoers "authenticate" "authenticate"
echo "✅ sudo configurado para exigir senha"

# 181 - re-autenticação não desabilitada globalmente
echo -e "\n[181] Garantindo que timestamp_timeout != -1"
sed -i '/timestamp_timeout=-1/d' "$SUDOERS_FILE"
echo "✅ timestamp_timeout -1 removido (se existia)"

# 182 - timeout configurado
echo -e "\n[182] Garantindo configuração de timeout"
# Define timeout de 5 minutos (ajustável)
edit_sudoers "timestamp_timeout" "timestamp_timeout=5"
echo "✅ Timeout configurado (5 minutos)"

# 183 - restrição do comando su
echo -e "\n[183] Revisar restrição de su"
echo "⚠️ Ajuste manual recomendado: configure 'auth required pam_wheel.so use_uid group=sudo' em /etc/pam.d/su"
#184 185 core packages

echo "[186] Remediação - Instalar libpam-pwquality"

PKG="libpam-pwquality"
TS="$(date +%F_%H%M%S)"

# Verifica se já está instalado
if dpkg-query -s "$PKG" 2>/dev/null | grep -q '^Status: install ok installed'; then
  echo "✅ $PKG já está instalado"
else
  echo "⚠️ $PKG ausente — instalando..."
  apt-get update -qq
  if apt-get install -y "$PKG"; then
    echo "✅ $PKG instalado com sucesso"
  else
    echo "❌ Falha ao instalar $PKG — verifique os repositórios"
    exit 1
  fi
fi