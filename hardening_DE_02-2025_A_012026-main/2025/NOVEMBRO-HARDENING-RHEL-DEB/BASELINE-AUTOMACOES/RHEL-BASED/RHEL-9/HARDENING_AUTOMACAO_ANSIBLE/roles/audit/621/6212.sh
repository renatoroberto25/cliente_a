#!/usr/bin/env bash

echo "[218] Verificar se o acesso ao log do journald está corretamente configurado"

arquivo=""

# Define limite de permissão aceitável
max_perms=0640
found_issues=false
saida=""

# Detecta o arquivo de configuração
if [ -f /etc/tmpfiles.d/systemd.conf ]; then
  arquivo="/etc/tmpfiles.d/systemd.conf"
elif [ -f /usr/lib/tmpfiles.d/systemd.conf ]; then
  arquivo="/usr/lib/tmpfiles.d/systemd.conf"
fi

if [ -n "$arquivo" ]; then
  while IFS= read -r linha; do
    [[ "$linha" =~ ^\s*# ]] && continue
    [[ -z "$linha" ]] && continue

    perm=$(echo "$linha" | awk '{print $3}')
    [[ -z "$perm" ]] && continue

    if [[ "$perm" =~ ^0?[0-7]{3,4}$ ]]; then
      dec_perm=$((8#$perm))
      dec_max=$((8#$max_perms))

      if (( dec_perm > dec_max )); then
        found_issues=true
        saida+="  - Permissão $perm na linha: $linha\n"
      fi
    fi
  done < "$arquivo"

  if $found_issues; then
    printf "⚠️ [REPROVADO]: Permissões mais abertas que %s encontradas em %s\n" "$max_perms" "$arquivo"
    printf "%b" "$saida"
    echo -e "\n  - Revise e ajuste conforme sua política de segurança."
  else
    echo "✅ [APROVADO]: Todas as permissões estão corretas (até $max_perms) em $arquivo"
  fi
else
  echo "⚠️ [REPROVADO]: Arquivo systemd.conf não encontrado em /etc ou /usr/lib/tmpfiles.d"
fi

exit 0