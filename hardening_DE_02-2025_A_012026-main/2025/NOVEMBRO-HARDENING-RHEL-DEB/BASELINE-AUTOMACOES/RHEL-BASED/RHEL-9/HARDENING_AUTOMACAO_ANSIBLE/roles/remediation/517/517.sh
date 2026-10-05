#!/usr/bin/env bash

echo " [149 a 151] Orientações para configuração manual conforme política local"

# 149 – SSHD: Restrição de acesso por usuários/grupos
echo "➡️  [149] Configure AllowUsers, AllowGroups, DenyUsers ou DenyGroups no sshd_config"
echo "     - Defina somente os usuários/grupos autorizados a se conectar via SSH"
echo "     - Exemplo:"
echo "         AllowUsers admin1 devops"
echo "         AllowGroups sshaccess"
echo "     - Evite acesso desnecessário com DenyUsers e DenyGroups se apropriado"

# 150 – Banner de aviso legal
echo -e "\n➡️  [150] Configure um banner legal em /etc/issue.net"
echo "     - Exemplo básico:"
echo '         Authorized access only. All activity may be monitored and reported.'
echo "     - Evite informações sobre o sistema operacional, hostname ou versão"
echo "     - Aplique em /etc/ssh/sshd_config:"
echo "         Banner /etc/issue.net"

# 151 – ClientAliveInterval / ClientAliveCountMax
echo -e "\n➡️  [151] Ajuste ClientAliveInterval e ClientAliveCountMax para limitar sessões inativas"
echo "     - Exemplo recomendado:"
echo "         ClientAliveInterval 15"
echo "         ClientAliveCountMax 3"
echo "     - Isso finaliza sessões inativas após 45 segundos"

echo -e "\n⚠️  Estes ajustes devem ser definidos conforme política local e aplicados manualmente em:"
echo "     /etc/ssh/sshd_config e /etc/ssh/sshd_config.d/*.conf"

echo -e "\n✅ Remediação finalizada"
exit 0