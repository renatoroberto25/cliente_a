#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: bootloader e single-user"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"
GRUBCFG="/boot/grub2/grub.cfg"
EMERGENCY_UNIT="/usr/lib/systemd/system/emergency.service"

backup_file() {
    local file="$1"
    [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null || true
}

echo "[50] Permissoes seguras no arquivo do bootloader"
if [ ! -f "$GRUBCFG" ]; then
    echo "SKIP: $GRUBCFG nao encontrado"
else
    backup_file "$GRUBCFG"
    if chown root:root "$GRUBCFG" 2>/dev/null && chmod 0600 "$GRUBCFG" 2>/dev/null; then
        echo "OK: $GRUBCFG ajustado para 0600 root:root"
    else
        echo "WARN: falha ao ajustar permissoes de $GRUBCFG"
    fi
fi

echo "[51] Single user mode com autenticacao"
if [ ! -f "$EMERGENCY_UNIT" ]; then
    echo "SKIP: $EMERGENCY_UNIT nao encontrado"
elif grep -q '^ExecStart=-/bin/sh' "$EMERGENCY_UNIT" 2>/dev/null; then
    echo "SKIP: emergency.service usa shell direto; alteracao exige janela e validacao de boot/recovery"
else
    echo "OK: emergency.service nao expoe ExecStart direto para /bin/sh"
fi

echo "OK"
exit 0
