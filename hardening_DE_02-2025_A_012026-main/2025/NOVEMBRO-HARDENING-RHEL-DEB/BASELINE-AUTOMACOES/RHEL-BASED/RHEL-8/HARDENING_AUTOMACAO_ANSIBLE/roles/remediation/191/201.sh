#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
echo "[201 - 202] Configurar ambiente padrão do usuário"

# --- [201] Configurar TMOUT ---
echo -e "\n[201] Garantir TMOUT <= 900 com readonly e export"
TMOUT_VALUE=900
TMOUT_FILE="/etc/profile.d/99-hardening-tmout.sh"

if [[ -f "$TMOUT_FILE" ]]; then
    if grep -q "TMOUT=$TMOUT_VALUE" "$TMOUT_FILE"; then
        echo "✅ $TMOUT_FILE já está configurado para TMOUT=$TMOUT_VALUE"
    else
        cp -p "$TMOUT_FILE" "$TMOUT_FILE.bak_${TS}"
        cat > "$TMOUT_FILE" <<EOF
# Hardening CIS 201 - shell timeout
if [ -z "\${TMOUT:-}" ]; then
    TMOUT=$TMOUT_VALUE
    readonly TMOUT
    export TMOUT
fi
EOF
        echo "⚠️ Ajustado TMOUT em $TMOUT_FILE"
    fi
else
    cat > "$TMOUT_FILE" <<EOF
# Hardening CIS 201 - shell timeout
if [ -z "\${TMOUT:-}" ]; then
    TMOUT=$TMOUT_VALUE
    readonly TMOUT
    export TMOUT
fi
EOF
    echo "⚠️ Criado $TMOUT_FILE com TMOUT=$TMOUT_VALUE"
fi

# --- [202] Configurar umask ---
echo -e "\n[202] Garantir umask 027 ou mais restritivo"
UMASK_VALUE="027"
UMASK_FILE="/etc/profile.d/99-hardening-umask.sh"

if [[ -f "$UMASK_FILE" ]]; then
    if grep -q "umask $UMASK_VALUE" "$UMASK_FILE"; then
        echo "✅ $UMASK_FILE já possui umask $UMASK_VALUE"
    else
        cp -p "$UMASK_FILE" "$UMASK_FILE.bak_${TS}"
        echo "umask $UMASK_VALUE" > "$UMASK_FILE"
        echo "⚠️ Ajustado umask em $UMASK_FILE"
    fi
else
    echo "umask $UMASK_VALUE" > "$UMASK_FILE"
    echo "⚠️ Criado $UMASK_FILE com umask $UMASK_VALUE"
fi
exit 0