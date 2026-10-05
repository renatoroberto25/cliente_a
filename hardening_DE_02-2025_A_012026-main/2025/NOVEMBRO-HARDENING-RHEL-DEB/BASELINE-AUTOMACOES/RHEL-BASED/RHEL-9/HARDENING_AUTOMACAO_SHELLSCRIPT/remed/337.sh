#!/usr/bin/env bash

# 130 Ensure reverse path filtering is enabled (Hitss Benchmark)
# Parâmetros recomendados:
# - net.ipv4.conf.all.rp_filter = 1
# - net.ipv4.conf.default.rp_filter = 1

# Caminho do arquivo de configuração persistente
arquivo_conf="/etc/sysctl.d/60-netipv4_sysctl.conf"

# Função para aplicar e registrar o parâmetro
configurar_rede() {
    local parametro="$1"
    local valor="$2"

    echo "🔧 Aplicando ${parametro}=${valor}..."

    # Remove entradas antigas do mesmo parâmetro
    sed -i "/^\s*${parametro}\s*=.*/d" "$arquivo_conf"

    # Adiciona a nova configuração ao arquivo
    echo "${parametro} = ${valor}" >> "$arquivo_conf" && \
        echo "✅ Escrito em: $arquivo_conf" || \
        echo "❌ Falha ao escrever em $arquivo_conf"

    # Aplica imediatamente ao sistema
    if sysctl -w "${parametro}=${valor}" > /dev/null; then
        echo "✅ sysctl aplicou ${parametro}=${valor}"
    else
        echo "❌ sysctl falhou para ${parametro}"
    fi
}

# Configura os dois parâmetros necessários
configurar_rede "net.ipv4.conf.all.rp_filter" 1
configurar_rede "net.ipv4.conf.default.rp_filter" 1

# Atualiza rotas para refletir as mudanças
sysctl -w net.ipv4.route.flush=1 > /dev/null && echo "🔄 Rotas atualizadas."

# Exibe configurações finais
echo -e "\n📄 Verificação final em ${arquivo_conf}:"
grep 'rp_filter' "$arquivo_conf"
