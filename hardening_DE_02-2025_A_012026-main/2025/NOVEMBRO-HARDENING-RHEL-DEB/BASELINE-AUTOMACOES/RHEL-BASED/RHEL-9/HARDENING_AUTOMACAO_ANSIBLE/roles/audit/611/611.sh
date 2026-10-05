#!/usr/bin/env bash
echo -e "\n 214 Ensure AIDE is installed"

# Verificar se o pacote AIDE está instalado
if rpm -q aide &>/dev/null; then
echo "✅ [APROVADO]: AIDE está instalado."
else
echo "⚠️[REPROVADO]: Pacote AIDE não está instalado."
fi

echo -e "\n 215 Ensure filesystem integrity is regularly checked"
# Otimizando e evitando múltiplas chamadas ao systemctl.
aidecheck_service_enabled=$(systemctl is-enabled aidecheck.service 2>/dev/null)
aidecheck_timer_enabled=$(systemctl is-enabled aidecheck.timer 2>/dev/null)
aidecheck_timer_active=$(systemctl is-active aidecheck.timer 2>/dev/null)

[[ "$aidecheck_service_enabled" == "enabled" ]] && \
echo "✅ [APROVADO]: aidecheck.service está habilitado." || \
echo "⚠️[REPROVADO]: aidecheck.service NÃO está habilitado."

[[ "$aidecheck_timer_enabled" == "enabled" ]] && \
echo "✅ [APROVADO]: aidecheck.timer está habilitado." || \
echo "⚠️[REPROVADO]: aidecheck.timer NÃO está habilitado - ou não existe, criar manualmente."

[[ "$aidecheck_timer_active" == "active" ]] && \
echo "✅ [APROVADO]: aidecheck.timer está ativo (em execução)." || \
echo "⚠️[REPROVADO]: aidecheck.timer NÃO está ativo - ou não existe, criar manualmente."