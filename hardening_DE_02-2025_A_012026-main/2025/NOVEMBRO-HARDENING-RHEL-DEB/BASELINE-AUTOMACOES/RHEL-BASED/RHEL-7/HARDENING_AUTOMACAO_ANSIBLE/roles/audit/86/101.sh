#!/usr/bin/env bash
echo "[101–107] Verificações do Firewalld e configuração de zonas"

# 101 - Ensure firewalld is installed
echo "[101] Verifique se o firewalld está instalado"
rpm -q firewalld &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 102 - Ensure iptables-services not installed with firewalld
echo "[102] Verifique se iptables-services não está instalado junto com firewalld"
if rpm -q firewalld &>/dev/null && rpm -q iptables-services &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# 103 - Ensure nftables either not installed or masked with firewalld
echo "[103] Verifique se o nftables não está ativo junto com firewalld"
if systemctl is-active nftables &>/dev/null; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi

# 104 - Ensure firewalld service enabled and running
echo "[104] Verifique se o serviço firewalld está habilitado e em execução"
if systemctl is-enabled firewalld &>/dev/null && systemctl is-active firewalld &>/dev/null; then
  echo "✅ APROVADO"
else
  echo "⚠️ REPROVADO"
fi

# 105 - Ensure firewalld default zone is set
echo "[105] Verifique se existe zona padrão configurada no firewalld"
firewall-cmd --get-default-zone &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 106 - Ensure network interfaces are assigned to appropriate zone
echo "[106] Verifique se interfaces estão atribuídas a zonas no firewalld"
firewall-cmd --get-active-zones | grep -E "interfaces:" &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 107 - Ensure firewalld drops unnecessary services and ports
echo "[107] Verifique se o firewalld possui apenas serviços e portas necessárias"
if firewall-cmd --list-all | grep -E "services:|ports:" | grep -vqE 'services:\s*(ssh|dhcpv6-client)?$'; then
  echo "⚠️ REPROVADO"
else
  echo "✅ APROVADO"
fi