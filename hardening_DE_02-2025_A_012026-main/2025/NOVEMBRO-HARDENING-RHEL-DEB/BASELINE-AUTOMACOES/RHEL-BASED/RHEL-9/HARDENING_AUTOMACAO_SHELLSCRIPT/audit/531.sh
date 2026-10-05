#!/usr/bin/env bash

echo " [172] Verificar versão mínima exigida dos pacotes de autenticação"

check_pkg_version() {
  local pkg="$1"
  local min="$2"
  local desc="$3"

  echo " $desc "

  if rpm -q "$pkg" &>/dev/null; then
    local versao_instalada
    versao_instalada=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}\n' "$pkg")

    if [ "$(printf '%s\n' "$min" "$versao_instalada" | sort -V | head -n1)" = "$min" ]; then
      echo "✅ [APROVADO] $pkg está na versão $versao_instalada (mínimo: $min)"
    else
      echo "⚠️ [REPROVADO] $pkg está na versão $versao_instalada (mínimo exigido: $min)"
    fi
  else
    echo "⚠️ [REPROVADO] $pkg não está instalado"
  fi
}

check_pkg_version pam          "51-19" "172 Garantir que a versão mínima do pam está instalada"
check_pkg_version authselect   "1.2.6-2"  "173 Garantir que a versão mínima do authselect está instalada"
check_pkg_version libpwquality "1.4.4-8"  "174 Garantir que a versão mínima do libpwquality está instalada"

echo -e "\n✅ Auditoria finalizada"
exit 0