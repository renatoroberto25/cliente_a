#!/usr/bin/env bash
echo "[108–133] nftables, iptables e ip6tables"

# 108
echo -e "\n [108] Verifique se o nftables está instalado "; rpm -q nftables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Instale com: dnf install nftables -y"

# 109
echo -e "\n [109] Verifique se o firewalld está desabilitado ao usar nftables "; command -v firewalld &>/dev/null && systemctl is-active firewalld &>/dev/null && echo "⚠️ REPROVADO" ; echo -e "\n -Desabilite: systemctl disable --now firewalld" || echo "✅ APROVADO"

# 110
echo -e "\n [110] Verifique se iptables-services não está instalado junto com nftables "; rpm -q nftables &>/dev/null && rpm -q iptables-services &>/dev/null && echo "⚠️ REPROVADO" ; echo -e "\n -Remova: dnf remove iptables-services -y" || echo "✅ APROVADO"

# 111
echo -e "\n [111] Verifique se iptables está limpo quando nftables é utilizado "; command -v iptables &>/dev/null && iptables -L 2>/dev/null | grep -qvE "Chain|target|policy" && echo "⚠️ REPROVADO" ; echo -e "\n -Limpe: iptables -F" || echo "✅ APROVADO"

# 112
echo -e "\n [112] Verifique se há tabela configurada no nftables "; command -v nft &>/dev/null && nft list tables 2>/dev/null | grep -q . && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Crie: nft add table inet filter"

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


# 113
echo -e "\n [113] Verifique se as cadeias base do nftables existem "; command -v nft &>/dev/null && nft list chains 2>/dev/null | grep -Eq "hook input|hook forward|hook output" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Crie cadeias base"

# 114
echo -e "\n [114] Verifique se o tráfego de loopback está permitido no nftables "; command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -Eq "iif lo accept" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Adicione: nft add rule inet filter input iif lo accept"

# 115
echo -e "\n [115] Verifique se conexões estabelecidas e saídas estão permitidas "; command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -Eq "ct state (related,established|established,related)" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Adicione regra de conexões estabelecidas"

# 116
echo -e "\n [116] Verifique se a política padrão do nftables é de negação "; command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -Eq "policy drop" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Configure política padrão drop"

# 117
echo -e "\n [117] Verifique se o serviço nftables está habilitado "; systemctl is-enabled nftables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Habilite: systemctl enable --now nftables"

# 118
echo -e "\n [118] Verifique se as regras do nftables estão persistentes "; [ -f /etc/sysconfig/nftables.conf ] && grep -q "include" /etc/sysconfig/nftables.conf && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Salve regras: nft list ruleset > /etc/sysconfig/nftables.conf"

# 119
echo -e "\n [119] Verifique se iptables está instalado "; rpm -q iptables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Instale: dnf install iptables -y"

# 120
echo -e "\n [120] Verifique se nftables não está ativo junto com iptables "; systemctl is-active nftables &>/dev/null && echo "⚠️ REPROVADO" ; echo -e "\n -Desative nftables: systemctl disable --now nftables" || echo "✅ APROVADO"

# 121
echo -e "\n [121] "; systemctl is-active firewalld &>/dev/null && echo "⚠️ REPROVADO" ; echo -e "\n -Desative firewalld: systemctl disable --now firewalld" || echo "✅ APROVADO"

# 122
echo -e "\n [122] Verifique se iptables permite tráfego loopback "; command -v iptables &>/dev/null && iptables -L INPUT -v -n 2>/dev/null | grep -q "lo" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Adicione: iptables -A INPUT -i lo -j ACCEPT"

# 123
echo -e "\n [123] Verifique se iptables permite conexões estabelecidas e saídas "; command -v iptables &>/dev/null && iptables -L -v -n 2>/dev/null | grep -Eq "ESTABLISHED,RELATED" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Adicione regra de conexões estabelecidas"

# 124
echo -e "\n [124] Verifique se iptables possui regras para portas abertas "; command -v iptables &>/dev/null && ss -tuln | awk 'NR>1 {print $5}' | cut -d: -f2 | sort -u | while read port; do iptables -L INPUT -v -n 2>/dev/null | grep -q "$port" || { echo "⚠️ Porta $port sem regra - iptables -A INPUT -p tcp --dport $port -j ACCEPT "; exit 1; }; done && echo "✅ APROVADO"

# 125
echo -e "\n [125] Verifique se política padrão do iptables é de negação "; command -v iptables &>/dev/null && iptables -L INPUT 2>/dev/null | grep -q "policy DROP" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Configure: iptables -P INPUT DROP"

# 126
echo -e "\n [126] Verifique se as regras do iptables estão salvas "; [ -s /etc/sysconfig/iptables ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Salve regras: service iptables save"

# 127
echo -e "\n [127] Verifique se o iptables está habilitado e em execução "; systemctl is-enabled iptables &>/dev/null && systemctl is-active iptables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Ative: systemctl enable --now iptables"

# 128
echo -e "\n [128] Verifique se ip6tables permite tráfego loopback "; command -v ip6tables &>/dev/null && ip6tables -L INPUT -v -n 2>/dev/null | grep -q "lo" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Adicione: ip6tables -A INPUT -i lo -j ACCEPT"

# 129
echo -e "\n [129] Verifique se ip6tables permite conexões estabelecidas e saídas "; command -v ip6tables &>/dev/null && ip6tables -L -v -n 2>/dev/null | grep -Eq "ESTABLISHED,RELATED" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Adicione regra de conexões estabelecidas"

# 130
echo -e "\n [130] Verifique se ip6tables possui regras para portas IPv6 abertas "; command -v ip6tables &>/dev/null && ss -tuln | grep -E "::" | awk '{print $5}' | cut -d: -f2 | sort -u | while read port; do ip6tables -L INPUT -v -n 2>/dev/null | grep -q "$port" || { echo "⚠️ Porta IPv6 $port sem regra - ip6tables -A INPUT -p tcp --dport $port -j ACCEPT "; exit 1; }; done && echo "✅ APROVADO"

# 131
echo -e "\n [131] Verifique se política padrão do ip6tables é de negação "; command -v ip6tables &>/dev/null && ip6tables -L INPUT 2>/dev/null | grep -q "policy DROP" && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Configure: ip6tables -P INPUT DROP"

# 132
echo -e "\n [132] Verifique se as regras do ip6tables estão salvas "; [ -s /etc/sysconfig/ip6tables ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Salve regras: service ip6tables save"

# 133
echo -e "\n [133] Verifique se o ip6tables está habilitado e em execução "; systemctl is-enabled ip6tables &>/dev/null && systemctl is-active ip6tables &>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ; echo -e "\n -Ative: systemctl enable --now ip6tables"

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