#!/usr/bin/env bash

log() {
    echo "[✅ SUCESSO] $1"
}

err() {
    echo "[⚠️ FALHA] $1"
}


echo "36 -39 Configure Package Repositories"

CONFIG_FILE="/etc/dnf/dnf.conf"
echo "36 Ensure GPG keys are configured "
# Garantir que as chaves GPG estão configuradas nos repositórios
echo "Verificando chaves GPG nos repositórios..."
if ! grep -rq "gpgkey" /etc/yum.repos.d/* /etc/dnf/dnf.conf; then
    err " REPROVADO: Nenhuma chave GPG encontrada nos repositórios. Verifique manualmente."
else
    log " APROVADO: Chaves GPG já estão configuradas."
fi

echo "37 Ensure gpgcheck is globally activated"
# Garantir que gpgcheck está ativado globalmente
echo "Ativando gpgcheck globalmente..."
if [ -f "$CONFIG_FILE" ]; then
    if sed -i 's/^gpgcheck\s*=\s*.*/gpgcheck=1/' "$CONFIG_FILE"; then
        log " APROVADO: gpgcheck ativado no arquivo $CONFIG_FILE."
    else
        err " REPROVADO: Erro ao ativar gpgcheck no arquivo $CONFIG_FILE."
    fi
else
    err " REPROVADO: Arquivo $CONFIG_FILE não encontrado."
fi

echo "Verificando arquivos em /etc/yum.repos.d/..."
REPO_FILES=$(find /etc/yum.repos.d/ -name "*.repo")
if [ -z "$REPO_FILES" ]; then
    err " REPROVADO: Nenhum arquivo .repo encontrado em /etc/yum.repos.d/"
else
    for FILE in $REPO_FILES; do
        echo "Checking: $FILE"
        if sed -i 's/^gpgcheck\s*=\s*.*/gpgcheck=1/' "$FILE"; then
            log " APROVADO: gpgcheck ativado no arquivo $FILE."
        else
            err " REPROVADO: Erro ao ativar gpgcheck no arquivo $FILE."
        fi
    done
fi

echo "39 Ensure package manager repositories are configured"
# Verificar e corrigir lista de repositórios
echo "Verificando repositórios do DNF..."
if dnf clean all > /dev/null 2>&1 && dnf repolist > /dev/null 2>&1; then
    log " APROVADO: Repositórios configurados corretamente."
else
    err " REPROVADO: Problema ao listar os repositórios. Verifique manualmente."
fi