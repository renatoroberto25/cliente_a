#!/usr/bin/env bash

echo -e "\n [175] Orientação para habilitar módulos PAM no authselect"

# Lista dos módulos esperados
modulos_esperados=("pam_pwquality.so" "pam_pwhistory.so" "pam_faillock.so" "pam_unix.so")

# Verifica se authselect está instalado
if ! command -v authselect &>/dev/null; then
  echo "❌ authselect não está instalado."
  exit 0
fi

perfil_ativo=$(authselect current | awk '{print $NF}')
echo -e " Perfil ativo: $perfil_ativo"

if [[ "$perfil_ativo" == "detected." ]]; then
  echo "⚠️ Sistema não gerenciado por authselect. Auditoria manual recomendada."
  exit 0
fi

echo "⚠️ Esta remediação é EDUCATIVA. Não altera nada automaticamente."

echo "📦 Backup do perfil atual:"
authselect backup

echo -e "\n💡 Exemplo de comando para ativar módulos recomendados:"
echo "authselect select $perfil_ativo with-faillock with-pwhistory with-pwquality --force"

echo -e "\n📘 Revise a política local antes de aplicar qualquer alteração no perfil authselect."

exit 0

#Remediação NÃO recomendada por script direto porque:
#Modificar arquivos dentro de /etc/authselect/ manualmente quebra a integridade do perfil (não é suportado oficialmente).
#É necessário recriar ou duplicar o perfil via authselect create-profile.
#Requer reaplicar com authselect select custom/<perfil> --force, o que pode sobrescrever regras específicas.
#Um erro aqui pode travar autenticação do sistema.