#!/usr/bin/env bash
echo "[64 - 68] Auditoria consolidada: acesso e configuração de arquivos de banner e GDM"

check_perms() {
  local arquivo="$1"
  local id="$2"
  if [ -e "$arquivo" ]; then
    local perms=$(stat -c "%a" "$arquivo")
    local owner=$(stat -c "%U:%G" "$arquivo")
    if [[ "$perms" == "644" && "$owner" == "root:root" ]]; then
      echo "✅ [$id] $arquivo com permissões corretas ($perms $owner)"
    else
      echo "⚠️ [$id] $arquivo com permissões incorretas ($perms $owner)"
    fi
  else
    echo "⚠️ [$id] $arquivo não existe"
  fi
}

# 64, 65, 66 → permissões de arquivos
check_perms "/etc/motd"       "64"
check_perms "/etc/issue"      "65"
check_perms "/etc/issue.net"  "66"

# 67 e 68 → GDM
arquivo_gdm="/etc/dconf/db/gdm.d/00-security-settings"

if [ -f "$arquivo_gdm" ]; then
  grep -q '^banner-message-enable=true' "$arquivo_gdm" && \
    echo "✅ [67] GDM: banner-message-enable=true" || \
    echo "⚠️ [67] GDM: banner-message-enable ausente"

  grep -q '^disable-user-list=true' "$arquivo_gdm" && \
    echo "✅ [68] GDM: disable-user-list=true" || \
    echo "⚠️ [68] GDM: disable-user-list ausente"
else
  echo "ℹ️ [67-68] GDM não instalado ou sem configuração detectada"
fi