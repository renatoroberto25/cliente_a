#!/usr/bin/env bash

log() { echo "[✅ SUCESSO] $1"; }
err() { echo "[⚠️ FALHA] $1"; }
warn() { echo "[⚠️ ATENÇÃO] $1"; }

echo "Remediação HITSS 292 - 295 - Aplicando correções seguras quando possível"

# 289 - Não automatizar
warn "289 - NÃO REMEDIADO: usuários com senha visível no /etc/passwd devem ser avaliados manualmente."

# 290 - Corrigir senhas vazias no /etc/shadow (desabilitar conta)
while IFS=: read -r user pass _; do
  if [[ -z "$pass" ]]; then
    usermod -L "$user" 2>/dev/null && log "Usuário \"$user\" com senha vazia foi bloqueado." || err "Falha ao bloquear \"$user\""
  fi
done < /etc/shadow

# 291 - Criar grupos faltantes para usuários
mapfile -t gids_passwd < <(cut -d: -f4 /etc/passwd | sort -u)
mapfile -t gids_group < <(cut -d: -f3 /etc/group | sort -u)

for gid in "${gids_passwd[@]}"; do
  if ! printf '%s\n' "${gids_group[@]}" | grep -qx "$gid"; then
    username=$(awk -F: -v id="$gid" '$4 == id {print $1}' /etc/passwd | head -n1)
    groupadd -g "$gid" "grp_$username" 2>/dev/null && log "Grupo \"grp_$username\" criado com GID $gid" || err "Falha ao criar grupo GID $gid"
  fi
done

# 292 a 295 - Não automatizar (UID/GID/nome duplicado)
warn "292 - NÃO REMEDIADO: UIDs duplicados devem ser corrigidos manualmente com extremo cuidado."
warn "293 - NÃO REMEDIADO: GIDs duplicados devem ser corrigidos manualmente com extremo cuidado."
warn "294 - NÃO REMEDIADO: Nomes de usuário duplicados exigem análise manual."
warn "295 - NÃO REMEDIADO: Nomes de grupo duplicados exigem análise manual."

echo " Remediação segura concluída para controles 292 - 295"
exit 0