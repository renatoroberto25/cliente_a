#!/usr/bin/env bash
echo "[51-53] Auditorias complementares SELINUX: Serviços confinados, mctrans e setroubleshoot"

echo  -e "[51] Verificar se há serviços SELinux não confinados (unconfined)"
ps -eZ | grep -q 'unconfined_service_t' && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[52] Verificar se o serviço mcstrans está desabilitado"
systemctl is-enabled mcstrans.service &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[53] Verificar se o pacote setroubleshoot está instalado"
rpm -q setroubleshoot &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"