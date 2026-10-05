#!/usr/bin/env bash

# Lista de servidores NTP esperados
NTP_SERVERS=(
    "time.cloudflare.com iburst"
    "time.nist.gov iburst"
)

# Garante que o Chrony está instalado
instalar_chrony() {
    if ! rpm -q chrony &>/dev/null; then
        echo "🔄 Instalando Chrony..."
        if dnf install -y chrony &>/dev/null; then
            echo "[✅ SUCESSO] Chrony instalado."
        else
            echo "[❌ FALHA] Erro ao instalar Chrony."
        fi
    else
        echo "[✅ SUCESSO] Chrony já está instalado."
    fi
}

# Configura os servidores NTP
configurar_chrony() {
    local config_file="/etc/chrony.conf"
    local backup_file="/etc/chrony.conf.bak"

    cp "$config_file" "$backup_file"

    for server in "${NTP_SERVERS[@]}"; do
        if ! grep -q "$server" "$config_file"; then
            echo "Adicionando servidor NTP: $server"
            echo "server $server" >> "$config_file"
        fi
    done
    echo "[✅ SUCESSO] Configuração do Chrony atualizada."
}

# Garante que o Chrony não rode como root
ajustar_execucao_chrony() {
    local sysconfig_file="/etc/sysconfig/chronyd"

    if grep -q -- "-u root" "$sysconfig_file"; then
        sed -i 's/-u root//g' "$sysconfig_file"
        echo "[✅ SUCESSO] Chrony ajustado para não rodar como root."
    else
        echo "[✅ SUCESSO] Chrony já não roda como root."
    fi
}

# Habilita e inicia o serviço Chrony
iniciar_chrony() {
    systemctl unmask chronyd.service &>/dev/null
    if systemctl enable --now chronyd.service &>/dev/null; then
        echo "[✅ SUCESSO] Chrony iniciado corretamente."
    else
        echo "[❌ FALHA] Erro ao iniciar Chrony."
    fi
}

# Executa as remediações
instalar_chrony
configurar_chrony
ajustar_execucao_chrony
iniciar_chrony