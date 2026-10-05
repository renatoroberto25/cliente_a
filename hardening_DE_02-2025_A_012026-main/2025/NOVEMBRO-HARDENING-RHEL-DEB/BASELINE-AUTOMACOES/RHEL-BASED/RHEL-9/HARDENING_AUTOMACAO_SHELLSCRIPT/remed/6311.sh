#!/usr/bin/env bash

echo "Iniciando remediação: 237 - Configurações do auditd"

echo "237 Instalando os pacotes audit e audit-libs (se necessário)..."
if dnf install -y audit audit-libs &>/dev/null; then
    echo "✅ SUCESSO: Pacotes audit e audit-libs instalados"
else
    echo "❌ ERRO: Falha ao instalar audit e audit-libs"
fi

echo "238 Garantindo que 'audit=1' está presente nos parâmetros do kernel..."
if grubby --update-kernel ALL --args 'audit=1' &>/dev/null; then
    echo "✅ SUCESSO: Parâmetro 'audit=1' adicionado aos kernels"
else
    echo "❌ ERRO: Falha ao adicionar 'audit=1'"
fi

echo "239 Garantindo que 'audit_backlog_limit=8192' está presente nos parâmetros do kernel..."
if grubby --update-kernel ALL --args 'audit_backlog_limit=8192' &>/dev/null; then
    echo "✅ SUCESSO: Parâmetro 'audit_backlog_limit=8192' adicionado aos kernels"
else
    echo "❌ ERRO: Falha ao adicionar 'audit_backlog_limit=8192'"
fi

echo "240 Garantindo que o serviço auditd está habilitado e em execução..."
systemctl unmask auditd &>/dev/null
systemctl enable auditd &>/dev/null
if systemctl start auditd &>/dev/null; then
    echo "✅ SUCESSO: auditd habilitado e iniciado"
else
    echo "❌ ERRO: Falha ao iniciar o serviço auditd"
fi