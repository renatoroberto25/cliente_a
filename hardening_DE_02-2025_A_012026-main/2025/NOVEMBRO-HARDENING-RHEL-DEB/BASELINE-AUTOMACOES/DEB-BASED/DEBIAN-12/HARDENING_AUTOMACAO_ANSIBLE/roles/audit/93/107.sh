#!/usr/bin/env bash
# [107] Verifique se o at está restrito a usuários autorizados (aplica-se apenas se cron NÃO existir e at estiver instalado)
echo -e "\n[107] Verifique se o at está restrito a usuários autorizados (aplica-se apenas se cron NÃO existir e at instalado)"
( systemctl list-unit-files | grep -q '^cron.service' && echo "✅ APROVADO" ) || ( ! command -v at >/dev/null 2>&1 && echo "✅ APROVADO" ) || ( [ -f /etc/at.allow ] && stat -Lc "%a %U %G" /etc/at.allow 2>/dev/null | grep -Eq '^600 root root$' && echo "✅ APROVADO" ) || echo "⚠️ REPROVADO"