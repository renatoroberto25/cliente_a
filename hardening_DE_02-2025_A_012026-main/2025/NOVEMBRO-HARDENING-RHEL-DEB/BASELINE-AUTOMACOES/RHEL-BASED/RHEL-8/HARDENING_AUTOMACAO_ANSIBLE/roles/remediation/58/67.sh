#!/usr/bin/env bash
echo "[67 - 68] Verificar se GDM está presente e informar recomendação de remoção"

if rpm -q gdm &>/dev/null || systemctl list-units --type=service | grep -q gdm; then
  echo "⚠️ GDM detectado no sistema."
  echo "❗ Recomendação: REMOVA o GDM — servidores não devem ter interface gráfica."
  echo "👉 Execute manualmente:"
  echo "    systemctl disable gdm --now"
  echo "    yum remove -y gdm gnome* dconf*"
else
  echo "✅ GDM não está instalado — nenhum problema encontrado."
fi