#!/usr/bin/env bash
echo "[109 - 129] Remediação SSH"

SSHD="/etc/ssh/sshd_config"

backup() {
    [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

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

backup "$SSHD"

echo -e "\n[109] Permissões"
if [ -f "$SSHD" ]; then
    chmod 600 "$SSHD"
    chown root:root "$SSHD"
    echo "✔ Permissões ajustadas"
else
    echo "✖ $SSHD não encontrado"
fi

echo -e "\n[110] Allow/Deny"
echo "✔ Sem alteração (política definida pelo cliente)"

echo -e "\n[111–127] Parâmetros gerais"
set_param "LogLevel" "INFO"
set_param "X11Forwarding" "no"
set_param "MaxAuthTries" "4"
set_param "IgnoreRhosts" "yes"
set_param "HostbasedAuthentication" "no"
set_param "PermitEmptyPasswords" "no"
set_param "PermitUserEnvironment" "no"
set_param "UsePAM" "yes"
set_param "ClientAliveInterval" "300"
set_param "ClientAliveCountMax" "3"
set_param "LoginGraceTime" "60"
set_param "MaxStartups" "10:30:100"
set_param "MaxSessions" "10"
set_param "AllowTcpForwarding" "no"

echo -e "\n[124] Banner legal"
echo "AÇÃO MANUAL: Definir diretiva Banner em /etc/ssh/sshd_config apontando para arquivo de aviso legal aprovado pela organização."

echo -e "\n[125] Ciphers"
set_param "Ciphers" "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com"

echo -e "\n[126] MACs"
set_param "MACs" "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com"

echo -e "\n[127] KexAlgorithms"
set_param "KexAlgorithms" "curve25519-sha256,diffie-hellman-group-exchange-sha256"

echo -e "\n[128] Preferência moderna"
if grep -Eq '^[[:space:]]*Ciphers[[:space:]]+.*chacha20-poly1305@openssh\.com' "$SSHD"; then
    echo "✔ Ciphers já contempla preferência moderna"
else
    echo "Ciphers chacha20-poly1305@openssh.com" >> "$SSHD"
    echo "✔ Ciphers reforçado"
fi

if grep -Eq '^[[:space:]]*KexAlgorithms[[:space:]]+.*curve25519-sha256' "$SSHD"; then
    echo "✔ KexAlgorithms já contempla preferência moderna"
else
    echo "KexAlgorithms curve25519-sha256" >> "$SSHD"
    echo "✔ KexAlgorithms reforçado"
fi

echo -e "\n[129] ForceCommand/Chroot"
echo "✔ Sem alteração – política específica do cliente"

echo -e "\n🔍 Validando configuração SSH..."
if sshd -t -f "$SSHD" >/dev/null 2>&1; then
    echo "✔ sshd_config válido – recarregando serviço"
    if systemctl reload sshd >/dev/null 2>&1; then
        echo "✔ sshd recarregado"
    else
        if systemctl restart sshd >/dev/null 2>&1; then
            echo "✔ sshd reiniciado"
        else
            echo "✖ Falha ao recarregar/reiniciar sshd"
        fi
    fi
else
    echo "✖ sshd_config inválido – NÃO reiniciado"
fi

echo "OK"
exit 0
