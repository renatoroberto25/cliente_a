#!/usr/bin/env bash

echo "[44 - 48] Remediação: Sticky bit e Autofs"

echo -e "\n[44] Aplicar sticky bit em diretórios world-writable"
WW_DIRS=$(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null || true)
if [ -n "$WW_DIRS" ]; then
  for d in $WW_DIRS; do
    if chmod +t "$d" 2>/dev/null; then
      echo "✔ Sticky aplicado: $d"
    else
      echo "⚠️ Falha ao aplicar sticky: $d"
    fi
  done
else
  echo "✔ Nenhum diretório inseguro encontrado"
fi

echo -e "\n[45] Sticky bit em /tmp"
if stat -c "%A" /tmp 2>/dev/null | grep -q 't'; then
  echo "✔ /tmp já contém sticky bit"
else
  if chmod +t /tmp 2>/dev/null; then
    echo "✔ Sticky aplicado em /tmp"
  else
    echo "⚠️ Falha ao aplicar sticky em /tmp"
  fi
fi

echo -e "\n[46] Sticky bit em /var/tmp"
if stat -c "%A" /var/tmp 2>/dev/null | grep -q 't'; then
  echo "✔ /var/tmp já contém sticky bit"
else
  if chmod +t /var/tmp 2>/dev/null; then
    echo "✔ Sticky aplicado em /var/tmp"
  else
    echo "⚠️ Falha ao aplicar sticky em /var/tmp"
  fi
fi

echo -e "\n[47] Sticky bit em /dev/shm"
if stat -c "%A" /dev/shm 2>/dev/null | grep -q 't'; then
  echo "✔ /dev/shm já contém sticky bit"
else
  if chmod +t /dev/shm 2>/dev/null; then
    echo "✔ Sticky aplicado em /dev/shm"
  else
    echo "⚠️ Falha ao aplicar sticky em /dev/shm"
  fi
fi

echo -e "\n[48] Desabilitar autofs"
if systemctl list-unit-files 2>/dev/null | grep -q "^autofs.service"; then
  if systemctl is-enabled autofs &>/dev/null; then
    systemctl disable autofs --now >/dev/null 2>&1 || true
    systemctl mask autofs >/dev/null 2>&1 || true
    echo "✔ autofs desabilitado e mascarado"
  else
    echo "✔ autofs já desabilitado"
  fi
else
  echo "✔ autofs não instalado no sistema"
fi


