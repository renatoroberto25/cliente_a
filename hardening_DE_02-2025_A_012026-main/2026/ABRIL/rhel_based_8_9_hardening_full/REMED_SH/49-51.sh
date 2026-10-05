#!/usr/bin/env bash
echo "[49 - 51] Bootloader e Single User Mode"

backup() {
    [ -f "$1" ] && cp "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

echo -e "\n[49] Senha do bootloader (orientação)"
if grep -q 'password_pbkdf2' /boot/grub2/grub.cfg 2>/dev/null; then
    echo "✔ Senha do GRUB já configurada"
else
    echo "⚠️ Senha do GRUB não configurada"
    echo "   Para configurar:"
    echo "   # grub2-setpassword"
fi

echo -e "\n[50] Permissões seguras no /boot/grub2/grub.cfg"

GRUBCFG="/boot/grub2/grub.cfg"

if [ -f "$GRUBCFG" ]; then
    if stat -Lc '%a %U %G' "$GRUBCFG" | grep -Eq '^(400|600) root root$'; then
        echo "✔ Permissões do GRUB adequadas"
    else
        chmod 600 "$GRUBCFG" 2>/dev/null
        chown root:root "$GRUBCFG" 2>/dev/null
        echo "✔ Permissões do GRUB ajustadas para 600 root:root"
    fi
else
    echo "⚠️ Arquivo grub.cfg não encontrado"
fi

echo -e "\n[51] Single user mode com autenticação"

FILE="/usr/lib/systemd/system/emergency.service"

if [ -f "$FILE" ]; then
    if grep -q '^ExecStart=-/bin/sh' "$FILE"; then
        backup "$FILE"
        sed -i 's/^ExecStart=-\/bin\/sh/#ExecStart=-\/bin\/sh/' "$FILE"

        if grep -q '^ExecStart=-/usr/lib/systemd/systemd-sulogin-shell emergency' "$FILE"; then
            echo "✔ Shell direto removido — autenticação exigida no single-user"
        else
            echo "ExecStart=-/usr/lib/systemd/systemd-sulogin-shell emergency" >> "$FILE"
            echo "✔ Shell direto removido — autenticação exigida no single-user"
        fi
    else
        echo "✔ Single-user mode já exige autenticação"
    fi
else
    echo "⚠️ emergency.service não encontrado"
fi

echo "OK"
exit 0
