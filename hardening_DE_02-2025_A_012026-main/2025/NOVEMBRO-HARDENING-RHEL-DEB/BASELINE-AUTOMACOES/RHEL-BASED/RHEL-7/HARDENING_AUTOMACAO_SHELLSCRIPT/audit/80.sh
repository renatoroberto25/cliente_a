#!/usr/bin/env bash
# [80–79] Auditoria HITSS - Serviços e pacotes (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[80] Verifique se o NIS Client não está instalado"
rpm -q ypbind &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[81] Verifique se o rsh client não está instalado"
rpm -q rsh &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[82] Verifique se o talk client não está instalado"
rpm -q talk &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[83] Verifique se o telnet client não está instalado"
rpm -q telnet &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[84] Verifique se o LDAP client não está instalado"
rpm -q openldap-clients &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[85] Verifique se existem serviços não essenciais em execução"
lsof -i -P -n | grep -v "(ESTABLISHED)" | grep -E "LISTEN|UDP" && echo "⚠️ REPROVADO" || echo "✅ APROVADO"