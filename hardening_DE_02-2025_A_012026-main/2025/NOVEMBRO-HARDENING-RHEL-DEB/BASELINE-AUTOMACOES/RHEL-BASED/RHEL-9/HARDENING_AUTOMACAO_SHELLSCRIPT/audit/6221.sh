#!/usr/bin/env bash
echo "#TÓPICOS VALIDOS APENAS SE O journald FOR O PADRÃO LOCAL CASO USE EXCLUSIVAMENTE rsyslog DESCONSIDERAR#"

echo " 221 Ensure systemd-journal-remote is installed"

if rpm -q systemd-journal-remote &>/dev/null; then
echo "✅ [APROVADO]: systemd-journal-remote está instalado"
else
echo "⚠️[REPROVADO]: systemd-journal-remote NÃO está instalado"
fi

echo " 222 Ensure systemd-journal-upload authentication is configured"

upload_config=$(grep -P "^ *URL=|^ *ServerKeyFile=|^ *ServerCertificateFile=|^ *TrustedCertificateFile=" /etc/systemd/journal-upload.conf 2>/dev/null)

if [[ -n "$upload_config" ]]; then
echo "✅ Parâmetros encontrados:"
echo "$upload_config"
else
echo "⚠️ Nenhuma configuração de autenticação encontrada em /etc/systemd/journal-upload.conf"
fi

echo " 223 Ensure systemd-journal-upload is enabled and active"

upload_enabled=$(systemctl is-enabled systemd-journal-upload.service 2>/dev/null)
upload_active=$(systemctl is-active systemd-journal-upload.service 2>/dev/null)

if [[ "$upload_enabled" == "enabled" && "$upload_active" == "active" ]]; then
echo "✅ [APROVADO]: systemd-journal-upload está habilitado e ativo"
else
echo "⚠️[REPROVADO]: systemd-journal-upload NÃO está habilitado ou ativo"
echo "Status: enabled=$upload_enabled, active=$upload_active"
fi

echo " 224 Ensure systemd-journal-remote service is not in use"

remote_status=$(systemctl is-enabled systemd-journal-remote.socket systemd-journal-remote.service 2>/dev/null | grep -P '^enabled')

if [[ -n "$remote_status" ]]; then
echo "⚠️[REPROVADO]: Serviços relacionados ao systemd-journal-remote estão habilitados:"
echo "$remote_status"
else
echo "✅ [APROVADO]: systemd-journal-remote NÃO está em uso (não habilitado)"
fi