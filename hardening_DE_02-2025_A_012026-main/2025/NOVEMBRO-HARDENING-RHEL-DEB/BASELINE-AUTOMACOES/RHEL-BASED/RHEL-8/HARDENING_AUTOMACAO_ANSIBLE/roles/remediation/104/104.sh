#!/usr/bin/env bash
echo "[104 - 110] Remediação genérica - Interfaces, Bluetooth e Módulos de Kernel"

# 104 - IPv6 (apenas orientação)
echo "[104] IPv6 detectado — nenhuma ação automática aplicada."
echo "    → Para desabilitar, avalie adicionar:"
echo "      net.ipv6.conf.all.disable_ipv6 = 1"
echo "      net.ipv6.conf.default.disable_ipv6 = 1"
echo "    Em /etc/sysctl.conf e executar: sysctl -p"

# 105 - Wireless interfaces
echo "[105] Interface wireless detectada (se presente)."
echo "    → Remova ou bloqueie drivers como iwlwifi, cfg80211, etc., se não utilizados."

# 106 - Bluetooth
echo "[106] Desabilitando serviço bluetooth (se instalado)"
if systemctl is-enabled bluetooth &>/dev/null; then
  systemctl disable bluetooth --now
  echo "✅ Serviço bluetooth desabilitado"
else
  echo "✅ Bluetooth já estava desabilitado"
fi

# 107–110 - Kernel modules
modulos=(dccp tipc rds sctp)
for mod in "${modulos[@]}"; do
  echo "[${mod^^}] Aplicando bloqueio via modprobe (install /bin/true)"
  conf="/etc/modprobe.d/${mod}.conf"
  if ! grep -q "^install $mod /bin/true" "$conf" 2>/dev/null; then
    echo "install $mod /bin/true" > "$conf"
    echo "✅ Módulo $mod bloqueado com sucesso"
  else
    echo "✅ Módulo $mod já estava bloqueado"
  fi
done


echo "[ICMP] Garantir DROP para timestamp-request e timestamp-reply"

# 1. Garantir tabela e chain
nft list table inet filter >/dev/null 2>&1 || nft add table inet filter
nft list chain inet filter input >/dev/null 2>&1 \
  || nft add chain inet filter input { type filter hook input priority 0\; }

# 2. Remover TODAS as instâncias antigas
nft --handle list chain inet filter input \
 | grep -Ei 'icmp[[:space:]]+type[[:space:]]+timestamp-(request|reply)' \
 | awk '{print $NF}' \
 | sed 's/;$//' \
 | xargs -r -I{} nft delete rule inet filter input handle {}

# 3. Criar regras definitivas
nft add rule inet filter input icmp type timestamp-request drop
nft add rule inet filter input icmp type timestamp-reply drop

# 4. Persistência
nft list ruleset >/etc/nftables.conf