#!/usr/bin/env bash
echo "264 Ensure the audit configuration is immutable"

FINAL_RULE_FILE="/etc/audit/rules.d/99-finalize.rules"

# Verifica se a regra -e 2 já está presente
if grep -qP '^\h*-e\h+2\b' "$FINAL_RULE_FILE" 2>/dev/null; then
  echo "✅ A regra '-e 2' já está presente em $FINAL_RULE_FILE"
else
  echo "Adicionando '-e 2' ao final do arquivo $FINAL_RULE_FILE..."
  printf '\n-e 2\n' >> "$FINAL_RULE_FILE" && echo "✅ Regra adicionada"
fi

# Carregar as regras
echo "Carregando regras com augenrules..."
augenrules --load && echo "✅ Regras carregadas com sucesso"

# Verificar se o audit está em modo imutável
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
  echo "✅ Audit já está em modo imutável (enabled 2)"
else
  echo "⚠️ Reboot necessário para aplicar o modo imutável (enabled 2)"
fi