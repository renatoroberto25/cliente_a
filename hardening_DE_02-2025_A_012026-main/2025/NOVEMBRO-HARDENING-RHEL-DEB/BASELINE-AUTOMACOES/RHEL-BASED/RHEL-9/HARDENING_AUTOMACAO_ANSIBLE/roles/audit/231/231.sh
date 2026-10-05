#!/usr/bin/env bash

# Lista de servidores NTP esperados
NTP_SERVERS=(
    "time.cloudflare.com iburst"
    "time.nist.gov iburst"
)

# Verifica se o Chrony está instalado
verificar_instalacao_chrony() {
    if rpm -q chrony &>/dev/null; then
echo "✅ [APROVADO]: Chrony está instalado."
    else
echo "⚠️[REPROVADO]: Chrony não está instalado."
    fi
}

# Verifica a configuração dos servidores NTP
verificar_configuracao_chrony() {
    local config_file="/etc/chrony.conf"
    local configured_servers=$(grep -E '^server ' "$config_file" | awk '{print $2}')
    local issues=0

    for server in "${NTP_SERVERS[@]}"; do
        if ! grep -q "$server" "$config_file"; then
echo "⚠️[REPROVADO]: Servidor NTP $server não está configurado."
            ((issues++))
        fi
    done

    if [[ $issues -eq 0 ]]; then
echo "✅ [APROVADO]: Todos os servidores NTP estão configurados corretamente."
    fi
}

# Verifica se o Chrony está sendo executado como root
verificar_execucao_chrony() {
    local sysconfig_file="/etc/sysconfig/chronyd"
    if grep -q -- "-u root" "$sysconfig_file"; then
echo "⚠️[REPROVADO]: Chrony está sendo executado como root."
    else
echo "✅ [APROVADO]: Chrony não está rodando como root."
    fi
}

# Verifica se o serviço Chrony está rodando
verificar_servico_chrony() {
    if systemctl is-active --quiet chronyd.service; then
echo "✅ [APROVADO]: Chrony está rodando."
    else
echo "⚠️[REPROVADO]: Chrony não está rodando."
    fi
}

# Executar verificações
verificar_instalacao_chrony
verificar_configuracao_chrony
verificar_execucao_chrony
verificar_servico_chrony
