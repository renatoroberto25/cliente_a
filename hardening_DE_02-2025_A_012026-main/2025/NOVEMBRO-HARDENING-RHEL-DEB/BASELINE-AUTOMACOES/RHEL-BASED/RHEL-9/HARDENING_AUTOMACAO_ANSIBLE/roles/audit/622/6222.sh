#!/usr/bin/env bash
echo "#TÓPICOS VALIDOS APENAS SE O journald FOR O PADRÃO LOCAL CASO USE EXCLUSIVAMENTE rsyslog DESCONSIDERAR#"

echo "225 Ensure journald ForwardToSyslog is disabled"

forward_to_syslog=$(systemd-analyze cat-config systemd/journald.conf systemd/journald.conf.d/* 2>/dev/null | grep -E "^ForwardToSyslog=")

if [[ "$forward_to_syslog" == "ForwardToSyslog=no" ]]; then
echo "✅ [APROVADO]: ForwardToSyslog está corretamente configurado como 'no'"
else
echo "⚠️[REPROVADO]: ForwardToSyslog NÃO está configurado como 'no'"
echo "Valor encontrado: ${forward_to_syslog:-não configurado}"
fi

echo "226 Ensure journald Compress is configured"

compress_config=$(systemd-analyze cat-config systemd/journald.conf systemd/journald.conf.d/* 2>/dev/null | grep -E "^Compress=")

if [[ "$compress_config" == "Compress=yes" ]]; then
echo "✅ [APROVADO]: Compress está corretamente configurado como 'yes'"
else
echo "⚠️[REPROVADO]: Compress NÃO está configurado como 'yes'"
echo "Valor encontrado: ${compress_config:-não configurado}"
fi

echo "227 Ensure journald Storage is configured"

storage_config=$(systemd-analyze cat-config systemd/journald.conf systemd/journald.conf.d/* 2>/dev/null | grep -E "^Storage=")

if [[ "$storage_config" == "Storage=persistent" ]]; then
echo "✅ [APROVADO]: Storage está corretamente configurado como 'persistent'"
else
echo "⚠️[REPROVADO]: Storage NÃO está configurado como 'persistent'"
echo "Valor encontrado: ${storage_config:-não configurado}"
fi