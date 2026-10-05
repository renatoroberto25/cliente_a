#!/usr/bin/env bash
echo "[69 - 73] Recomendação: Remover GDM ou configurar manualmente"

if rpm -q gdm &>/dev/null || [ -d /etc/dconf/db/gdm.d ]; then
  echo "⚠️ GDM detectado. Para ambientes server, recomenda-se removê-lo:"
  echo "  systemctl disable gdm --now"
  echo "  yum remove -y gdm gnome*"
  echo ""
  echo "Ou, caso precise manter GDM, edite o arquivo:"
  echo "  /etc/dconf/db/gdm.d/00-security-settings"
  echo "E adicione as seguintes linhas:"
  echo "  automount=false"
  echo "  automount-open=false"
  echo "  autorun-never=true"
  echo ""
  echo "Depois, execute: dconf update"
else
  echo "✅ GDM não presente — nenhum problema identificado"
fi