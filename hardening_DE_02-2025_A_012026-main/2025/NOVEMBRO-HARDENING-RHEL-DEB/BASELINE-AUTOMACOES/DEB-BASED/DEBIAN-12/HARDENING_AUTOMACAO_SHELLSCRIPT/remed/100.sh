#!/usr/bin/env bash
# Remedia - Controles 100 a 106 (Cron)
TS="$(date +%F_%H%M%S)"

ok(){ printf '✅ %s\n' "$1"; }
warn(){ printf '⚠️ %s\n' "$1"; }

echo -e "\n[100] Garantir que /etc/crontab tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/crontab 2>/dev/null | grep -Eq '^600 root root$'; then
  warn "REPROVADO → aplicando correção em /etc/crontab"
  [ -f /etc/crontab ] && cp -a /etc/crontab "/etc/crontab.bak_${TS}"
  chown root:root /etc/crontab 2>/dev/null || warn "chown falhou para /etc/crontab"
  chmod 600 /etc/crontab 2>/dev/null || warn "chmod falhou para /etc/crontab"
else
  ok "/etc/crontab OK"
fi

echo -e "\n[101] Garantir que /etc/cron.hourly tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/cron.hourly 2>/dev/null | grep -Eq '^700 root root$'; then
  warn "REPROVADO → aplicando correção em /etc/cron.hourly"
  if [ -e /etc/cron.hourly ]; then
    cp -a /etc/cron.hourly "/etc/cron.hourly.bak_${TS}" 2>/dev/null || warn "backup falhou /etc/cron.hourly"
    chown root:root /etc/cron.hourly 2>/dev/null || warn "chown falhou /etc/cron.hourly"
    chmod 700 /etc/cron.hourly 2>/dev/null || warn "chmod falhou /etc/cron.hourly"
  else
    warn "/etc/cron.hourly não existe — nada a corrigir"
  fi
else
  ok "/etc/cron.hourly OK"
fi

echo -e "\n[102] Garantir que /etc/cron.daily tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/cron.daily 2>/dev/null | grep -Eq '^700 root root$'; then
  warn "REPROVADO → aplicando correção em /etc/cron.daily"
  if [ -e /etc/cron.daily ]; then
    cp -a /etc/cron.daily "/etc/cron.daily.bak_${TS}" 2>/dev/null || warn "backup falhou /etc/cron.daily"
    chown root:root /etc/cron.daily 2>/dev/null || warn "chown falhou /etc/cron.daily"
    chmod 700 /etc/cron.daily 2>/dev/null || warn "chmod falhou /etc/cron.daily"
  else
    warn "/etc/cron.daily não existe — nada a corrigir"
  fi
else
  ok "/etc/cron.daily OK"
fi

echo -e "\n[103] Garantir que /etc/cron.weekly tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/cron.weekly 2>/dev/null | grep -Eq '^700 root root$'; then
  warn "REPROVADO → aplicando correção em /etc/cron.weekly"
  if [ -e /etc/cron.weekly ]; then
    cp -a /etc/cron.weekly "/etc/cron.weekly.bak_${TS}" 2>/dev/null || warn "backup falhou /etc/cron.weekly"
    chown root:root /etc/cron.weekly 2>/dev/null || warn "chown falhou /etc/cron.weekly"
    chmod 700 /etc/cron.weekly 2>/dev/null || warn "chmod falhou /etc/cron.weekly"
  else
    warn "/etc/cron.weekly não existe — nada a corrigir"
  fi
else
  ok "/etc/cron.weekly OK"
fi

echo -e "\n[104] Garantir que /etc/cron.monthly tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/cron.monthly 2>/dev/null | grep -Eq '^700 root root$'; then
  warn "REPROVADO → aplicando correção em /etc/cron.monthly"
  if [ -e /etc/cron.monthly ]; then
    cp -a /etc/cron.monthly "/etc/cron.monthly.bak_${TS}" 2>/dev/null || warn "backup falhou /etc/cron.monthly"
    chown root:root /etc/cron.monthly 2>/dev/null || warn "chown falhou /etc/cron.monthly"
    chmod 700 /etc/cron.monthly 2>/dev/null || warn "chmod falhou /etc/cron.monthly"
  else
    warn "/etc/cron.monthly não existe — nada a corrigir"
  fi
else
  ok "/etc/cron.monthly OK"
fi

echo -e "\n[105] Garantir que /etc/cron.d tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/cron.d 2>/dev/null | grep -Eq '^700 root root$'; then
  warn "REPROVADO → aplicando correção em /etc/cron.d"
  if [ -e /etc/cron.d ]; then
    cp -a /etc/cron.d "/etc/cron.d.bak_${TS}" 2>/dev/null || warn "backup falhou /etc/cron.d"
    chown root:root /etc/cron.d 2>/dev/null || warn "chown falhou /etc/cron.d"
    chmod 700 /etc/cron.d 2>/dev/null || warn "chmod falhou /etc/cron.d"
  else
    warn "/etc/cron.d não existe — nada a corrigir"
  fi
else
  ok "/etc/cron.d OK"
fi

echo -e "\n[106] Garantir que /etc/cron.allow exista e tenha permissões corretas"
if ! stat -Lc "%a %U %G" /etc/cron.allow 2>/dev/null | grep -Eq '^640 root (root|crontab)$'; then
  warn "REPROVADO → aplicando correção em /etc/cron.allow"
  [ -f /etc/cron.allow ] && cp -a /etc/cron.allow "/etc/cron.allow.bak_${TS}"
  touch /etc/cron.allow 2>/dev/null || warn "Não foi possível criar /etc/cron.allow"
  chown root:root /etc/cron.allow 2>/dev/null || warn "chown falhou para /etc/cron.allow"
  chmod 640 /etc/cron.allow 2>/dev/null || warn "chmod falhou para /etc/cron.allow"
else
  ok "/etc/cron.allow OK"
fi

echo -e "\nConcluído. Verifique backups *.bak_${TS} se quiser reverter manualmente."