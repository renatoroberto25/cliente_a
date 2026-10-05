#!/usr/bin/env bash
echo "[104 - 110] Recursos de rede e módulos de kernel"

# 104 - IPv6 status 
echo "[104] Verificação - IPv6 habilitado em interfaces"
ip a | grep -i inet6 && echo "⚠️ IPv6 detectado — avalie necessidade" || echo "✅ Nenhuma interface IPv6 ativa"
echo "Consulte também sysctl: net.ipv6.conf.all.disable_ipv6"

# 105 - Wireless interfaces
echo "[105] Verificando interfaces wireless"
nmcli dev status | grep -iq wifi && echo "⚠️ Interface Wi-Fi detectada" || echo "✅ Nenhuma interface Wi-Fi ativa"

# 106 - Serviço bluetooth
echo "[106] Verificando se bluetooth.service está desabilitado"
systemctl is-enabled bluetooth &>/dev/null && echo "⚠️ REPROVADO - bluetooth habilitado" || echo "✅ APROVADO"

# 107–110 - Módulos de kernel: dccp, tipc, rds, sctp
for mod in dccp tipc rds sctp; do
  echo "[${mod^^}] Verificando se o módulo $mod está bloqueado"
  if modprobe -n -v $mod 2>/dev/null | grep -q 'install /bin/true'; then
    echo "✅ $mod bloqueado"
  else
    echo "⚠️ $mod disponível ou não bloqueado"
  fi
done