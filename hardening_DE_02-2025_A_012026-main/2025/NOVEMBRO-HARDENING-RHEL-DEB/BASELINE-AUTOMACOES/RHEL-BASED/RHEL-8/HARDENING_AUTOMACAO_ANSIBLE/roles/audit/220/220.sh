#!/usr/bin/env bash
set -u
echo "[220 - 228] Configuração do Auditd e Logs"

# 220
echo -e "\n [220] Verifique se todos os arquivos de log possuem permissões adequadas"
if find /var/log -type f -printf "%p %m %u %g\n" 2>/dev/null | \
   awk '$2 > 640 && $2 != 664 {exit 1}'; then
   echo "✅ APROVADO"
else
   echo "⚠️ REPROVADO"
fi


# 221
echo -e "\n [221] Verifique se o pacote audit está instalado"
(rpm -q audit audit-libs &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 222
echo -e "\n [222] Verifique se audit=1 está configurado no GRUB"
grep -Pq '^\h*GRUB_CMDLINE_LINUX="([^#\n\r]+\h+)?audit=1\b' /etc/default/grub \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 223
echo -e "\n [223] Verifique se audit_backlog_limit está configurado no GRUB"
grep -Pq '^\h*GRUB_CMDLINE_LINUX="([^#\n\r]+\h+)?audit_backlog_limit=\d+\b' /etc/default/grub \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 224
echo -e "\n [224] Verifique se o serviço auditd está habilitado e ativo"
(systemctl is-enabled auditd 2>/dev/null | grep -q '^enabled' && \
 systemctl is-active auditd 2>/dev/null | grep -q '^active') \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 225
echo -e "\n [225] Verifique se max_log_file está configurado em auditd.conf"
grep -Pq '^\h*max_log_file\h*=\h*\d+\b' /etc/audit/auditd.conf \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 226
echo -e "\n [226] Verifique se os logs de auditoria não são excluídos automaticamente"
grep -Pq '^\h*max_log_file_action\h*=\h*(?!(rotate|ROTATE)\b)' /etc/audit/auditd.conf \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 227
echo -e "\n [227] Verifique se o sistema é desabilitado quando os logs enchem"
grep -Pq '^\h*disk_full_action\h*=\h*(halt|single)\b' /etc/audit/auditd.conf \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 228
echo -e "\n [228] Verifique se o sistema avisa quando os logs estão com pouco espaço"
grep -Pq '^\h*space_left_action\h*=\h*(email|exec|single|halt)\b' /etc/audit/auditd.conf \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"