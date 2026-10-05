#!/usr/bin/env bash

echo -e "\n [36 - 39] Configurar repositórios de pacotes"

# Verificar se há chaves GPG configuradas
if grep -r gpgkey /etc/yum.repos.d/* /etc/dnf/dnf.conf > /dev/null 2>&1; then
echo "✅ [APROVADO]: Chaves GPG encontradas corretamente"
else
echo "[⚠️[REPROVADO]: Chaves GPG não encontradas. Verifique a configuração dos repositórios."
fi

# Verificar se gpgcheck está ativado globalmente
if grep -Pi -- '^\h*gpgcheck\h*=\h*(1|true|yes)\b' /etc/dnf/dnf.conf > /dev/null 2>&1; then
echo "✅ [APROVADO]: gpgcheck ativado corretamente"
else
echo "[⚠️[REPROVADO]]: gpgcheck não está ativado globalmente."
fi

# Verificar se repo_gpgcheck está ativado globalmente
if grep ^repo_gpgcheck /etc/dnf/dnf.conf > /dev/null 2>&1; then
echo "✅ [APROVADO]: repo_gpgcheck ativado corretamente"
else
echo "[⚠️[REPROVADO]]: repo_gpgcheck não está ativado."
fi

# Verificar a lista de repositórios configurados
if dnf repolist > /dev/null 2>&1; then
echo "✅ [APROVADO]: Repositórios configurados corretamente"
else
echo "[⚠️[REPROVADO]]: Erro ao listar repositórios. Verifique a configuração do DNF."
fi
