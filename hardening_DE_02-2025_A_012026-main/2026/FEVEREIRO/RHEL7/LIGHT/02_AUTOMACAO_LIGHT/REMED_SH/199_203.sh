#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 199–203 (Homes – RHEL 7)"

############################################
# 199 – Usuários sem diretório home (somente reportar)
############################################
echo -e "\n[199] Usuários sem diretório home (apenas relatório, sem ação automática)"

MISSING_HOME=$(
  awk -F: '($3>=1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1":"$6}' /etc/passwd \
    | while IFS=: read -r u d; do
        [ -n "$d" ] && [ ! -d "$d" ] && echo "$u"
      done
)

if [ -n "${MISSING_HOME}" ]; then
  echo " Usuários sem home detectados:"
  echo "$MISSING_HOME"
  echo " Nenhuma ação automática realizada (ajuste manual recomendado)."
else
  echo " Todos os usuários válidos possuem diretório home."
fi

############################################
# 200 – Ownership do diretório home
############################################
echo -e "\n[200] Ajustar ownership dos diretórios home"

awk -F: '($3>=1000 && $7!="/sbin/nologin" && $7!="/bin/false"){print $1":"$6}' /etc/passwd \
  | while IFS=: read -r u d; do
      [ -z "$d" ] && continue
      [ ! -d "$d" ] && continue
      CUR_OWNER=$(stat -c %U "$d" 2>/dev/null || echo "")
      if [ -n "$CUR_OWNER" ] && [ "$CUR_OWNER" != "$u" ]; then
        chown "$u":"$u" "$d" 2>/dev/null || true
        echo " Ownership ajustado: $d -> $u:$u"
      fi
    done

############################################
# 201 – Permissões dos homes (750 ou mais restritivas)
############################################
echo -e "\n[201] Ajustar permissões dos diretórios home"

if [ -d /home ]; then
  find /home -mindepth 1 -maxdepth 1 -type d -perm /027 2>/dev/null | while read -r h; do
    chmod 750 "$h" 2>/dev/null || true
    echo " Permissão ajustada para 750: $h"
  done
fi

############################################
# 202 – Dotfiles com escrita indevida
############################################
echo -e "\n[202] Ajustar permissões de dotfiles"

if [ -d /home ]; then
  find /home -maxdepth 2 -type f -name ".*" -perm -002 2>/dev/null | while read -r f; do
    chmod o-w "$f" 2>/dev/null || true
    echo " Removido write de others em: $f"
  done
fi

############################################
# 203 – .forward/.netrc/.rhosts (remover ou proteger)
############################################
echo -e "\n[203] Tratar .forward / .netrc / .rhosts"

if [ -d /home ]; then
  find /home -maxdepth 2 -type f \( -name ".forward" -o -name ".netrc" -o -name ".rhosts" \) 2>/dev/null \
    | while read -r f; do
        TS="$(date +%Y%m%d_%H%M%S)"
        DEST="${f}.disabled_${TS}"
        mv "$f" "$DEST" 2>/dev/null || true
        echo " Arquivo sensível movido: $f -> $DEST"
      done
fi

echo -e "\n[OK] Bloco 199–203 aplicado"
