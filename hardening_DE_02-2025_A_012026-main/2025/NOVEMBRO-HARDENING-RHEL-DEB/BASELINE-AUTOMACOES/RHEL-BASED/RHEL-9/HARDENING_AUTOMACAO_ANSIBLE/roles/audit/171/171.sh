#!/usr/bin/env bash

# Função para verificar informações sensíveis em arquivos
check_sensitive_info() {
    local file="$1"
    if grep -Psqi -- "(\\\v|\\\r|\\\m|\\\s|\b$(grep ^ID= /etc/os-release | cut -d= -f2 | sed -e 's/"//g')\b)" "$file"; then
echo -e "\n- Audit Result (Sensitive Info - $file):\n ⚠️[REPROVADO]\n  - $file contém informações sensíveis do sistema."
        return 1
    else
echo -e "\n- Audit Result (Sensitive Info - $file):\n ✅ [APROVADO]:\n  - $file não contém informações sensíveis do sistema."
        return 0
    fi
}
# Função para verificar permissões e proprietário de arquivos
check_permissions_owner() {
    local file="$1"
    if [ -e "$file" ]; then
        local permissions=$(stat -c "%a" "$file")
        local owner=$(stat -c "%U:%G" "$file")
        if [[ "$permissions" -ge 644 ]] && [[ "$owner" == "root:root" ]]; then
echo -e "\n- Audit Result (Permissions - $file):\n  APROVADO\n  - $file possui permissões e proprietário corretos."
            return 0
        else
echo -e "\n- Audit Result (Permissions - $file):\n  REPROVADO\n  - $file possui permissões ou proprietário incorretos. Permissões: $permissions, Proprietário: $owner."
            return 1
        fi
    else
echo -e "\n- Audit Result (Permissions - $file):\n  REPROVADO\n  - $file não existe."
        return 1
    fi
}

# Auditoria 65 - /etc/motd e /etc/motd.d/
{
    l_output="" l_output2=""
    a_files=()
    for l_file in /etc/motd{,.d/*}; do
        if grep -Psqi -- "(\\\v|\\\r|\\\m|\\\s|\b$(grep ^ID= /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')\b)" "$l_file"; then
            l_output2="$l_output2\n - Arquivo: \"$l_file\" contém informações do sistema"
        else
            a_files+=("$l_file")
        fi
    done
    if [ "${#a_files[@]}" -gt 0 ]; then
echo -e "\n- Por favor, revise os seguintes arquivos e verifique se o conteúdo segue a política do site local\n"
        printf '%s\n' "${a_files[@]}"
    elif [ -z "$l_output2" ]; then
echo "- Nenhum arquivo MOTD com tamanho encontrado. Por favor, verifique se isso está em conformidade com a política do site local -"
    fi
    if [ -z "$l_output2" ]; then
        l_output=" - Nenhum arquivo MOTD inclui informações do sistema"
echo -e "\n- Resultado da Auditoria (MOTD):\n  APROVADO\n$l_output\n"
    else
echo -e "\n- Resultado da Auditoria (MOTD):\n  REPROVADO\n - Razão(ões) para falha da auditoria:\n$l_output2\n"
    fi
}

# Auditoria 63 - /etc/issue
check_sensitive_info "/etc/issue"

# Auditoria 64 - /etc/issue.net
check_sensitive_info "/etc/issue.net"

# Auditoria 65 - /etc/motd
check_permissions_owner "/etc/motd"

# Auditoria 66 - /etc/issue
check_permissions_owner "/etc/issue"

# Auditoria 67 - /etc/issue.net
check_permissions_owner "/etc/issue.net"