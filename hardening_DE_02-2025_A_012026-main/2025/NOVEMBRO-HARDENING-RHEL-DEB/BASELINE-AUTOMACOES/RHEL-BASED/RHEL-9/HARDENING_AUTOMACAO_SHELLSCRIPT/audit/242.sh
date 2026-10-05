#!/usr/bin/env bash

# Verifica se o at está instalado
verificar_instalacao_at() {
    if command -v at &>/dev/null; then
echo "✅ [APROVADO]: 'at' está instalado."
    else
echo "⚠️[REPROVADO]: 'at' não está instalado."
    fi
}

# Verifica se o arquivo /etc/at.allow existe e tem as permissões corretas
verificar_permissoes_at_allow() {
    local arquivo="/etc/at.allow"
    local esperado_permissao="640"
    local esperado_dono="root"
    local esperado_grupo1="daemon"
    local esperado_grupo2="root"

    if [[ -e "$arquivo" ]]; then
        local permissao_atual=$(stat -c "%a" "$arquivo")
        local dono_atual=$(stat -c "%U" "$arquivo")
        local grupo_atual=$(stat -c "%G" "$arquivo")

        [[ "$permissao_atual" -le "$esperado_permissao" ]] && \
echo "✅ [APROVADO]: Permissões de $arquivo estão corretas ($permissao_atual)." || \
echo "⚠️[REPROVADO]: Permissões de $arquivo estão incorretas ($permissao_atual), esperado $esperado_permissao."

        [[ "$dono_atual" == "$esperado_dono" ]] && \
echo "✅ [APROVADO]: Dono de $arquivo está correto ($dono_atual)." || \
echo "⚠️[REPROVADO]: Dono de $arquivo está incorreto ($dono_atual), esperado $esperado_dono."

        if [[ "$grupo_atual" == "$esperado_grupo1" || "$grupo_atual" == "$esperado_grupo2" ]]; then
echo "✅ [APROVADO]: Grupo de $arquivo está correto ($grupo_atual)."
        else
echo "⚠️[REPROVADO]: Grupo de $arquivo está incorreto ($grupo_atual), esperado $esperado_grupo1 ou $esperado_grupo2."
        fi
    else
echo "⚠️[REPROVADO]: $arquivo não existe."
    fi
}

# Executar verificações
verificar_instalacao_at
verificar_permissoes_at_allow