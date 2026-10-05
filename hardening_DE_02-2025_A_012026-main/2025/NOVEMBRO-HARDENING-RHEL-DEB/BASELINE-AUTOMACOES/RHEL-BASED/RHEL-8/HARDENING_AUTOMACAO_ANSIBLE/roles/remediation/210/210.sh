#!/usr/bin/env bash
set -u
TS=$(date +%F_%H%M%S)

echo "[210 - 219] Configuração journald"

# Função de backup e edição
backup_and_set() {
    local file="$1"
    local key="$2"
    local value="$3"
    [[ -f "$file" ]] && cp -p "$file" "$file.bak_$TS"
    mkdir -p "$(dirname "$file")"
    if grep -Eq "^[^#]*$key" "$file" 2>/dev/null; then
        sed -i "s|^\s*$key.*|$key=$value|" "$file"
    else
        echo "$key=$value" >> "$file"
    fi
}

# 210 e 211] Apenas recomendação
echo "⚠️ [[210 - 211] instalar/configurar systemd-journal-remote manualmente se aplicável."

# 212] habilitar se existir
if systemctl list-unit-files | grep -q systemd-journal-remote.socket; then
    systemctl enable systemd-journal-remote.socket
    systemctl start systemd-journal-remote.socket
    echo "✅ [212] systemd-journal-remote habilitado."
else
    echo "⚠️ [212] socket não encontrado, nada feito."
fi

# 213] remover recebimento remoto
if [[ -f /etc/systemd/journal-remote.conf ]]; then
    cp -p /etc/systemd/journal-remote.conf "/etc/systemd/journal-remote.conf.bak_$TS"
    sed -i '/^[^#]*ListenStream/s/^/#/' /etc/systemd/journal-remote.conf
    echo "✅ [213] recebimento remoto desabilitado."
else
    echo "✅ [213] nenhum arquivo de configuração remoto encontrado."
fi

# 214] habilitar journald
systemctl enable systemd-journald && echo "✅ [214] journald habilitado."

# 215] compressão
backup_and_set /etc/systemd/journald.conf.d/99-compress.conf "Compress" "yes"
if grep -Eiq '^[[:space:]]*Compress=yes' \
    /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null; then
    echo "✅ [215] compressão habilitada."
else
    echo "⚠️ [215] compressão não configurada."
fi

# 216] armazenamento persistente
backup_and_set /etc/systemd/journald.conf.d/99-storage.conf "Storage" "persistent"
if grep -Eiq '^[[:space:]]*Storage=persistent' \
    /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null; then
    echo "✅ [216] armazenamento persistente configurado."
else
    echo "⚠️ [216] armazenamento persistente não configurado."
fi

# 217, 218, 219] Apenas recomendação
echo "⚠️ [217] desativar ForwardToSyslog manualmente se aplicável."
echo "⚠️ [218] ajustar política de rotação do journald manualmente."
echo "⚠️ [219] verificar configuração do logrotate manualmente."

# Reinicia journald
systemctl restart systemd-journald