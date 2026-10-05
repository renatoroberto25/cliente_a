#!/usr/bin/env bash
echo -e "\n[136] Remediação – Certifique-se de que um único utilitário de firewall esteja em uso"

{
  l_fwd_status="" l_nft_status="" l_fwutil_status=""

  # Estado do FirewallD
  rpm -q firewalld &>/dev/null && l_fwd_status="$(systemctl is-enabled firewalld.service):$(systemctl is-active firewalld.service)"

  # Estado do NFTables
  rpm -q nftables &>/dev/null && l_nft_status="$(systemctl is-enabled nftables.service):$(systemctl is-active nftables.service)"

  l_fwutil_status="$l_fwd_status:$l_nft_status"

  case "$l_fwutil_status" in
    enabled:active:masked:inactive|enabled:active:disabled:inactive)
      echo "[✅ SUCESSO]: Apenas o FirewallD está ativo. Nenhuma ação necessária."
      ;;
    masked:inactive:enabled:active|disabled:inactive:enabled:active)
      echo "[✅ SUCESSO]: Apenas o nftables está ativo. Nenhuma ação necessária."
      ;;
    enabled:active:enabled:active)
      echo "⚠️ Conflito: Ambos ativos. Mascarando o nftables..."
      systemctl stop nftables && systemctl mask nftables
      ;;
    enabled:*:enabled:*)
      if [ "$(awk -F: '{print $2}' <<< "$l_fwutil_status")" = "active" ]; then
        echo "⚠️ Conflito: Ambos instalados. Mantendo firewalld. Mascarando nftables..."
        systemctl stop nftables && systemctl mask nftables
      elif [ "$(awk -F: '{print $4}' <<< "$l_fwutil_status")" = "active" ]; then
        echo "⚠️ Conflito: Ambos instalados. Mantendo nftables. Mascarando firewalld..."
        systemctl stop firewalld && systemctl mask firewalld
      fi
      ;;
    *:active:*:active)
      if [ "$(awk -F: '{print $1}' <<< "$l_fwutil_status")" = "enabled" ]; then
        echo "⚠️ Ambos ativos. Mantendo firewalld. Mascarando nftables..."
        systemctl stop nftables && systemctl mask nftables
      elif [ "$(awk -F: '{print $3}' <<< "$l_fwutil_status")" = "enabled" ]; then
        echo "⚠️ Ambos ativos. Mantendo nftables. Mascarando firewalld..."
        systemctl stop firewalld && systemctl mask firewalld
      fi
      ;;
    :enabled:active)
      echo "[✅ SUCESSO]: Apenas nftables está instalado e ativo. Nenhuma ação necessária."
      ;;
    :)
      echo "⚠️ Nenhum firewall instalado. Instalando nftables..."
      dnf -qy install nftables
      ;;
    *:*:)
      echo "⚠️ nftables não instalado. Instalando..."
      dnf -qy install nftables
      ;;
    *)
      echo "❗ Estado do firewall não pôde ser determinado. Verificação manual necessária."
      ;;
  esac
}