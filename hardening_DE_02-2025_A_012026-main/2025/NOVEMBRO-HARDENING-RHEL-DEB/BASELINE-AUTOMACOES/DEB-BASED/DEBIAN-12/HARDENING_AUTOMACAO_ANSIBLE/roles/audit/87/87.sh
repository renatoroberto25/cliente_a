#!/usr/bin/env bash

echo -e "\n[87] Verifique se o cliente NIS não está instalado"
( dpkg-query -W -f='${Status}\n' nis 2>/dev/null | grep -q 'install ok installed' ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[88] Verifique se o cliente rsh não está instalado"
( dpkg-query -W -f='${Status}\n' rsh-client 2>/dev/null | grep -q 'install ok installed' ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[89] Verifique se o cliente talk não está instalado"
( dpkg-query -W -f='${Status}\n' talk 2>/dev/null | grep -q 'install ok installed' ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[90] Verifique se o cliente telnet não está instalado"
( dpkg-query -W -f='${Status}\n' telnet 2>/dev/null | grep -q 'install ok installed' || \
  dpkg-query -W -f='${Status}\n' inetutils-telnet 2>/dev/null | grep -q 'install ok installed' ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[91] Verifique se o cliente ldap-utils não está instalado"
( dpkg-query -W -f='${Status}\n' ldap-utils 2>/dev/null | grep -q 'install ok installed' ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[92] Verifique se os clientes ftp/tnftp não estão instalados"
( dpkg-query -W -f='${Status}\n' ftp 2>/dev/null | grep -q 'install ok installed' || \
  dpkg-query -W -f='${Status}\n' tnftp 2>/dev/null | grep -q 'install ok installed' ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"
