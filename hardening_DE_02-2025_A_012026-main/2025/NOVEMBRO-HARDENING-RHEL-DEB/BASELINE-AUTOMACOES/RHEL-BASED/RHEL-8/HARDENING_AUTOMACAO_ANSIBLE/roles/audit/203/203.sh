#!/usr/bin/env bash
set -u
echo "[203 - 209] Remediação rsyslog"

# 203
echo -e "\n[203] Ensure rsyslog is installed"
rpm -q rsyslog &>/dev/null && echo "✅ APROVADO"|| echo "⚠️ REPROVADO"

# 204
echo -e "\n[204] Ensure rsyslog service is enabled (Manual)"
systemctl is-enabled rsyslog &>/dev/null && echo "✅ APROVADO"|| echo "⚠️ REPROVADO"

# 205
echo -e "\n[205] Ensure journald is configured to send logs to rsyslog"
systemd-analyze cat-config systemd/journald.conf systemd/journald.conf.d/* 2>/dev/null \
  | grep -Eq '^ForwardToSyslog=yes' && echo "✅ APROVADO"|| echo "⚠️ REPROVADO"

# 206
echo -e "\n[206] Ensure rsyslog default file permissions are configured"
mode=$(grep -Eoi '^\s*(\$)?FileCreateMode\s*(=|)\s*"?0[0-7]{3}"?' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null \
       | grep -Eo '0[0-7]{3}' | head -n1 || true)
[[ -n "$mode" && $((8#$mode)) -le $((8#0640)) ]] && echo "✅ APROVADO"|| echo "⚠️ REPROVADO"

# 207 (manual → sempre ⚠️ REPROVADO até implementar)
echo -e "\n[207] Ensure logging is configured"
[[ -f /var/log/messages ]] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 208
echo -e "\n[208] Ensure rsyslog is configured to send logs to a remote log host"
grep -Eiq '^\s*[^#]*@[^@]' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 209
echo -e "\n[209] Ensure rsyslog is not configured to receive logs from a remote client"
if grep -Eiq '^\s*\$ModLoad\s+imtcp' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null \
   || grep -Eiq '^\s*\$InputTCPServerRun' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
    echo "⚠️ REPROVADO"
else
    echo "✅ APROVADO"
fi