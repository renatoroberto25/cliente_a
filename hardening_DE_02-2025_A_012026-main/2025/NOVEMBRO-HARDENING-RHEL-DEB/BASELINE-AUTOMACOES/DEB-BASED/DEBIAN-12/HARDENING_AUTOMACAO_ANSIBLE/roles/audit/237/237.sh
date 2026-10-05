#!/usr/bin/env bash

echo -e "\n[237] Verifique se o rsyslog está instalado"
dpkg -s rsyslog &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[238] Verifique se o serviço rsyslog está habilitado e ativo"
if systemctl list-unit-files 2>/dev/null | grep -q '^rsyslog.service'; then
  ( systemctl is-enabled --quiet rsyslog && systemctl is-active --quiet rsyslog ) \
    && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
else
  echo "⚠️ REPROVADO (serviço rsyslog inexistente)"
fi

echo -e "\n[239] Verifique se o journald envia logs para rsyslog"
grep -Psi '^\s*ForwardToSyslog=yes\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
  | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[240] Verifique se o modo de criação de arquivos do rsyslog está configurado"
grep -Psi '^\s*\$FileCreateMode\s+0[0-9]{3}\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null \
  | grep -Eq '\$FileCreateMode\s+0(640|60[0-3]|[0-5][0-9]{2})' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

#echo -e "\n[241] Verifique se o rsyslog está configurado para logging adequado (Manual)"
#echo "⚠️ REVISÃO MANUAL: confirme conteúdo de /etc/rsyslog.conf e /etc/rsyslog.d/*.conf conforme política"

#echo -e "\n[242] Verifique se o rsyslog envia logs a um host remoto (Manual)"
#echo "⚠️ REVISÃO MANUAL: confirme presença de linhas '*.* @@host:porta' em /etc/rsyslog.conf ou /etc/rsyslog.d/*.conf"

#echo -e "\n[243] Verifique se o rsyslog não está configurado para receber logs remotos"
#if grep -Psi '^\s*\$ModLoad\s+imtcp' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null \
#  || grep -Psi '^\s*\$InputTCPServerRun' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
#  echo "⚠️ REPROVADO"
#else
#  echo "✅ APROVADO"
#fi

#echo -e "\n[244] Verifique se o logrotate está configurado (Manual)"
#echo "⚠️ REVISÃO MANUAL: confirme existência e conteúdo de /etc/logrotate.conf e /etc/logrotate.d/*"

echo -e "\n[245] Verifique se o acesso a todos os arquivos de log está configurado"
find /var/log -type f -exec stat -Lc '%n %a' {} \; 2>/dev/null \
  | awk '$2 <= 640 {ok++} END{exit !(ok>0)}' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"