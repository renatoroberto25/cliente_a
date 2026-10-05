#!/usr/bin/env bash
echo -e "\n[177] Verifique se o sudo está instalado"
command -v sudo >/dev/null 2>&1 && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[178] Verifique se o sudo está configurado para usar pty"
egrep -i '^\s*Defaults\s+.*use_pty' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[179] Verifique se existe log de comandos sudo"
egrep -i '^\s*Defaults\s+.*logfile=' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[180] Verifique se sudo exige senha para escalonamento de privilégios"
egrep -i '^\s*Defaults\s+.*!authenticate' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[181] Verifique se a re-autenticação do sudo não está desabilitada globalmente"
egrep -i '^\s*Defaults\s+.*timestamp_timeout=-1' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[182] Verifique se o timeout de autenticação do sudo está configurado"
egrep -i '^\s*Defaults\s+.*timestamp_timeout=' /etc/sudoers /etc/sudoers.d/* 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[183] Verifique se o acesso ao comando su está restrito"
grep -Eq '^\s*auth\s+required\s+pam_wheel.so.*group=sudo' /etc/pam.d/su && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#184 185 são core packages
echo -e "\n[186] Verifique se libpam-pwquality está instalado"
dpkg-query -s libpam-pwquality 2>/dev/null | grep -Eq '^Status: install ok installed' \
  && echo "✅ APROVADO" || echo "⚠️ REPROVADO"