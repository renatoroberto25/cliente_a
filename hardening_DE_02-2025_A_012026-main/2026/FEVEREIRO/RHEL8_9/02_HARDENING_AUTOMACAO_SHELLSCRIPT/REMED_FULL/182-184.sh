#!/usr/bin/env bash
echo -E "\n[182-184] Remediação - AIDE e proteção dos binários de auditoria"

TS="$(date +%Y%m%d-%H%M%S)"
log(){ echo "✔ $1"; }
warn(){ echo "⚠️ $1"; }
fail(){ echo "✖ $1"; }

# -----------------------------------------
# 182 — AIDE instalado e inicializado
# -----------------------------------------
if rpm -q aide &>/dev/null; then
    echo "[182] AIDE instalado"
else
    warn "[182] AIDE não encontrado"
fi

# -----------------------------------------
# 183 — Agendamento de verificação do AIDE
# -----------------------------------------
if rpm -q aide &>/dev/null; then
    # Preferência: systemd timer
    if systemctl list-unit-files | grep -q '^aidecheck.timer'; then
        systemctl enable --now aidecheck.timer &>/dev/null
        log "[183] Timer systemd habilitado"
    else
        CRON="/etc/cron.daily/aide-check"
        if [ ! -f "$CRON" ]; then
            {
                echo '#!/bin/bash'
                echo '/usr/sbin/aide --check'
            } > "$CRON"
            chmod 700 "$CRON"
            log "[183] Cron diário criado"
        else
            log "[183] Cron diário já existente"
        fi
    fi
else
    warn "[183] AIDE não instalado — ignorado"
fi

# -----------------------------------------
# 184 — Proteger ferramentas de auditoria via AIDE
# -----------------------------------------
if rpm -q aide &>/dev/null; then
    CONF="/etc/aide.conf"
    for bin in /sbin/auditctl /sbin/auditd /sbin/ausearch /sbin/aureport /sbin/autrace /sbin/augenrules; do
        if ! grep -q "$bin" "$CONF" 2>/dev/null; then
            echo "$bin p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$CONF"
        fi
    done
    log "[184] Proteção de binários configurada"
else
    warn "[184] AIDE não instalado — ignorado"
fi
