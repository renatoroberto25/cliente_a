#!/usr/bin/env bash
#remediação
echo "[129 - 136] - Cron e Permissões"

echo -e "\n[129] Garantindo que o serviço cron esteja habilitado e ativo"
systemctl is-enabled crond &>/dev/null && systemctl is-active crond &>/dev/null && echo "✅ crond já está ativo" || {
  systemctl enable crond --now &>/dev/null && echo "✅ crond habilitado e iniciado" || echo "❌ Falha ao habilitar crond"
}

fix_perm() {
  local path="$1"
  local expected="$2"
  local id="$3"
  echo -e "\n[$id] Corrigindo permissões de $path"
  if [ -e "$path" ]; then
    actual=$(stat -c %a "$path")
    if [ "$actual" != "$expected" ]; then
      chmod "$expected" "$path" && echo "✅ Permissão ajustada para $expected" || echo "❌ Falha ao ajustar permissões"
    else
      echo "✅ Permissões já corretas: $expected"
    fi
  else
    echo "❌ Caminho não encontrado: $path"
  fi
}

fix_perm "/etc/crontab" "600" "130"
fix_perm "/etc/cron.hourly" "700" "131"
fix_perm "/etc/cron.daily" "700" "132"
fix_perm "/etc/cron.weekly" "700" "133"
fix_perm "/etc/cron.monthly" "700" "134"
fix_perm "/etc/cron.d" "700" "135"

echo -e "\n[136] Garantindo restrição de uso do crontab"
if [ ! -e /etc/cron.allow ]; then
  touch /etc/cron.allow
  chmod 600 /etc/cron.allow
  echo "root" > /etc/cron.allow
  echo "✅ /etc/cron.allow criado e configurado"
else
  echo "✅ /etc/cron.allow já existe"
fi