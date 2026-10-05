#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: contas, shell e sudo"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
ROOT_PROFILE="/root/.bash_profile"
UMASK_FILE="/etc/profile.d/99-hitss-umask.sh"
TMOUT_FILE="/etc/profile.d/99-hitss-tmout.sh"
SUDO_FILE="/etc/sudoers.d/99-hitss-hardening"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

ensure_parent() {
    local file="$1" dir
    dir="$(dirname "$file")"
    if [ ! -d "$dir" ]; then
        echo "WARN: diretorio ausente: $dir"
        return 1
    fi
}

write_managed_file() {
    local file="$1" mode="$2"
    ensure_parent "$file" || return 1
    backup_file "$file"
    shift 2
    {
        printf '# Gerenciado pela automacao HITSS hardening\n'
        printf '%s\n' "$@"
    } > "$file"
    chmod "$mode" "$file" 2>/dev/null || echo "WARN: nao foi possivel ajustar permissao de $file"
}

echo "[148] Root unico UID 0"
echo "SKIP: alterar UID de contas existentes e destrutivo; controle deve ser tratado por auditoria e plano manual"

echo "[149] Root unico GID 0"
echo "SKIP: alterar GID de contas existentes e destrutivo; controle deve ser tratado por auditoria e plano manual"

echo "[150] Contas de sistema com shell interativo"
echo "SKIP: contas de sistema com shell interativo exigem revisao nominal; nenhuma conta foi alterada"

echo "[151] /sbin/nologin presente em /etc/shells"
if [ -f /etc/shells ] && grep -qx '/sbin/nologin' /etc/shells; then
    echo "OK: /sbin/nologin presente em /etc/shells"
elif [ -f /etc/shells ]; then
    backup_file /etc/shells
    printf '%s\n' '/sbin/nologin' >> /etc/shells
    echo "OK: /sbin/nologin adicionado em /etc/shells"
else
    echo "SKIP: /etc/shells nao encontrado"
fi

echo "[152] PATH do root"
SAFE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if ensure_parent "$ROOT_PROFILE"; then
    [ -e "$ROOT_PROFILE" ] || touch "$ROOT_PROFILE"
    backup_file "$ROOT_PROFILE"
    if grep -Eq '^[[:space:]]*PATH=' "$ROOT_PROFILE"; then
        sed -i "s|^[[:space:]]*PATH=.*|PATH=${SAFE_PATH}|" "$ROOT_PROFILE"
    else
        printf 'PATH=%s\n' "$SAFE_PATH" >> "$ROOT_PROFILE"
    fi
    echo "OK: PATH do root definido em $ROOT_PROFILE"
fi

echo "[153] umask 027"
if write_managed_file "$UMASK_FILE" 0644 'umask 027'; then
    echo "OK: umask 027 definido em $UMASK_FILE"
fi
for file in /etc/profile /etc/bashrc; do
    [ -f "$file" ] || continue
    backup_file "$file"
    if grep -Eq '^[[:space:]]*umask[[:space:]]+' "$file"; then
        sed -i 's|^[[:space:]]*umask[[:space:]].*|umask 027|' "$file"
    else
        printf '%s\n' 'umask 027' >> "$file"
    fi
    echo "OK: umask 027 definido em $file"
done

echo "[154] TMOUT 900"
if write_managed_file "$TMOUT_FILE" 0644 'TMOUT=900' 'export TMOUT'; then
    echo "OK: TMOUT 900 definido em $TMOUT_FILE"
fi
for file in /etc/profile /etc/bashrc; do
    [ -f "$file" ] || continue
    backup_file "$file"
    sed -i \
        -e '/^[[:space:]]*TMOUT=/d' \
        -e '/^[[:space:]]*readonly[[:space:]]\+TMOUT\b/d' \
        -e '/^[[:space:]]*export[[:space:]]\+TMOUT\b/d' \
        "$file"
    printf '%s\n' 'TMOUT=900' 'export TMOUT' >> "$file"
    echo "OK: TMOUT 900 definido em $file"
done

echo "[155] Ausencia de regras amplas sudo"
echo "INFO: regras de delegacao existentes foram preservadas; remocao exige revisao nominal"

echo "[156,157,159] Defaults seguros de sudo"
if ensure_parent "$SUDO_FILE"; then
    backup_file "$SUDO_FILE"
    {
        printf '# Gerenciado pela automacao HITSS hardening\n'
        printf 'Defaults use_pty\n'
        printf 'Defaults logfile="/var/log/sudo.log"\n'
        printf 'Defaults timestamp_timeout=5\n'
    } > "$SUDO_FILE"
    chmod 0440 "$SUDO_FILE" 2>/dev/null || echo "WARN: nao foi possivel ajustar permissao de $SUDO_FILE"

    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf /etc/sudoers >/dev/null 2>&1; then
            echo "OK: defaults de sudo validados em $SUDO_FILE"
        else
            if [ -e "${SUDO_FILE}.hitss.bak.${TS}" ]; then
                cp -p "${SUDO_FILE}.hitss.bak.${TS}" "$SUDO_FILE"
            else
                rm -f "$SUDO_FILE"
            fi
            echo "WARN: sudoers invalido; rollback automatico aplicado"
        fi
    else
        echo "SKIP: visudo nao encontrado para validar $SUDO_FILE"
    fi
fi

echo "OK"
exit 0
