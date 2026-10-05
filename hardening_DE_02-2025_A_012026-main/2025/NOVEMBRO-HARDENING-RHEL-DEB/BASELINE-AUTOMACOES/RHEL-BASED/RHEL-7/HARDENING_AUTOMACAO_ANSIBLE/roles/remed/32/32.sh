#!/usr/bin/env bash
# [32-34] Remediação HITSS - Bootloader e modo single-user (Servidores baseados em RHEL 7)
# Alinhado 1:1 com audit_hitss_32-34.sh
# 32 → Manual (somente orientação)
# 33 → Corrige perms de grub.cfg e user.cfg
# 34 → Garante sulogin em rescue/emergency
set -euo pipefail

# [32] Senha do bootloader - manual
cfg_file="/boot/grub2/user.cfg"
echo -e "\n[32] Configurar senha no bootloader (manual)"
if [ ! -f "$cfg_file" ]; then
  echo "⚠️ Arquivo não encontrado: $cfg_file"
  echo "Execute manualmente:"
  echo "    grub2-setpassword"
  echo "Depois valide se o audit marca como APROVADO."
elif grep -Eq '^\s*GRUB2_PASSWORD=grub\.pbkdf2\.sha512' "$cfg_file"; then
  echo "✅ Senha já configurada corretamente no GRUB."
else
  echo "⚠️ Nenhuma senha detectada em $cfg_file"
  echo "Execute manualmente:"
  echo "    grub2-setpassword"
  echo "Depois valide com o audit novamente."
fi

# [33] Permissões de bootloader
echo -e "\n[33] Corrigir permissões de grub.cfg e user.cfg"
cfg="/boot/grub2/grub.cfg"
usr="/boot/grub2/user.cfg"
[ -f "$cfg" ] && chmod 400 "$cfg" && chown root:root "$cfg"
[ -f "$usr" ] && chmod 600 "$usr" && chown root:root "$usr"
echo "✅ Permissões e propriedade ajustadas (400/600 root:root)"

# [34] Autenticação no modo single-user
echo -e "\n[34] Garantir autenticação no modo single-user"
for svc in /usr/lib/systemd/system/rescue.service /usr/lib/systemd/system/emergency.service; do
  if [ -f "$svc" ]; then
    grep -q '/sbin/sulogin' "$svc" || sed -i '/ExecStart=/s|=.*|=-/sbin/sulogin|' "$svc"
  fi
done
systemctl daemon-reexec 2>/dev/null || true
echo "✅ Autenticação exigida no modo single-user"
