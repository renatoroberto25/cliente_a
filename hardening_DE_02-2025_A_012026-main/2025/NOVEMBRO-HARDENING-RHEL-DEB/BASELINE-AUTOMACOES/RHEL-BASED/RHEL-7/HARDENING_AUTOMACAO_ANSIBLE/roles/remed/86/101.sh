#!/usr/bin/env bash
echo "[101–107] Firewalld e zonas"

# 101 - Ensure firewalld is installed
echo "[101] Verifique se o firewalld está instalado"
if rpm -q firewalld &>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Instale com: dnf install firewalld -y"
fi

# 102 - Ensure iptables-services not installed with firewalld
echo "[102] Verifique se iptables-services não está instalado junto com firewalld"
if rpm -q firewalld &>/dev/null && rpm -q iptables-services &>/dev/null; then
  echo "⚠️ REPROVADO - Remova iptables-services: dnf remove iptables-services -y"
else
  echo "✅ APROVADO"
fi

# 103 - Ensure nftables either not installed or masked with firewalld
echo "[103] Verifique se nftables não está ativo junto com firewalld"
if systemctl is-active nftables &>/dev/null; then
  echo "⚠️ REPROVADO - Desabilite com: systemctl disable --now nftables"
else
  echo "✅ APROVADO"
fi

# 104 - Ensure firewalld service enabled and running
echo "[104] Verifique se o serviço firewalld está habilitado e em execução"
if systemctl is-enabled firewalld &>/dev/null && systemctl is-active firewalld &>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Habilite e inicie com: systemctl enable --now firewalld"
fi

# 105 - Ensure firewalld default zone is set
echo "[105] Verifique se existe zona padrão configurada no firewalld"
if firewall-cmd --get-default-zone &>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Configure uma zona padrão: firewall-cmd --set-default-zone=public"
fi

# 106 - Ensure network interfaces are assigned to appropriate zone
echo "[106] Verifique se interfaces estão atribuídas a zonas"
if firewall-cmd --get-active-zones | grep -q "interfaces:"; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO - Associe interfaces: firewall-cmd --zone=public --add-interface=eth0 --permanent"
fi

# 107 - Ensure firewalld drops unnecessary services and ports
echo "[107] Verifique se o firewalld possui apenas serviços e portas necessárias"
if firewall-cmd --list-all | grep -E "services:|ports:" | grep -vqE 'services:\s*(ssh|dhcpv6-client)?$'; then
  echo "⚠️ REPROVADO - Revise regras com: firewall-cmd --zone=public --remove-service=<serviço> --permanent"
else
  echo "✅ APROVADO"
fi