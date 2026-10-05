#!/bin/bash

echo "220 Ensure only one logging system is in use"

rsyslog_active=$(systemctl is-active rsyslog 2>/dev/null)
rsyslog_enabled=$(systemctl is-enabled rsyslog 2>/dev/null)
journald_forward=$(grep -i '^ForwardToSyslog=' /etc/systemd/journald.conf | awk -F= '{print $2}' | tr '[:upper:]' '[:lower:]')

# Se rsyslog está ativo e journald não está encaminhando
if [[ "$rsyslog_active" == "active" && ( -z "$journald_forward" || "$journald_forward" == "no" ) ]]; then    
echo "✅ [APROVADO]:  rsyslog está em uso - siga apenas as recomendações na subseção Configurar rsyslog"
    exit 0
fi

# Se rsyslog não está ativo ou instalado
if ! rpm -q rsyslog >/dev/null || [[ "$rsyslog_active" != "active" ]]; then
echo "✅ [APROVADO]:  apenas journald está em uso - siga apenas as recomendações na subseção Configurar journald"
    exit 0
fi

# Caso contrário, há dois sistemas operando juntos
echo "⚠️ FALHA: journald e rsyslog estão ativos simultaneamente. Desative um deles conforme sua política."
exit 1