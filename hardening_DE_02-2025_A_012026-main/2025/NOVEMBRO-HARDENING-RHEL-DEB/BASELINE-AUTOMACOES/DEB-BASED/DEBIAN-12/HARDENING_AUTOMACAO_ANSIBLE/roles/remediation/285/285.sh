#!/usr/bin/env bash
echo "[285–286] Remediação - AIDE e verificação periódica"

# 285 – AIDE instalado
if ! dpkg -s aide 2>/dev/null | grep -q '^Status: install'; then
    echo "⚠️ REPROVADO (AIDE não instalado, instale com: apt install aide)"
else
    echo "✅ APROVADO (AIDE já instalado)"
fi

# 286 – filesystem integrity regularly checked
if systemctl list-unit-files | grep -q 'dailyaidecheck.timer'; then
    systemctl enable dailyaidecheck.timer >/dev/null 2>&1
    systemctl start dailyaidecheck.timer >/dev/null 2>&1
    (systemctl is-enabled dailyaidecheck.timer | grep -q enabled && \
     systemctl is-active dailyaidecheck.timer | grep -q active) && \
     echo "✅ APROVADO (timer habilitado e ativo)" || echo "⚠️ REPROVADO (falha ao ativar)"
else
    echo "⚠️ REPROVADO (dailyaidecheck.timer não existe neste sistema)"
fi