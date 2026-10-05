#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: permissoes de arquivos sensiveis"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

fix_file() {
    local id="$1" file="$2" mode="$3" owner="$4" group="$5"

    echo "[$id] $file"
    if [ ! -f "$file" ]; then
        echo "SKIP: $file nao encontrado"
        return
    fi

    backup_file "$file"

    chmod "$mode" "$file" 2>/dev/null || {
        echo "WARN: nao foi possivel ajustar permissao de $file"
        return
    }
    chown "${owner}:${group}" "$file" 2>/dev/null || {
        echo "WARN: nao foi possivel ajustar owner/group de $file"
        return
    }

    echo "OK: $file mode=$mode owner=${owner}:${group}"
}

fix_file 185 /etc/passwd 0644 root root
fix_file 186 /etc/passwd- 0644 root root
fix_file 187 /etc/shadow 0000 root root
fix_file 188 /etc/shadow- 0000 root root
fix_file 189 /etc/gshadow- 0000 root root
fix_file 190 /etc/gshadow 0000 root root
fix_file 191 /etc/group 0644 root root
fix_file 192 /etc/group- 0644 root root

fix_file 194 /etc/security/opasswd 0600 root root

echo "OK"
exit 0
