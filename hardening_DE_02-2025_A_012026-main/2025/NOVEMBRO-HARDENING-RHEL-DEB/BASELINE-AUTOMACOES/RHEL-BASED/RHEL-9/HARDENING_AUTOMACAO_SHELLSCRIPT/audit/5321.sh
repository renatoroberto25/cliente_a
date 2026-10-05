#!/usr/bin/env bash

echo "[175] Verificar se o perfil authselect ativo inclui módulos PAM obrigatórios"

modulos=("pam_pwquality.so" "pam_pwhistory.so" "pam_faillock.so" "pam_unix.so")
perfil_ativo=$(authselect current 2>/dev/null | awk '{print $NF}')
diretorio_perfil="/etc/authselect/${perfil_ativo}"
arquivos=("${diretorio_perfil}/system-auth" "${diretorio_perfil}/password-auth")

if [[ "$perfil_ativo" == "detected." || -z "$perfil_ativo" ]]; then
  echo "⚠️ Ambiente não gerenciado por authselect ou perfil não detectado. Verifique manualmente."
  exit 0
fi

faltando=0
for arquivo in "${arquivos[@]}"; do
  if [[ -f "$arquivo" ]]; then
    for modulo in "${modulos[@]}"; do
      if grep -q "\b${modulo}\b" "$arquivo"; then
        echo "✅ $modulo presente em $arquivo"
      else
        echo "⚠️ $modulo ausente em $arquivo"
        faltando=1
      fi
    done
  else
    echo "⚠️ Arquivo não encontrado: $arquivo"
    faltando=1
  fi
done

if [[ $faltando -eq 0 ]]; then
  echo "✅ Todos os módulos obrigatórios estão presentes nos arquivos PAM"
else
  echo "⚠️ Um ou mais módulos estão ausentes"
fi

exit 0