#!/usr/bin/env bash
echo "217 Ensure journald service is enabled and active"

# Verificar se o systemd-journald está com o status 'static'
is_enabled=$(systemctl is-enabled systemd-journald.service 2>/dev/null)
if [[ "$is_enabled" == "static" ]]; then
echo "✅ [APROVADO]: systemd-journald está com status 'static' (esperado)."
else
echo "⚠️ [REPROVADO]: systemd-journald não está com status 'static'. Status atual: $is_enabled"
fi

# Verificar se o systemd-journald está ativo
is_active=$(systemctl is-active systemd-journald.service 2>/dev/null)
if [[ "$is_active" == "active" ]]; then
echo "✅ [APROVADO]: systemd-journald está ativo."
else
echo "⚠️ [REPROVADO]: systemd-journald não está ativo. Status atual: $is_active"
fi