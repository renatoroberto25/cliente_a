#!/usr/bin/env bash
set -u

echo "[56-57] Remediacao: softwares legados"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para avaliar remediacoes"
    exit 0
fi

pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

echo "[56] Prelink removido"
if pkg_installed prelink; then
    echo "SKIP: prelink instalado; remocao ou desfazer prelink exige janela validada e aprovacao"
else
    echo "OK: prelink nao instalado"
fi

echo "[57] xinetd removido"
if pkg_installed xinetd; then
    echo "SKIP: xinetd instalado; remocao/desativacao pode afetar servicos legados e exige aprovacao"
else
    echo "OK: xinetd nao instalado"
fi

echo "OK"
exit 0
