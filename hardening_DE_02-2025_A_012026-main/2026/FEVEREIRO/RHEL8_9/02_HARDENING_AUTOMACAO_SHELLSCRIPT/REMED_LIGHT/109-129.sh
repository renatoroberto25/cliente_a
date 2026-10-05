#!/usr/bin/env bash
echo "[109 - 129] Remediação SSH"

SSHD="/etc/ssh/sshd_config"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

# Garante backup único por execução
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

echo -e "\n[109] Permissões"
chmod 600 /etc/ssh/sshd_config
chown root:root /etc/ssh
echo "✔ Permissões ajustadas"

echo -e "\n[110] Allow/Deny"
# Não altera — depende da política do cliente

echo -e "\n[111] LogLevel"
set_param "LogLevel" "INFO"

echo -e "\n[112] X11Forwarding"
set_param "X11Forwarding" "no"

echo -e "\n[113] MaxAuthTries"
set_param "MaxAuthTries" "4"

echo -e "\n[114] IgnoreRhosts"
set_param "IgnoreRhosts" "yes"

echo -e "\n[115] HostbasedAuthentication"
set_param "HostbasedAuthentication" "no"

echo -e "\n[116] PermitRootLogin"
set_param "PermitRootLogin" "no"

echo -e "\n[117] PermitEmptyPasswords"
set_param "PermitEmptyPasswords" "no"

echo -e "\n[118] PermitUserEnvironment"
set_param "PermitUserEnvironment" "no"

echo -e "\n[119] UsePAM"
set_param "UsePAM" "yes"

echo -e "\n[120] Idle timeout"
set_param "ClientAliveInterval" "300"
set_param "ClientAliveCountMax" "3"

echo -e "\n[121] LoginGraceTime"
set_param "LoginGraceTime" "60"

echo -e "\n[122] MaxStartups/MaxSessions"
set_param "MaxStartups" "10:30:100"
set_param "MaxSessions" "10"

echo -e "\n[123] AllowTcpForwarding"
set_param "AllowTcpForwarding" "no"

echo -e "\n[124] Banner"
set_param "Banner" "/etc/issue.net"

echo -e "\n[125] Ciphers"
set_param "Ciphers" "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com"

echo -e "\n[126] MACs"
set_param "MACs" "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com"

echo -e "\n[127] KexAlgorithms"
set_param "KexAlgorithms" "curve25519-sha256,diffie-hellman-group-exchange-sha256"

echo -e "\n[128] Preferência moderna (double-check)"
# Reforça padrões se os anteriores forem alterados por políticas externas
grep -Eq 'Ciphers.*chacha20' "$SSHD" || \
    echo "Ciphers chacha20-poly1305@openssh.com" >> "$SSHD"

grep -Eq 'KexAlgorithms.*curve25519' "$SSHD" || \
    echo "KexAlgorithms curve25519-sha256" >> "$SSHD"

echo "✔ Preferência moderna reforçada"

echo -e "\n[129] ForceCommand/Chroot (não ativa por padrão)"
# Só aplicar se cliente exigir — deixar neutro
echo "✔ Sem alteração (política específica do cliente)"

echo -e "\n✔ Reiniciando SSH de maneira segura"
systemctl reload sshd 2>/dev/null || systemctl restart sshd
