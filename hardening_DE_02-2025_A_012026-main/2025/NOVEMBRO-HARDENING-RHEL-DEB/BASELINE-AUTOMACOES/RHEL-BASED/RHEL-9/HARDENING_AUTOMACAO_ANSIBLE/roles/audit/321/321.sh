#!/usr/bin/env bash

# Verifica se o módulo DCCP está instalado e configurado corretamente
verificar_modulo_dccp() {
    local modulo="dccp"
    local tipo_modulo="net"
    local caminho_modulo="$(readlink -f /lib/modules/**/kernel/$tipo_modulo | sort -u)"
    local configuracoes_modulo=()
    local resultado_pass=()
    local resultado_fail=()
    local diretorios_modulo=""

    # Verifica se o módulo está carregado
    if ! lsmod | grep "$modulo" &>/dev/null; then
        resultado_pass+=("✅ [APROVADO]: Módulo kernel '$modulo' não está carregado.")
    else
        resultado_fail+=("⚠️[REPROVADO]: Módulo kernel '$modulo' está carregado.")
    fi

    # Verifica configurações de instalação e blacklist
    while IFS= read -r linha_config; do
        configuracoes_modulo+=("$linha_config")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${modulo//-/_}"'\b')

    if grep -Pq -- '\binstall\h+'"${modulo//-/_}"'\h+\/bin\/(true|false)\b' <<< "${configuracoes_modulo[*]}"; then
        resultado_pass+=("✅ [APROVADO]: Módulo kernel '$modulo' não é carregável.")
    else
        resultado_fail+=("⚠️[REPROVADO]: Módulo kernel '$modulo' é carregável.")
    fi

    if grep -Pq -- '\bblacklist\h+'"${modulo//-/_}"'\b' <<< "${configuracoes_modulo[*]}"; then
        resultado_pass+=("✅ [APROVADO]: Módulo kernel '$modulo' está na lista de bloqueio.")
    else
        resultado_fail+=("⚠️[REPROVADO]: Módulo kernel '$modulo' não está na lista de bloqueio.")
    fi

    # Verifica se o módulo existe no sistema
    for diretorio_base in $caminho_modulo; do
        if [ -d "$diretorio_base/${modulo/-/\/}" ] && [ -n "$(ls -A $diretorio_base/${modulo/-/\/})" ]; then
            diretorios_modulo="$diretorios_modulo\n  - '$diretorio_base'"
        else
            resultado_pass+=("✅ [APROVADO]: Módulo kernel '$modulo' não existe em '$diretorio_base'.")
        fi
    done

    # Exibe resultados
    if [ -n "$diretorios_modulo" ]; then
echo "\n\n -- INFO --\n - Módulo: '$modulo' existe em:$diretorios_modulo"
    fi

    if [ "${#resultado_fail[@]}" -le 0 ]; then
        printf '%s\n' "" "- Resultado da Auditoria:" " ✅ [APROVADO]:" "${resultado_pass[@]}"
    else
        printf '%s\n' "" "- Resultado da Auditoria:" " ⚠️[REPROVADO]" " - Motivo(s) da falha na auditoria:" "${resultado_fail[@]}"
        [ "${#resultado_pass[@]}" -gt 0 ] && printf '%s\n' "- Configurado corretamente:" "${resultado_pass[@]}"
    fi
}

# Executar verificação
verificar_modulo_dccp