#!/usr/bin/env bash
echo "[129 - 136] - Cron , configurações e Permissões"

echo -e "\n[129] Verifique se o serviço cron está habilitado e ativo"
systemctl is-enabled crond &>/dev/null && systemctl is-active crond &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

check_perm() {
  local path="$1"
  local expected="$2"
  local id="$3"
  echo -e "\n[$id] Verificando permissões de $path"
  [ -e "$path" ] && [ "$(stat -c %a "$path")" == "$expected" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
}

check_perm "/etc/crontab" "600" "130"
check_perm "/etc/cron.hourly" "700" "131"
check_perm "/etc/cron.daily" "700" "132"
check_perm "/etc/cron.weekly" "700" "133"
check_perm "/etc/cron.monthly" "700" "134"
check_perm "/etc/cron.d" "700" "135"

echo -e "\n[136] Verifique se /etc/cron.allow existe e está restrito"
[ -e /etc/cron.allow ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"