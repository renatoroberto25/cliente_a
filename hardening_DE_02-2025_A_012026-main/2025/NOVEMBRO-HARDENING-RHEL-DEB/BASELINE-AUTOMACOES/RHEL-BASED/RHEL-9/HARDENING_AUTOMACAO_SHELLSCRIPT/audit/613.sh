#!/usr/bin/env bash
echo -e "\n [216] Garantir proteção de integridade das ferramentas de auditoria com AIDE"

set -euo pipefail

AUDIT_TOOLS=("auditctl" "auditd" "ausearch" "aureport" "autrace" "augenrules")
AIDE_ATTRS="p+i+n+u+g+s+b+acl+xattrs+sha512"
AIDE_CONF_MAIN="$(whereis aide.conf | awk '{print $2}')"
AIDE_INCLUDE_DIR="/etc/aide.d"
AIDE_CUSTOM_RULES="$AIDE_INCLUDE_DIR/audit-tools.conf"

# Verifica se o AIDE está instalado
if ! command -v aide &>/dev/null; then
  echo "⚠️ AIDE não está instalado. Nenhuma ação realizada."
  exit 0
fi

mkdir -p "$AIDE_INCLUDE_DIR"

# Atualiza ou recria o arquivo de regras personalizadas
echo "# Regras para integridade das ferramentas de auditoria" > "$AIDE_CUSTOM_RULES"
for tool in "${AUDIT_TOOLS[@]}"; do
  tool_path="$(readlink -f "/sbin/$tool" || true)"
  if [[ -x "$tool_path" ]]; then
    echo "$tool_path $AIDE_ATTRS" >> "$AIDE_CUSTOM_RULES"
  fi
done
echo "✅ Regras criadas em $AIDE_CUSTOM_RULES"

# Garante inclusão no aide.conf
if [[ -f "$AIDE_CONF_MAIN" ]]; then
  if ! grep -qF "@@include $AIDE_CUSTOM_RULES" "$AIDE_CONF_MAIN"; then
    echo -e "\n# Inclusão automática\n@@include $AIDE_CUSTOM_RULES" >> "$AIDE_CONF_MAIN"
    echo "✅ Inclusão adicionada ao $AIDE_CONF_MAIN"
  else
    echo "✅ Inclusão já existente no $AIDE_CONF_MAIN"
  fi
else
  echo "⚠️ Arquivo $AIDE_CONF_MAIN não encontrado. Regra não incluída automaticamente."
fi

echo "✅ [FINALIZADO]: Proteção de integridade aplicada com sucesso"
exit 0