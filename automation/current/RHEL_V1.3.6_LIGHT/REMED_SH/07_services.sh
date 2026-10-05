#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: servicos e componentes opcionais"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para avaliar remediacoes"
    exit 0
fi

pkg_absent_or_skip() {
    local id="$1" pkg="$2" label="$3"
    echo "[$id] $label"
    if rpm -q "$pkg" >/dev/null 2>&1; then
        echo "SKIP: pacote $pkg instalado; remocao/desativacao exige aprovacao do dono do servico"
    else
        echo "OK: pacote $pkg nao instalado"
    fi
}

pkg_absent_or_skip 73 ypserv "NIS server ausente"
pkg_absent_or_skip 74 telnet-server "Telnet server ausente"

echo "[75] MTA em modo local-only"
if [ ! -f /etc/postfix/main.cf ]; then
    echo "OK: Postfix nao instalado/configurado"
elif grep -Eq '^[[:space:]]*inet_interfaces[[:space:]]*=[[:space:]]*(localhost|loopback-only)\b' /etc/postfix/main.cf 2>/dev/null; then
    echo "OK: Postfix limitado a localhost/loopback-only"
else
    echo "SKIP: Postfix nao esta local-only; alterar MTA pode quebrar envio de aplicacoes"
fi


pkg_absent_or_skip 79 ypbind "Cliente NIS ausente"
pkg_absent_or_skip 80 rsh "Cliente rsh ausente"
pkg_absent_or_skip 81 talk "Cliente talk ausente"
pkg_absent_or_skip 82 telnet "Cliente telnet ausente"

pkg_absent_or_skip 85 tftp-server "TFTP server ausente"

echo "[86] PolicyKit endurecido"
POLKIT_DIR="/etc/polkit-1/rules.d"
if [ ! -d "$POLKIT_DIR" ]; then
    echo "OK: diretorio $POLKIT_DIR ausente"
elif ! ls "$POLKIT_DIR"/*.rules >/dev/null 2>&1; then
    echo "OK: nenhum arquivo .rules encontrado em $POLKIT_DIR"
elif grep -RE 'polkit\.Result\.YES|allow' "$POLKIT_DIR"/*.rules >/dev/null 2>&1; then
    echo "SKIP: regra permissiva de PolicyKit detectada; alteracao exige revisao da politica local"
else
    echo "OK: nenhuma regra permissiva simples detectada em PolicyKit"
fi

echo "OK"
exit 0
