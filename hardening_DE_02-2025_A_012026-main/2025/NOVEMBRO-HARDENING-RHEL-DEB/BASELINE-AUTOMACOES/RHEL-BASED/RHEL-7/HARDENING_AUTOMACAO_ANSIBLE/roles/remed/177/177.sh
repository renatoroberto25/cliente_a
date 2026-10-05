#!/usr/bin/env bash
echo "[177–178] Remediação avançada - Configuração do sudo (idempotente + backup)"

# Função de backup
backup_file() {
    local path="$1"
    [[ -e "$path" ]] && cp -p "$path" "${path}.bkp.$(date +%F_%H%M%S)" && echo "[🗂️ BACKUP] $path salvo."
}

SUDO_FILE="/etc/sudoers.d/hitss-hardening"
mkdir -p /etc/sudoers.d

# Garante arquivo custom para não mexer diretamente no /etc/sudoers
if [[ ! -e "$SUDO_FILE" ]]; then
    echo "[ℹ️ INFO] Criando arquivo $SUDO_FILE"
    touch "$SUDO_FILE"
    chmod 440 "$SUDO_FILE"
fi

# 177 - Defaults use_pty
echo "[177] Garantindo que o sudo use pseudo-TTY"
if grep -Eq '^[[:space:]]*Defaults[[:space:]]+([^#[:space:]]+,\s*)?use_pty\b' /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
    echo "[ℹ️ OK] Parâmetro use_pty já configurado"
else
    backup_file "$SUDO_FILE"
    echo "Defaults use_pty" >> "$SUDO_FILE"
    visudo -cf "$SUDO_FILE" &>/dev/null && echo "[✅ SUCESSO] Adicionado 'Defaults use_pty' em $SUDO_FILE" || echo "[❌ FALHA] Erro de sintaxe ao validar $SUDO_FILE"
fi

# 178 - Defaults logfile
echo "[178] Garantindo que o sudo tenha log customizado"
if grep -Eq '^[[:space:]]*Defaults[[:space:]]+([^#;]+,\s*)?logfile\s*=\s*(")?[^#;]+(")?' /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
    echo "[ℹ️ OK] Parâmetro logfile já configurado"
else
    backup_file "$SUDO_FILE"
    echo 'Defaults logfile="/var/log/sudo.log"' >> "$SUDO_FILE"
    touch /var/log/sudo.log && chmod 600 /var/log/sudo.log
    visudo -cf "$SUDO_FILE" &>/dev/null && echo "[✅ SUCESSO] Logfile configurado em /var/log/sudo.log" || echo "[❌ FALHA] Erro de sintaxe ao validar $SUDO_FILE"
fi

echo "[ℹ️ FIM]"
exit 0