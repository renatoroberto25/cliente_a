#!/usr/bin/env bash
echo "[109 - 129] Remediação SSH"

SSHD="/etc/ssh/sshd_config"

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

backup "$SSHD"

set_param() {
    local key="$1"
    local value="$2"
    if grep -Eq "^[[:space:]]*${key}[[:space:]]+" "$SSHD"; then
        sed -ri "s|^[[:space:]]*${key}[[:space:]]+.*|${key} ${value}|" "$SSHD"
        echo "✔ Ajustado: ${key} ${value}"
    else
        echo "${key} ${value}" >> "$SSHD"
        echo "✔ Inserido: ${key} ${value}"
    fi
}

# [109] Permissões
echo -e "\n[109] Permissões"
chmod 600 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
echo "✔ Permissões do sshd_config ajustadas"

# [110] Allow/Deny
echo -e "\n[110] Allow/Deny"
echo "✔ Sem alteração (política definida pelo cliente)"

# [111–123] Parâmetros gerais
echo -e "\n[111–123] Parâmetros gerais"
set_param "LogLevel" "INFO"
set_param "X11Forwarding" "no"
set_param "MaxAuthTries" "4"
set_param "IgnoreRhosts" "yes"
set_param "HostbasedAuthentication" "no"
set_param "PermitRootLogin" "no"
set_param "PermitEmptyPasswords" "no"
set_param "PermitUserEnvironment" "no"
set_param "UsePAM" "yes"
set_param "ClientAliveInterval" "300"
set_param "ClientAliveCountMax" "3"
set_param "LoginGraceTime" "60"
set_param "MaxStartups" "10:30:100"
set_param "MaxSessions" "10"
set_param "AllowTcpForwarding" "no"

# [124] Banner
echo -e "\n[124] Banner"
if [ -f /etc/issue.net ]; then
    set_param "Banner" "/etc/issue.net"
else
    echo "⚠ /etc/issue.net não encontrado – não configurado"
fi

# [125] Ciphers
echo -e "\n[125] Ciphers"
set_param "Ciphers" "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com"

# [126] MACs
echo -e "\n[126] MACs"
set_param "MACs" "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com"

# [127] KexAlgorithms
echo -e "\n[127] KexAlgorithms"
set_param "KexAlgorithms" "curve25519-sha256,diffie-hellman-group-exchange-sha256"

# [128] Preferência moderna
echo -e "\n[128] Preferência moderna"
echo "✔ Garantida pelos controles 125–127"

# [129] ForceCommand / Chroot
echo -e "\n[129] ForceCommand/Chroot"
echo "✔ Sem alteração – política específica do cliente"

# Validação
echo -e "\n🔍 Validando configuração SSH..."
if sshd -t; then
    echo "✔ sshd_config válido – recarregando serviço"
    systemctl reload sshd 2>/dev/null || systemctl restart sshd
else
    echo "❌ sshd_config inválido – serviço NÃO reiniciado"
fi
