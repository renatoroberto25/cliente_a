#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

secure_grub() { local id="$1" name="$2" found=0 f; echo "[$id] $name"; for f in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do [[ -e "$f" ]] || continue; found=1; backup_file "$f"; chown root:root "$f" && chmod 0600 "$f" || { echo "WARN: $f"; return; }; done; (( found )) && echo "OK: permissoes ajustadas" || echo "SKIP: grub.cfg ausente"; }

manual 43 'Senha no bootloader' 'Definir a credencial do GRUB, executar update-grub e validar pelo console.'
secure_grub 44 'Permissões seguras no arquivo do bootloader'
manual 45 'Single user mode com autenticação' 'Configurar a autenticação de recuperação e validar o acesso pelo console.'
