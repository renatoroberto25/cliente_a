#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: configuracao SSH"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
SSHD="/etc/ssh/sshd_config"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

set_sshd_param() {
    local key="$1" value="$2" pattern
    pattern="${key//./\\.}"

    if [ ! -f "$SSHD" ]; then
        echo "SKIP: $SSHD nao encontrado"
        return 1
    fi

    if grep -Eq "^[[:space:]]*#?[[:space:]]*${pattern}[[:space:]]+" "$SSHD"; then
        sed -i "s|^[[:space:]]*#\\?[[:space:]]*${pattern}[[:space:]].*|${key} ${value}|" "$SSHD"
    else
        printf '%s %s\n' "$key" "$value" >> "$SSHD"
    fi
    echo "OK: ${key} ${value}"
}

if [ ! -f "$SSHD" ]; then
    echo "SKIP: $SSHD nao encontrado"
    echo "OK"
    exit 0
fi

backup_file "$SSHD"

echo "[109] Permissoes do sshd_config"
chown root:root "$SSHD" 2>/dev/null || echo "WARN: nao foi possivel ajustar owner de $SSHD"
chmod 600 "$SSHD" 2>/dev/null && echo "OK: $SSHD com permissao 600" || echo "WARN: nao foi possivel ajustar permissao de $SSHD"
chown root:root /etc/ssh 2>/dev/null || echo "WARN: nao foi possivel ajustar owner de /etc/ssh"
chmod 750 /etc/ssh 2>/dev/null && echo "OK: /etc/ssh com permissao 750" || echo "WARN: nao foi possivel ajustar permissao de /etc/ssh"

echo "[111,113-115,117-122] Diretivas SSH gerais"
set_sshd_param SyslogFacility AUTHPRIV
set_sshd_param LogLevel INFO
set_sshd_param MaxAuthTries 4
set_sshd_param IgnoreRhosts yes
set_sshd_param HostbasedAuthentication no
set_sshd_param PermitEmptyPasswords no
set_sshd_param PermitUserEnvironment no
set_sshd_param UsePAM yes
set_sshd_param ClientAliveInterval 300
set_sshd_param ClientAliveCountMax 3
set_sshd_param LoginGraceTime 60
set_sshd_param MaxStartups 10:30:100
set_sshd_param MaxSessions 10

ssh_valid=0
if command -v sshd >/dev/null 2>&1; then
    if sshd -t -f "$SSHD" >/dev/null 2>&1; then
        ssh_valid=1
        echo "OK: $SSHD validado por sshd -t"
    else
        if cp -p "${SSHD}.hitss.bak.${TS}" "$SSHD" 2>/dev/null; then
            echo "WARN: configuracao invalida; rollback automatico aplicado"
        else
            echo "WARN: configuracao invalida e rollback falhou; restaurar ${SSHD}.hitss.bak.${TS}"
        fi
    fi
else
    echo "SKIP: binario sshd nao encontrado para validacao sintatica"
fi

if [ "$ssh_valid" -eq 1 ] && systemctl list-unit-files sshd.service >/dev/null 2>&1; then
    systemctl reload sshd >/dev/null 2>&1 && echo "OK: sshd recarregado" || echo "WARN: nao foi possivel recarregar sshd"
fi
echo "OK"
exit 0
