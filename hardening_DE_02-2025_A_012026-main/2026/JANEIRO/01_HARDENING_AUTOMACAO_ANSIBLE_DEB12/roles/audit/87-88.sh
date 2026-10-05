#!/usr/bin/env bash

echo -e "\n[87] Assinaturas de pacotes habilitadas"
(grep -Eq '^deb.*signed-by' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO")


echo -e "\n[88] Patches de segurança aplicados"
(apt-get -s upgrade &>/dev/null && echo "⚠️ REPROVADO (atualizações pendentes)" || echo "✅ APROVADO")

#MUDAR NO TENABLE AUDIT