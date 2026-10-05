#!/usr/bin/env bash

conf_dir="/etc/systemd/coredump.conf.d"
conf_file="$conf_dir/60-coredump.conf"
setting="ProcessSizeMax=0"

echo " Verificando e aplicando configuração de backtrace (HITSS 53)..."

[ ! -d "$conf_dir" ] && mkdir -p "$conf_dir"

if grep -q "^$setting" "$conf_file" 2>/dev/null; then
  echo "✅ $setting já configurado em $conf_file."
else
  if ! grep -q "^\[Coredump\]" "$conf_file" 2>/dev/null; then
    echo -e "[Coredump]\n$setting" > "$conf_file"
    echo "✅ Criado $conf_file com seção [Coredump] e configuração '$setting'."
  else
    echo "$setting" >> "$conf_file"
    echo "✅ Adicionada configuração '$setting' em $conf_file."
  fi
fi

echo -e "\n📄 Resultado final:"
grep -Hni "^ProcessSizeMax" "$conf_file"
