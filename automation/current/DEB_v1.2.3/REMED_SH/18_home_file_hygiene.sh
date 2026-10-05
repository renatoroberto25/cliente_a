#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

home_hygiene() { local id="$1" name="$2" found=0 p u uid gid home shell; echo "[$id] $name"; case "$id" in 161|163) echo 'SKIP: owner ausente exige decisão por caminho';; 162) while IFS= read -r p; do found=1; backup_metadata "$p"; chmod +t "$p" && echo "OK: sticky $p" || echo "WARN: $p"; done < <(find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null); (( found )) || echo 'OK: nenhum achado';; 164) echo 'SKIP: remoção SUID/SGID exige allowlist aprovada';; 165) echo 'SKIP: criação de home exige validação por usuário';; 166|167) while IFS=: read -r u _ uid gid _ home shell; do (( uid >= 1000 )) || continue; [[ "$shell" == */nologin || "$shell" == */false || ! -d "$home" ]] && continue; backup_metadata "$home"; [[ "$id" == 166 ]] && chown "$u:$gid" "$home" || chmod go-rwx "$home"; done < /etc/passwd; echo 'OK: homes processados';; 168) while IFS= read -r p; do backup_file "$p"; chmod go-w "$p"; done < <(find /home -xdev -maxdepth 2 -type f -name '.*' -perm /022 2>/dev/null); echo 'OK: dotfiles processados';; 169) echo 'SKIP: desativação de .forward/.netrc/.rhosts exige revisão por usuário';; esac; }

home_hygiene 161 'Arquivos órfãos inexistentes'
home_hygiene 162 'Sticky bit em diretórios world writable'
home_hygiene 163 'Sem arquivos sem owner ou grupo'
home_hygiene 164 'SUID/SGID indevidos'
home_hygiene 165 'Usuários sem home inexistentes'
home_hygiene 166 'Ownership correto dos homes'
home_hygiene 167 'Permissões de home restritivas'
home_hygiene 168 'Dotfiles sem permissão world writable'
home_hygiene 169 'Sem arquivos .forward .netrc e .rhosts'
