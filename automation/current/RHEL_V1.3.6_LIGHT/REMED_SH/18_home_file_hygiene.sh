#!/usr/bin/env bash
set -u

echo "LIGHT - Remediacao: homes e arquivos especiais"

if [ "$(id -u)" -ne 0 ]; then
    echo "WARN: execute como root para aplicar remediacoes"
    exit 0
fi

TS="$(date +%Y%m%d%H%M%S)"

backup_file() {
    local file="$1"
    if [ -e "$file" ] && cp -p "$file" "${file}.hitss.bak.${TS}" 2>/dev/null; then
        chmod go-w "${file}.hitss.bak.${TS}" 2>/dev/null || true
    fi
}

valid_home_user() {
    local user="$1" uid="$2" home="$3" shell="$4"
    [ "$uid" -ge 1000 ] || return 1
    [ "$user" != "nfsnobody" ] || return 1
    [ -n "$home" ] || return 1
    [ "$home" != "/" ] || return 1
    case "$shell" in
        */nologin|*/false) return 1 ;;
    esac
    return 0
}

echo "[195] Arquivos orfaos"
echo "SKIP: corrigir nouser/nogroup em todo filesystem exige revisao manual dos caminhos encontrados"

echo "[196] World-writable fora de areas permitidas"
found=0
while IFS= read -r dir; do
    found=1
    chmod +t "$dir" 2>/dev/null && echo "OK: sticky bit aplicado em $dir" || echo "WARN: falha ao aplicar sticky bit em $dir"
done < <(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null)
[ "$found" -eq 0 ] && echo "OK: nenhum diretorio world-writable sem sticky bit"

echo "[197] Arquivos/diretorios sem owner ou group"
echo "SKIP: mesma familia do item 195; tratar via lista auditada"

echo "[199-201] Diretorios home validos, owner e permissao"
echo "SKIP: owner e modo das homes exigem revisao nominal; nenhum diretorio foi alterado"

echo "[202] Dotfiles inseguros nas homes"
echo "SKIP: dotfiles exigem revisao do proprietario; nenhum arquivo foi alterado"

echo "[203] Arquivos .forward/.netrc/.rhosts"
while IFS=: read -r user _ uid _ _ home shell; do
    valid_home_user "$user" "$uid" "$home" "$shell" || continue
    [ -d "$home" ] || continue

    for file in "$home/.forward" "$home/.netrc" "$home/.rhosts"; do
        if [ -f "$file" ]; then
            echo "SKIP: $file encontrado para $user; desativacao exige validacao do uso e aprovacao"
        else
            echo "OK: $file ausente"
        fi
    done
done < /etc/passwd

echo "OK"
exit 0
