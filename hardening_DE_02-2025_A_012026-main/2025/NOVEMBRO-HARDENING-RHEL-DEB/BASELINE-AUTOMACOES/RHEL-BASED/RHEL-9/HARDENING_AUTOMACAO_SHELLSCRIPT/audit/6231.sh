#!/usr/bin/env bash
echo " 228 Ensure rsyslog is installed "

if rpm -q rsyslog &>/dev/null; then
echo "✅ [APROVADO]: rsyslog está instalado"
else
echo "⚠️[REPROVADO]: rsyslog NÃO está instalado"
fi

echo " 229 Ensure rsyslog service is enabled and active"

rsyslog_enabled=$(systemctl is-enabled rsyslog.service 2>/dev/null)
rsyslog_active=$(systemctl is-active rsyslog.service 2>/dev/null)

if [[ "$rsyslog_enabled" == "enabled" && "$rsyslog_active" == "active" ]]; then
echo "✅ [APROVADO]: rsyslog.service está habilitado e ativo"
else
echo "⚠️[REPROVADO]: rsyslog.service NÃO está habilitado ou ativo"
echo "Status: enabled=$rsyslog_enabled, active=$rsyslog_active"
fi

echo " 230 Ensure journald is configured to send logs to rsyslog"
forwardtosyslog_status=$(systemd-analyze cat-config systemd/journald.conf systemd/journald.conf.d/* | grep -E "^ForwardToSyslog=yes")
if [[ -n "$forwardtosyslog_status" ]]; then
echo "✅ [APROVADO]: Syslog está configurado para enviar logs."
else
echo "⚠️[REPROVADO]: Syslog NÃO está configurado para enviar logs."
fi

echo "231 Ensure rsyslog log file creation mode is configured"
file_create_mode=$(egrep -Eoi '^\s*(\$)?FileCreateMode\s*(=|)\s*["'\''"]?(0[0-7]{3})["'\''"]?' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null | grep -Eo '0[0-7]{3}' | head -n1)
if [[ -n "$file_create_mode" ]]; then
    if (( 8#$file_create_mode <= 8#0640 )); then
echo "✅ [APROVADO]: FileCreateMode está configurado corretamente como $file_create_mode"
    else
echo "⚠️[REPROVADO]: FileCreateMode ($file_create_mode) está mais permissivo que 0640"
    fi
else
echo "⚠️[REPROVADO]: FileCreateMode não está configurado"
fi

echo "232 Ensure rsyslog logging is configured"
echo "Edite os seguintes arquivos /etc/rsyslog.conf e /etc/rsyslog.d/*.conf conforme apropriado para seu ambiente."
if [[ -f /var/log/messages ]]; then
echo "✅ Existe /var/log/messages, o que sugere que há logging mínimo."
else
echo "⚠️ Não existe /var/log/messages, o que sugere que não há logging mínimo."
fi

echo "233 Ensure rsyslog is configured to send logs to a remote log host"
resultado=$(grep -Psi -- '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)
if [[ -n "$resultado" ]]; then
echo "$resultado"
echo "✅ [APROVADO]: rsyslog está configurado para enviar logs para um host remoto."
else
echo "⚠️[REPROVADO]: rsyslog NÃO está configurado para enviar logs para um host remoto."
fi

echo "234 Ensure rsyslog is not configured to receive logs from a remote client"
recebe_logs=$(grep -Psi -- '^\s*module\s*\(\s*load\s*=\s*"?imtcp"?\s*\)' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)
recebe_logs+=$(grep -Psi -- '^\s*input\s*\(\s*type\s*=\s*"?imtcp"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)
if [[ -n "$recebe_logs" ]]; then
echo "$recebe_logs"
echo "⚠️[REPROVADO]: rsyslog está configurado para receber logs de clientes remotos."
else
echo "✅ [APROVADO]: rsyslog NÃO está configurado para receber logs de clientes remotos."
fi