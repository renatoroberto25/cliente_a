#!/usr/bin/env bash

echo "[212] Verificar se TMOUT está corretamente configurado no ambiente de shell"
echo "--- Iniciando verificação de TMOUT, readonly e export ---"

TMOUT_MAX=900
aprovado=()
reprovado=()

verifica_tmout() {
  local file="$1"
  local valor
  local readonly
  local exportado

  valor="$(grep -Po '^\s*TMOUT\s*=\s*\d+' "$file" | awk -F= '{gsub(/ /, "", $2); print $2}' | head -n1)"
  readonly="$(grep -Pq '^\s*readonly\s+TMOUT\b' "$file" && echo ok)"
  exportado="$(grep -Pq '^\s*export\s+TMOUT\b' "$file" && echo ok)"

  if [[ "$valor" =~ ^[0-9]+$ ]] && [ "$valor" -le "$TMOUT_MAX" ] && [ "$valor" -gt 0 ]; then
    [[ "$readonly" == "ok" && "$exportado" == "ok" ]] && \
      aprovado+=("✅ [APROVADO]: TMOUT=$valor, exportado e readonly em $file") || \
      reprovado+=("⚠️ [REPROVADO]: TMOUT=$valor em $file, mas faltando export ou readonly")
  elif [ -n "$valor" ]; then
    reprovado+=("⚠️ [REPROVADO]: TMOUT=$valor em $file (valor inválido)")
  else
    reprovado+=("⚠️ [REPROVADO]: $file não define TMOUT")
  fi
}

for f in /etc/profile /etc/bashrc /etc/profile.d/*.sh; do
  [ -f "$f" ] && verifica_tmout "$f"
done

if [ "${#reprovado[@]}" -eq 0 ]; then
  printf '%s\n' "${aprovado[@]}"
else
  printf '%s\n' "${reprovado[@]}"
  [ "${#aprovado[@]}" -gt 0 ] && printf '\n%s\n' "${aprovado[@]}"
fi

echo "✅ Auditoria finalizada"
exit 0