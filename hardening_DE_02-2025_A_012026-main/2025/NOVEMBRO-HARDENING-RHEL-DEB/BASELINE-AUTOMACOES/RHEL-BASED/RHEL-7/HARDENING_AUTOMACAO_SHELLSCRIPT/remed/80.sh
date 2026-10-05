#!/usr/bin/env bash
# [80–84] Remediação HITSS - Serviços e pacotes (Servidores baseados em RHEL 7)
set -euo pipefail

echo -e "\n[80] Remover NIS Client se instalado"
rpm -q ypbind &>/dev/null && yum remove -y ypbind || echo "✅ NIS Client não instalado"

echo -e "\n[81] Remover rsh client se instalado"
rpm -q rsh &>/dev/null && yum remove -y rsh || echo "✅ rsh client não instalado"

echo -e "\n[82] Remover talk client se instalado"
rpm -q talk &>/dev/null && yum remove -y talk || echo "✅ talk client não instalado"

echo -e "\n[83] Remover telnet client se instalado"
rpm -q telnet &>/dev/null && yum remove -y telnet || echo "✅ telnet client não instalado"

echo -e "\n[84] Remover LDAP client se instalado"
rpm -q openldap-clients &>/dev/null && yum remove -y openldap-clients || echo "✅ LDAP client não instalado"

echo "[85] Verificar serviços não essenciais ativos"

tmpfile="/tmp/nonessential_services_$$.log"
lsof -i -P -n | grep -v "(ESTABLISHED)" | grep -E "LISTEN|UDP" > "$tmpfile" || true

if [ -s "$tmpfile" ]; then
  echo "⚠️ Foram encontrados serviços escutando portas no sistema:"
  cat "$tmpfile"
  echo
  echo "[ORIENTAÇÃO]"
  echo "1. Analise se cada serviço listado é realmente necessário neste host."
  echo "2. Se NÃO for essencial, desinstale o pacote com:"
  echo "     yum remove <nome_do_pacote>"
  echo "3. Se o serviço for necessário mas não deve iniciar automaticamente:"
  echo "     systemctl stop <serviço>"
  echo "     systemctl mask <serviço>"
  echo
  echo "Resultado salvo em: $tmpfile"
else
  echo "✅ Nenhum serviço desnecessário em escuta identificado."
fi