#!/usr/bin/env bash

set -euo pipefail

AIDE_CONF_MAIN="$(whereis aide.conf | awk '{print $2}')"
AUDIT_TOOLS=("auditctl" "auditd" "ausearch" "aureport" "autrace" "augenrules")
AIDE_ATTRS="p+i+n+u+g+s+b+acl+xattrs+sha512"
AIDE_INCLUDE_DIR="/etc/aide.d"
AIDE_CUSTOM_RULES="$AIDE_INCLUDE_DIR/audit-tools.conf"

# Garante que o AIDE está instalado
if ! command -v aide &>/dev/null; then
  echo "⚠️ AIDE não está instalado. Abortando."
  exit 1
fi

# Cria diretório de includes se não existir
mkdir -p "$AIDE_INCLUDE_DIR"

# Gera as entradas para os arquivos de auditoria
{
  echo "# Regras de integridade para ferramentas de auditoria - gerado por script"
  for tool in "${AUDIT_TOOLS[@]}"; do
    path="$(readlink -f "/sbin/$tool")"
    [ -x "$path" ] && echo "$path $AIDE_ATTRS"
  done
} > "$AIDE_CUSTOM_RULES"

# Garante que o arquivo seja incluído no aide.conf
if ! grep -qF "# $AIDE_CUSTOM_RULES" "$AIDE_CONF_MAIN"; then
  echo -e "\n# $AIDE_CUSTOM_RULES\n@@include $AIDE_CUSTOM_RULES" >> "$AIDE_CONF_MAIN"
fi

echo -e "\n ✅ Regras adicionadas com sucesso ao AIDE para ferramentas de auditoria."

echo -e "\nEsse script não aplica as mudanças no banco do AIDE, ele só garante que os arquivos estejam corretamente configurados."
echo "Se quiser, pode adicionar um aide --init ou aide --update no final, com cuidado para não sobrescrever bancos sem querer."
echo -e "(Antes validar que existe o arquivo /var/lib/aide/aide.db.gz) \n"