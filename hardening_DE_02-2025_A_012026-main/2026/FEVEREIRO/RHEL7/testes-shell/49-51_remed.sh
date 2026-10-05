#!/usr/bin/env bash
echo -e "\n[49 - 51] Remediação Bootloader e Single User Mode (RHEL 7)"

backup() {
    if [ -f "$1" ]; then
        cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
    fi
}

echo -e "\n[49] Senha do bootloader (orientação)"
if grep -q 'password_pbkdf2' /boot/grub2/grub.cfg 2>/dev/null; then
    echo " Senha do GRUB já configurada"
else
    echo " Senha do GRUB não configurada"
    echo " Para configurar manualmente:"
    echo " # grub2-setpassword"
fi

echo -e "\n[50] Permissões seguras no /boot/grub2/grub.cfg"
GRUBCFG="/boot/grub2/grub.cfg"
if [ -f "$GRUBCFG" ]; then
    PERM_OUT=$(stat -Lc '%a %U %G' "$GRUBCFG" 2>/dev/null || echo "")
    if echo "$PERM_OUT" | grep -Eq '^(400|600) root root$'; then
        echo " Permissões do GRUB adequadas ($PERM_OUT)"
    else
        backup "$GRUBCFG"
        chmod 600 "$GRUBCFG" 2>/dev/null || true
        chown root:root "$GRUBCFG" 2>/dev/null || true
        PERM_OUT2=$(stat -Lc '%a %U %G' "$GRUBCFG" 2>/dev/null || echo "")
        if echo "$PERM_OUT2" | grep -Eq '^600 root root$'; then
            echo " Permissões do GRUB ajustadas para 600 root:root"
        else
            echo " Não foi possível garantir 600 root:root em $GRUBCFG (atual: $PERM_OUT2)"
        fi
    fi
else
    echo " Arquivo $GRUBCFG não encontrado"
fi

echo -e "\n[51] Single user mode com autenticação (RHEL 7)"
EMERGENCY_UNIT="/usr/lib/systemd/system/emergency.service"
OVR_DIR="/etc/systemd/system/emergency.service.d"
OVERRIDE="$OVR_DIR/override.conf"
# valida existência (audit-driven)
if [ ! -f "$EMERGENCY_UNIT" ]; then
    echo " emergency.service não existe — controle não aplicável"
    exit 0
fi
# audit logic: reprova apenas se houver shell direto
if ! grep -q '^ExecStart=-/bin/sh' "$EMERGENCY_UNIT"; then
    echo " Single-user mode já exige autenticação"
    exit 0
fi
echo " Shell direto detectado em emergency.service — aplicando correção"
# backup do unit original (boa prática)
cp -a "$EMERGENCY_UNIT" "$EMERGENCY_UNIT.bkp_$(date +%Y%m%d_%H%M%S)"
# cria override (não altera vendor unit)
mkdir -p "$OVR_DIR"
if [ -f "$OVERRIDE" ]; then
    cp -a "$OVERRIDE" "$OVERRIDE.bkp_$(date +%Y%m%d_%H%M%S)"
fi
cat > "$OVERRIDE" <<EOF
[Service]
ExecStart=
ExecStart=-/usr/lib/systemd/systemd-sulogin-shell emergency
EOF
# recarrega systemd de forma segura
systemctl daemon-reexec >/dev/null 2>&1 || true
echo " Single-user mode corrigido via sulogin (override aplicado)"

