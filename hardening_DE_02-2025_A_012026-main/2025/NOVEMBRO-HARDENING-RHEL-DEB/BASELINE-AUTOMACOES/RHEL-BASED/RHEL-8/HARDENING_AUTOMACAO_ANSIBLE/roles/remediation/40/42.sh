#!/usr/bin/env bash
echo "[42] Ativar ASLR (kernel.randomize_va_space = 2)"

kp="kernel.randomize_va_space"
val="2"
conf="/etc/sysctl.d/60-kernel_aslr.conf"

# Backup, se existir
[ -f "$conf" ] && cp "$conf" "$conf.bak"

# Garante arquivo
touch "$conf"

# Remove duplicatas antigas do parâmetro
sed -i "/^\s*${kp}\s*=/d" "$conf"

# Insere linha correta
echo "$kp = $val" >> "$conf"
echo " - Configuração persistente aplicada em $conf"

# Aplica em runtime
sysctl -w "$kp=$val" >/dev/null && echo " - Runtime ajustado para $val"

echo "OBS: Reboot necessário para que a configuração seja validada como persistente."
