#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: sticky bit e montagem automatica"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

apply_sticky() {
    local id="$1" dir="$2"
    echo "[$id] Sticky bit em $dir"

    if [ ! -d "$dir" ]; then
        echo "SKIP: $dir nao existe"
        return
    fi

    if stat -c "%A" "$dir" 2>/dev/null | grep -q 't'; then
        echo "OK: $dir ja possui sticky bit"
        return
    fi

    if chmod +t "$dir" 2>/dev/null; then
        echo "OK: sticky bit aplicado em $dir"
    else
        echo "WARN: falha ao aplicar sticky bit em $dir"
    fi
}

echo "[44] Sticky bit em diretorios world-writable"
found=0
while IFS= read -r dir; do
    found=1
    if chmod +t "$dir" 2>/dev/null; then
        echo "OK: sticky bit aplicado em $dir"
    else
        echo "WARN: falha ao aplicar sticky bit em $dir"
    fi
done < <(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null)
[ "$found" -eq 0 ] && echo "OK: nenhum diretorio world-writable sem sticky bit encontrado"

apply_sticky 45 /tmp
apply_sticky 46 /var/tmp
apply_sticky 47 /dev/shm

echo "OK"
exit 0
