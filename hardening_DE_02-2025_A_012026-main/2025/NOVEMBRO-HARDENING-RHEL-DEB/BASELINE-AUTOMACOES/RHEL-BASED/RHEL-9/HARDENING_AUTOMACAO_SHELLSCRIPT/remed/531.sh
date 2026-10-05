#!/usr/bin/env bash

echo " [172] Garantir que pacotes essenciais estejam instalados nas versões mínimas exigidas"

verifica_e_instala() {
  local pacote="$1"
  local versao_minima="$2"
  local descricao="$3"

  echo "$descricao"

  if rpm -q "$pacote" &>/dev/null; then
    versao_instalada=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}\n' "$pacote")
    if [ "$(printf '%s\n' "$versao_minima" "$versao_instalada" | sort -V | head -n1)" = "$versao_minima" ]; then
      echo "✅ [OK] $pacote na versão $versao_instalada (mínimo exigido: $versao_minima)"
    else
      echo "⚠️ $pacote na versão $versao_instalada (abaixo de $versao_minima) – atualizando..."
      dnf install -y "$pacote >= $versao_minima" &>/dev/null \
        && echo "✅ Atualizado para versão mínima $versao_minima ou superior" \
        || echo "❌ [FALHA] Não foi possível atualizar $pacote"
    fi
  else
    echo "⚠️ $pacote não instalado – instalando versão mínima $versao_minima..."
    dnf install -y "$pacote >= $versao_minima" &>/dev/null \
      && echo "✅ Instalado com sucesso" \
      || echo "❌ [FALHA] Não foi possível instalar $pacote"
  fi
}

verifica_e_instala pam          "51-19" "172 Verificar versão mínima do pam"
verifica_e_instala authselect   "1.2.6-2"  "173 Verificar versão mínima do authselect"
verifica_e_instala libpwquality "1.4.4-8"  "174 Verificar versão mínima do libpwquality"

echo -e "\n✅ Remediação finalizada"
exit 0