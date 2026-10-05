#!/usr/bin/env bash

echo " [165] Garantir que o sudo esteja instalado"

if rpm -q sudo &>/dev/null && [ -x /usr/bin/sudo ]; then
  echo "✅ [APROVADO] sudo já está instalado"
else
  echo "⚠️ sudo não encontrado – instalando..."
  dnf install -y sudo &>/dev/null

  if rpm -q sudo &>/dev/null && [ -x /usr/bin/sudo ]; then
    echo "✅ sudo instalado com sucesso"
  else
    echo "❌ [FALHA] Não foi possível instalar o sudo"
  fi
fi

echo -e "\n✅ Remediação finalizada"
exit 0