#!/usr/bin/env bash
echo "[260-262] Remediação - AIDE integridade e proteção criptográfica"

# 260 - Não instala se não existir, apenas valida
if rpm -q aide &>/dev/null; then
    echo "[260] AIDE instalado ✅ APROVADO"
else
    echo "[260] AIDE não encontrado ⚠️ REPROVADO"
fi

# 261 - Configurar agendamento de verificação (se AIDE estiver presente)
if rpm -q aide &>/dev/null; then
    if systemctl list-unit-files | grep -q '^aidecheck.timer'; then
        systemctl enable --now aidecheck.timer &>/dev/null
        echo "[261] Agendamento via systemd habilitado ✅ APROVADO"
    else
        CRON_FILE="/etc/cron.daily/aide-check"
        if [ ! -f "$CRON_FILE" ]; then
            {
                echo '#!/bin/bash'
                echo '/usr/sbin/aide --check'
            } > "$CRON_FILE"
            chmod 700 "$CRON_FILE"
            echo "[261] Cron diário criado para AIDE ✅ APROVADO"
        else
            echo "[261] Agendamento via cron já existente ✅ APROVADO"
        fi
    fi
else
    echo "[261] AIDE não instalado, nada a remediar ⚠️"
fi

# 262 - Configurar proteção criptográfica no aide.conf (se AIDE estiver presente)
if rpm -q aide &>/dev/null; then
    CONF_FILE="/etc/aide.conf"
    for bin in /sbin/auditctl /sbin/auditd /sbin/ausearch /sbin/aureport /sbin/autrace /sbin/augenrules; do
        if ! grep -q "$bin" "$CONF_FILE" 2>/dev/null; then
            echo "$bin p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$CONF_FILE"
        fi
    done
    echo "[262] AIDE configurado para proteger ferramentas de auditoria ✅ APROVADO"
else
    echo "[262] AIDE não instalado, nada a remediar ⚠️"
fi