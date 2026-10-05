#!/usr/bin/env bash
# orientacao_time_sync.sh
# Audita e orienta correção dos controles 93–98 (Debian 12)

ok(){ echo "✅ $1"; }
warn(){ echo "⚠️ $1"; }
hint(){ echo "   → $1"; }

echo -e "\n[93] Apenas um daemon de tempo ativo"
if (systemctl is-active --quiet systemd-timesyncd.service && ! systemctl is-active --quiet chrony.service) ||
   (! systemctl is-active --quiet systemd-timesyncd.service && systemctl is-active --quiet chrony.service); then
   ok "Somente um daemon está ativo"
else
   warn "Conflito (nenhum ou ambos ativos)"
   hint "Escolha UM: 'systemd-timesyncd' ou 'chrony'"
   hint "Ex.: systemctl disable --now chrony.service && systemctl enable --now systemd-timesyncd.service"
fi

echo -e "\n[94] systemd-timesyncd com servidores NTP"
if systemctl is-active --quiet systemd-timesyncd.service; then
   if grep -Piq '^\s*NTP\s*=' /etc/systemd/timesyncd.conf 2>/dev/null; then
      ok "timesyncd possui NTP configurado"
   else
      warn "timesyncd sem NTP configurado"
      hint "Edite /etc/systemd/timesyncd.conf e adicione:"
      hint "     [Time]\n     NTP=pool.ntp.org"
      hint "Depois: systemctl restart systemd-timesyncd"
   fi
else
   ok "timesyncd não está em uso"
fi

echo -e "\n[95] systemd-timesyncd habilitado e ativo"
if systemctl is-enabled --quiet systemd-timesyncd.service && systemctl is-active --quiet systemd-timesyncd.service; then
   ok "timesyncd habilitado e rodando"
else
   if systemctl is-active --quiet chrony.service; then
      ok "chrony em uso"
   else
      warn "timesyncd não habilitado/ativo"
      hint "systemctl enable --now systemd-timesyncd"
   fi
fi

echo -e "\n[96] chrony com servidores NTP"
if systemctl is-active --quiet chrony.service; then
   if grep -Piq '^\s*(server|pool)\s+' /etc/chrony/chrony.conf 2>/dev/null; then
      ok "chrony possui NTP configurado"
   else
      warn "chrony sem NTP configurado"
      hint "Edite /etc/chrony/chrony.conf e adicione:"
      hint "     server pool.ntp.org iburst"
      hint "Depois: systemctl restart chrony"
   fi
else
   ok "chrony não está em uso"
fi

echo -e "\n[97] chronyd rodando como usuário _chrony"
if pgrep -u _chrony -x chronyd >/dev/null 2>&1; then
   ok "chronyd roda como _chrony"
else
   warn "chronyd não roda como _chrony"
   hint "Edite override do systemd: /etc/systemd/system/chrony.service.d/override.conf"
   hint "Adicione: User=_chrony"
   hint "Depois: systemctl daemon-reload && systemctl restart chrony"
fi

echo -e "\n[98] chrony habilitado e ativo"
if systemctl is-enabled --quiet chrony.service 2>/dev/null && systemctl is-active --quiet chrony.service 2>/dev/null; then
   ok "chrony habilitado e rodando"
else
   if systemctl is-active --quiet systemd-timesyncd.service; then
      ok "timesyncd em uso"
   else
      warn "chrony não habilitado/ativo"
      hint "systemctl enable --now chrony"
   fi
fi