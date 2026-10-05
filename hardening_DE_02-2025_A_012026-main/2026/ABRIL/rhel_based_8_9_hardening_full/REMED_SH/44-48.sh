#!/usr/bin/env bash

echo "[44 - 48] Remediação: Sticky bit e Autofs"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}
find / -xdev -type d -perm -0002 ! -perm -1000
echo -e "\n[44] Aplicar sticky bit em diretórios world-writable"

WW_DIRS=$(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null)

if [ -n "$WW_DIRS" ]; then
    for d in $WW_DIRS; do
        chmod +t "$d" 2>/dev/null && \
            echo "✔ Sticky aplicado: $d" || \
            echo "⚠️ Falha ao aplicar sticky: $d"
    done
else
    echo "✔ Nenhum diretório inseguro encontrado"
fi
echo -e "\n[45] Sticky bit em /tmp"

if stat -c "%A" /tmp | grep -q 't'; then
    echo "✔ /tmp já contém sticky bit"
else
    chmod +t /tmp && echo "✔ Sticky aplicado em /tmp" || echo "⚠️ Falha ao aplicar sticky em /tmp"
fi
echo -e "\n[46] Sticky bit em /var/tmp"

if stat -c "%A" /var/tmp | grep -q 't'; then
    echo "✔ /var/tmp já contém sticky bit"
else
    chmod +t /var/tmp && echo "✔ Sticky aplicado em /var/tmp" || echo "⚠️ Falha ao aplicar sticky em /var/tmp"
fi
echo -e "\n[47] Sticky bit em /dev/shm"

if stat -c "%A" /dev/shm | grep -q 't'; then
    echo "✔ /dev/shm já contém sticky bit"
else
    chmod +t /dev/shm && echo "✔ Sticky aplicado em /dev/shm" || echo "⚠️ Falha ao aplicar sticky em /dev/shm"
fi
echo -e "\n[48] Desabilitar autofs"

if systemctl list-unit-files | grep -q "^autofs.service"; then
    if systemctl is-enabled autofs &>/dev/null; then
        systemctl disable autofs --now >/dev/null 2>&1
        systemctl mask autofs >/dev/null 2>&1
        echo "✔ autofs desabilitado e mascarado"
    else
        echo "✔ autfs já desabilitado"
    fi
else
    echo "✔ autofs não instalado no sistema"
fi

echo "OK"
exit 0
