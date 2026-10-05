#!/usr/bin/env bash
echo -e "\n[87] Assinaturas de pacotes habilitadas"
(grep -Eq '^gpgcheck\s*=\s*1' /etc/yum.conf /etc/yum.repos.d/*.repo 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

#echo -e "\n[88] Patches de segurança aplicados"
#(dnf check-update --security &>/dev/null && echo "⚠️ REPROVADO (atualizações pendentes)" || echo "✅ APROVADO")