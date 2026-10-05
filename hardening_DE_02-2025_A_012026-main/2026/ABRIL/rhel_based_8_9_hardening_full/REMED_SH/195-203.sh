#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"

echo "[195 - 203] Remediação – Segurança de homes e arquivos especiais"

backup_file() {
    local f="$1"
    [ -f "$f" ] && cp -a "$f" "${f}.bkp-${TS}"
}

usuarios() {
    awk -F: '$3>=1000 && $1!="nfsnobody"{print $1,$6}' /etc/passwd
}

echo -e "\n[195] Corrigir arquivos órfãos (nouser/nogroup)"
orphans=$(find / -xdev \( -nouser -o -nogroup \) 2>/dev/null || true)
if [ -n "${orphans}" ]; then
    while read -r f; do
        chown 0:0 "$f" 2>/dev/null || true
    done <<< "$orphans"
    echo "✔ Ownership ajustado"
else
    echo "✔ Nenhum arquivo órfão encontrado"
fi

echo -e "\n[196] Remover world-writable fora das áreas permitidas"
/usr/bin/find / -xdev \
    -not -path "/tmp/*" \
    -not -path "/var/tmp/*" \
    -not -path "/dev/shm/*" \
    -perm -0002 2>/dev/null |
while read -r f; do
    chmod o-w "$f" 2>/dev/null || true
done
echo "✔ Permissões ajustadas"

echo -e "\n[198] Remover SUID/SGID indevidos (com whitelist segura)"

WHITELIST=(
    /usr/bin/sudo
    /usr/bin/su
    /bin/su
    /usr/bin/passwd
    /usr/bin/chage
    /usr/bin/chsh
    /usr/bin/chfn
    /usr/bin/newgrp
    /usr/bin/gpasswd
    /usr/sbin/unix_chkpwd
    /usr/sbin/pam_timestamp_check
    /usr/bin/mount
    /usr/bin/umount
    /usr/bin/fusermount
    /usr/bin/pkexec
    /usr/bin/crontab
    /usr/bin/ssh-agent
    /usr/bin/ksu
    /usr/libexec/openssh/ssh-keysign
    /usr/bin/ping
    /usr/bin/ping6
    /usr/bin/traceroute
    /usr/bin/traceroute6
)

is_whitelisted() {
    local file="$1"
    for w in "${WHITELIST[@]}"; do
        [[ "$file" == "$w" ]] && return 0
    done
    return 1
}

find / -xdev \( -perm -4000 -o -perm -2000 \) 2>/dev/null |
while read -r f; do
    if is_whitelisted "$f"; then
        echo "→ Mantido (whitelist): $f"
    else
        chmod ug-s "$f" 2>/dev/null || true
        echo "→ Removido SUID/SGID: $f"
    fi
done
echo "✔ SUID/SGID ajustado com segurança"

echo -e "\n[202] Corrigir dotfiles inseguros"
while read -r user home; do
    find "$home" -maxdepth 1 -type f -name ".*" -perm /022 2>/dev/null |
    while read -r f; do
        chmod go-w "$f" 2>/dev/null || true
    done
done < <(awk -F: '$3>=1000 && $1!="nfsnobody"{print $1,$6}' /etc/passwd)
echo "✔ Dotfiles corrigidos"

echo -e "\n[203] Remover .forward/.netrc/.rhosts"
while read -r user home; do
    for f in "$home/.forward" "$home/.netrc" "$home/.rhosts"; do
        if [ -f "$f" ]; then
            backup_file "$f"
            rm -f "$f"
        fi
    done
done < <(awk -F: '$3>=1000 && $1!="nfsnobody"{print $1,$6}' /etc/passwd)
echo "✔ Arquivos sensíveis removidos"

echo "OK"

exit 0
