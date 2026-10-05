#!/usr/bin/env bash

echo -e "\n[40 - 43] Configuração AppArmor"

echo "[40] Instalando AppArmor e utilitários"
apt-get update -qq && apt-get install -y apparmor apparmor-utils >/dev/null 2>&1

echo "[41] Habilitando AppArmor no bootloader"
if ! grep -q "apparmor=1" /etc/default/grub; then
    cp /etc/default/grub /etc/default/grub.bak_$(date +%F_%H%M)
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="apparmor=1 security=apparmor /' /etc/default/grub
    update-grub >/dev/null 2>&1
fi

echo "[42] Ativando perfis AppArmor em modo enforce"
aa-enforce /etc/apparmor.d/* >/dev/null 2>&1

echo "[43] Habilitando e iniciando serviço AppArmor"
systemctl enable --now apparmor >/dev/null 2>&1
