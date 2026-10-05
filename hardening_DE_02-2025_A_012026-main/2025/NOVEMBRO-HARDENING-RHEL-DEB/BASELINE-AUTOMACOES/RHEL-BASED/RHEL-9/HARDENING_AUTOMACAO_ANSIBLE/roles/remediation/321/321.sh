Entendi! Vou ajustar o script para seguir o mesmo estilo do primeiro. Aqui está:

#!/usr/bin/env bash

# Corrige a configuração do módulo DCCP
corrigir_modulo_dccp() {
    local modulo="dccp"
    local tipo_modulo="net"
    local caminho_modulo="$(readlink -f /lib/modules/**/kernel/$tipo_modulo | sort -u)"
    local configuracoes_modulo=()
    local resultado=()
    local diretorios_modulo=""

    # Verifica se o módulo está carregado e o descarrega se necessário
    if lsmod | grep "$modulo" &>/dev/null; then
        resultado+=("⚠️ ** REPROVADO **: Descarregando módulo kernel '$modulo'.")
        modprobe -r "$modulo" 2>/dev/null
        rmmod "$modulo" 2>/dev/null
    fi

    # Verifica configurações de instalação e blacklist
    while IFS= read -r linha_config; do
        configuracoes_modulo+=("$linha_config")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${modulo//-/_}"'\b')

    if ! grep -Pq -- '\binstall\h+'"${modulo//-/_}"'\h+\/bin\/(true|false)\b' <<< "${configuracoes_modulo[*]}"; then
        resultado+=("⚠️ ** REPROVADO **: Configurando módulo kernel '$modulo' para '/bin/false'.")
        printf '%s\n' "install $modulo /bin/false" >> /etc/modprobe.d/"$modulo".conf
    fi

    if ! grep -Pq -- '\bblacklist\h+'"${modulo//-/_}"'\b' <<< "${configuracoes_modulo[*]}"; then
        resultado+=("⚠️ ** REPROVADO **: Adicionando módulo kernel '$modulo' à lista de bloqueio.")
        printf '%s\n' "blacklist $modulo" >> /etc/modprobe.d/"$modulo".conf
    fi

    # Verifica se o módulo existe no sistema
    for diretorio_base in $caminho_modulo; do
        if [ -d "$diretorio_base/${modulo/-/\/}" ] && [ -n "$(ls -A $diretorio_base/${modulo/-/\/})" ]; then
            diretorios_modulo="$diretorios_modulo\n  - '$diretorio_base'"
        else
            resultado+=("✅ ** APROVADO **: Módulo kernel '$modulo' não existe em '$diretorio_base'.")
        fi
    done

    # Exibe resultados
    if [ -n "$diretorios_modulo" ]; then
        echo -e "\n\n -- INFO --\n - Módulo: '$modulo' existe em:$diretorios_modulo"
    fi

    if [ "${#resultado[@]}" -gt 0 ]; then
        printf '%s\n' "" "- Resultado da Remediação:" "${resultado[@]}"
    fi

    echo -e "\n - Remediação do módulo kernel '$modulo' concluída\n"
}

# Executar correção
corrigir_modulo_dccp
