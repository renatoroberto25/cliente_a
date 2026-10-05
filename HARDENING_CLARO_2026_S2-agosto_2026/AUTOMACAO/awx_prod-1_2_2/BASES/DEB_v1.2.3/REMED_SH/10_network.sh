#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

network_control() { local id="$1" name="$2" pair key value; case "$id" in 81) pair='net.ipv4.conf.all.send_redirects net.ipv4.conf.default.send_redirects'; value=0;; 82) pair='net.ipv4.conf.all.accept_source_route net.ipv4.conf.default.accept_source_route net.ipv6.conf.all.accept_source_route net.ipv6.conf.default.accept_source_route'; value=0;; 84) pair='net.ipv4.conf.all.rp_filter net.ipv4.conf.default.rp_filter'; value=1;; esac; echo "[$id] $name"; for key in $pair; do [[ -e "/proc/sys/${key//./\/}" ]] || continue; backup_sysctl "$key"; set_kv /etc/sysctl.d/99-hitss-hardening.conf "$key" "$value"; set_kv /etc/sysctl.conf "$key" "$value"; sysctl -w "$key=$value" >/dev/null 2>&1 || { echo "WARN: $key"; return; }; done; echo 'OK: parametros aplicados'; }
icmp_redirects_active() { local id="$1" name="$2" family path iface key file=/etc/sysctl.d/99-hitss-hardening.conf ipv4_default ipv6_default; echo "[$id] $name"; ipv4_default="$(sysctl -n net.ipv4.conf.default.accept_redirects 2>/dev/null || echo NA)"; ipv6_default="$(sysctl -n net.ipv6.conf.default.accept_redirects 2>/dev/null || echo NA)"; for family in ipv4 ipv6; do key="net.$family.conf.all.accept_redirects"; [[ -e "/proc/sys/${key//./\/}" ]] || continue; backup_sysctl "$key"; set_kv "$file" "$key" 0; set_kv /etc/sysctl.conf "$key" 0; sysctl -w "$key=0" >/dev/null 2>&1 || { echo "WARN: $key"; return; }; done; for path in /sys/class/net/*; do [[ -e "$path" ]] || continue; iface=${path##*/}; [[ "$iface" == lo ]] && continue; [[ $(<"$path/operstate") == up ]] || continue; for family in ipv4 ipv6; do key="net.$family.conf.$iface.accept_redirects"; [[ -e "/proc/sys/${key//./\/}" ]] || continue; backup_sysctl "$key"; set_kv "$file" "$key" 0; set_kv /etc/sysctl.conf "$key" 0; sysctl -w "$key=0" >/dev/null 2>&1 || { echo "WARN: $key"; return; }; done; done; echo "INFO: defaults mantidos para revisao: ipv4=$ipv4_default ipv6=$ipv6_default"; echo 'OK: redirects bloqueados em all e nas interfaces ativas'; }
disable_ipv6() { local id="$1" name="$2"; set_sysctl "$id" "$name" net.ipv6.conf.all.disable_ipv6 1; backup_sysctl net.ipv6.conf.default.disable_ipv6; set_kv /etc/sysctl.d/99-hitss-hardening.conf net.ipv6.conf.default.disable_ipv6 1; set_kv /etc/sysctl.conf net.ipv6.conf.default.disable_ipv6 1; sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true; }

network_control 81 'Redirects desabilitados'
network_control 82 'Source-route bloqueado'
icmp_redirects_active 83 'ICMP redirects controlados nas interfaces ativas'
network_control 84 'Reverse path filtering habilitado'
set_sysctl 85 'Broadcast ICMP ignorado' net.ipv4.icmp_echo_ignore_broadcasts 1
set_sysctl 86 'ICMP bogus responses ignorado' net.ipv4.icmp_ignore_bogus_error_responses 1
set_sysctl 87 'TCP syncookies habilitado' net.ipv4.tcp_syncookies 1
disable_ipv6 88 'IPv6 desabilitado'
