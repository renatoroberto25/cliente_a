#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 92–107 (Rede e Firewall – RHEL 7)"

SYSCTLFILE="/etc/sysctl.conf"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

set_sysctl_kv() {
  local key="$1" val="$2"

  if sysctl -n "$key" >/dev/null 2>&1; then
    # persistência (normaliza "key = val")
    if grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$SYSCTLFILE" 2>/dev/null; then
      sed -ri "s|^[[:space:]]*${key}[[:space:]]*=.*|${key} = ${val}|" "$SYSCTLFILE"
    else
      echo "${key} = ${val}" >> "$SYSCTLFILE"
    fi

    # runtime: aplica na key
    sysctl -w "${key}=${val}" >/dev/null 2>&1 || true

    # se for net.ipv4.conf.(all|default).<param>, aplica em TODAS as ifaces existentes
    if [[ "$key" =~ ^net\.ipv4\.conf\.(all|default)\.([a-zA-Z0-9_]+)$ ]]; then
      local param="${BASH_REMATCH[2]}"
      for f in /proc/sys/net/ipv4/conf/*/"$param"; do
        [ -w "$f" ] && echo "$val" > "$f" || true
      done
    fi

    echo " ${key} = ${val}"
  else
    echo " ${key} não suportado"
  fi
}

backup "$SYSCTLFILE"
touch "$SYSCTLFILE"

############################################
# 92–98 – SYSCTL REDE (all + default)
############################################
echo -e "\n[92–98] Hardening de rede via sysctl"

# 92
set_sysctl_kv "net.ipv4.conf.all.send_redirects" "0"
set_sysctl_kv "net.ipv4.conf.default.send_redirects" "0"

# 93
set_sysctl_kv "net.ipv4.conf.all.accept_source_route" "0"
set_sysctl_kv "net.ipv4.conf.default.accept_source_route" "0"

# 94
set_sysctl_kv "net.ipv4.conf.all.accept_redirects" "0"
set_sysctl_kv "net.ipv4.conf.default.accept_redirects" "0"

# 95
set_sysctl_kv "net.ipv4.conf.all.rp_filter" "1"
set_sysctl_kv "net.ipv4.conf.default.rp_filter" "1"

# 96
set_sysctl_kv "net.ipv4.icmp_echo_ignore_broadcasts" "1"

# 97
set_sysctl_kv "net.ipv4.icmp_ignore_bogus_error_responses" "1"

# 98
set_sysctl_kv "net.ipv4.tcp_syncookies" "1"

# efetivar
sysctl --system >/dev/null 2>&1 || true

############################################
# 104 – APENAS UMA SOLUÇÃO DE FIREWALL
############################################
echo -e "\n[104] Garantir apenas uma solução de firewall"

fw_active=0
ipt_active=0

systemctl is-active --quiet firewalld 2>/dev/null && fw_active=1 || true
systemctl is-active --quiet iptables 2>/dev/null && ipt_active=1 || true

if [ "$fw_active" -eq 1 ] && [ "$ipt_active" -eq 1 ]; then
  systemctl disable --now iptables >/dev/null 2>&1 || true
  echo " firewalld ativo, iptables desabilitado"
elif [ "$fw_active" -eq 1 ] && [ "$ipt_active" -eq 0 ]; then
  systemctl disable --now iptables >/dev/null 2>&1 || true
  echo " firewalld ativo, iptables já inativo"
elif [ "$fw_active" -eq 0 ] && [ "$ipt_active" -eq 1 ]; then
  systemctl disable --now firewalld >/dev/null 2>&1 || true
  echo " iptables ativo, firewalld desabilitado"
else
  if systemctl list-unit-files | grep -q '^firewalld\.service'; then
    systemctl enable --now firewalld >/dev/null 2>&1 || true
    systemctl disable --now iptables >/dev/null 2>&1 || true
    echo " firewalld habilitado como firewall padrão"
  elif systemctl list-unit-files | grep -q '^iptables\.service'; then
    systemctl enable --now iptables >/dev/null 2>&1 || true
    echo " iptables habilitado como firewall padrão"
  else
    echo " nenhuma solução de firewall detectada – ação manual necessária"
  fi
fi


############################################
# 100–101 – BLOQUEIO ICMP TIMESTAMP
############################################
echo -e "\n[100-101] ICMP timestamp drop"

if systemctl is-active --quiet firewalld 2>/dev/null; then

    firewall-cmd --permanent --add-icmp-block=timestamp-request >/dev/null 2>&1
    firewall-cmd --permanent --add-icmp-block=timestamp-reply >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1
    echo " firewalld ajustado"

elif command -v iptables >/dev/null 2>&1; then

    iptables -C INPUT -p icmp --icmp-type timestamp-request -j DROP 2>/dev/null || \
    iptables -A INPUT -p icmp --icmp-type timestamp-request -j DROP

    iptables -C INPUT -p icmp --icmp-type timestamp-reply -j DROP 2>/dev/null || \
    iptables -A INPUT -p icmp --icmp-type timestamp-reply -j DROP

    echo " iptables ajustado (runtime)"

else
    echo " Nenhum firewall detectado – ação necessária do cliente"
fi

############################################
# 102 – DESABILITAR WIFI / BLUETOOTH
############################################
echo -e "\n[102] Desabilitar interfaces wireless/bluetooth"

nmcli radio wifi off >/dev/null 2>&1 || true
nmcli radio bluetooth off >/dev/null 2>&1 || true

############################################
# 105 – LOOPBACK + ESTABLISHED
############################################
#echo -e "\n[105] Regras básicas firewall - SÓMENTE IPTABLES"
#if command -v iptables >/dev/null 2>&1; then
#  if ! iptables-save | grep -q -- "-i lo -j ACCEPT"; then
#    iptables -A INPUT -i lo -j ACCEPT
#  fi
#  if ! iptables-save | grep -q -- "ESTABLISHED,RELATED"; then
#    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#  fi
#fi


############################################
# 107 – PERSISTÊNCIA FIREWALL
############################################
echo -e "\n[107] Persistência firewall"

if systemctl is-enabled firewalld >/dev/null 2>&1; then
  systemctl enable firewalld >/dev/null 2>&1 || true
else
  if command -v iptables-save >/dev/null 2>&1; then
    iptables-save > /etc/sysconfig/iptables || true
  fi
  systemctl enable iptables >/dev/null 2>&1 || true
fi

echo -e "\n[OK] Bloco 92–107 aplicado"
