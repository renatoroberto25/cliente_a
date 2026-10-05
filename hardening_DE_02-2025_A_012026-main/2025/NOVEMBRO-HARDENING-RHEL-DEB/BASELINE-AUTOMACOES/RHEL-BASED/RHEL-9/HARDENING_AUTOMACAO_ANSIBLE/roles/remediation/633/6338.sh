#!/usr/bin/env bash
echo "252 Ensure events that modify user/group information are collected"

RULE_FILE="/etc/audit/rules.d/50-identity.rules"

# Verificar se as regras já existem
EXISTING_RULES=$(auditctl -l 2>/dev/null | grep -E "/etc/(group|passwd|gshadow|shadow|security/opasswd|nsswitch.conf|pam.conf|pam.d).*p\s*wa.*key=identity")

if [[ -n "$EXISTING_RULES" ]]; then
  echo "✅ Regras de auditoria já existem para informações de usuário/grupo. Nenhuma alteração necessária."
  exit 0
fi

# Caso as regras não existam, escreve as regras no arquivo
echo "Escrevendo regras em $RULE_FILE..."

cat <<EOF > "$RULE_FILE"
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /etc/nsswitch.conf -p wa -k identity
-w /etc/pam.conf -p wa -k identity
-w /etc/pam.d -p wa -k identity
EOF

echo "✅ Regras gravadas com sucesso."

# Aplica as regras com augenrules
echo "Aplicando regras com augenrules..."
if augenrules --load; then
  echo "✅ Regras carregadas com sucesso."
else
  echo "❌ Erro ao carregar regras com augenrules."
fi

# Verifica se precisa de reboot (modo 2 = immutable)
if auditctl -s | grep -q "enabled.*2"; then
  echo "⚠️ AVISO: Reboot necessário para ativar as regras (modo 2 detectado)."
else
  echo "✅ Regras ativadas sem necessidade de reboot."
fi