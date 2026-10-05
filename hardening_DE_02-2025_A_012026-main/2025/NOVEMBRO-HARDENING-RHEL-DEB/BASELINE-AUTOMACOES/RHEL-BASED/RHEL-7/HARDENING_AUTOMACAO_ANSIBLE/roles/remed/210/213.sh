#!/usr/bin/env bash
echo "[213] Garantir umask padrão do sistema (027)"

UMASK_SEGURA="027"
DATA=$(date +%Y%m%d%H%M%S)

# Lista de arquivos de interesse
ARQS=(
  "/etc/profile"
  "/etc/bashrc"
  "/etc/login.defs"
  "/etc/default/login"
  /etc/profile.d/*.sh
)

for arq in "${ARQS[@]}"; do
  [ -f "$arq" ] || continue

  if grep -Eq '^\s*umask\s+(00[0-6]|0[1-6][0-6]|02[0-6])' "$arq"; then
    cp -p "$arq" "${arq}.bak.$DATA"
    sed -i -E "s/^\s*umask\s+[0-6]{3}/umask $UMASK_SEGURA/" "$arq"
    echo "✔ umask ajustado para $UMASK_SEGURA em $arq"
  else
    echo "⚠️ Nenhum umask permissivo encontrado em $arq"
  fi
done

# Validação final
echo -e "\n[Verificação final]"
grep -R --color -nE '^\s*umask' /etc/profile /etc/bashrc /etc/profile.d/*.sh | grep -v '^#'
