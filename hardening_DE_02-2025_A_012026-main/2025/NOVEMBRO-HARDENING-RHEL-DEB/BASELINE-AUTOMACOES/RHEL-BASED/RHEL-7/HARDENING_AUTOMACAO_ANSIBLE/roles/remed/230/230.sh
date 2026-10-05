#!/usr/bin/env bash
# [230–246] Integridade de contas, grupos e diretórios de usuários

# [230] Ensure accounts in /etc/passwd use shadowed passwords
echo "[230] Mover senhas para /etc/shadow"
pwconv

# [231] Ensure /etc/shadow password fields are not empty
echo "[231] Bloquear contas com senha vazia"
awk -F: '$2 == "" {print $1}' /etc/shadow | xargs -r -n1 passwd -l

# [232] Ensure all groups in /etc/passwd exist in /etc/group
echo "[232] Validar manualmente grupos inexistentes referenciados em /etc/passwd antes de criar com groupadd"

# [233] Ensure shadow group is empty
echo "[233] Remover usuários do grupo shadow"
gid=$(awk -F: '$1=="shadow"{print $3}' /etc/group)
awk -F: -v G="$gid" '$4==G{print $1}' /etc/passwd | xargs -r -n1 gpasswd -d shadow

# [234–237]
echo "[234–237] Corrigir manualmente duplicidades de usuários, grupos, UIDs ou GIDs — requer análise antes de alterar /etc/passwd e /etc/group"

# [238] Ensure root is the only UID 0 account
echo "[238] Corrigir contas com UID 0 diferentes de root"
awk -F: '$3==0 && $1!="root"{print $1}' /etc/passwd | while read u; do
  novo_uid=$(( $(awk -F: '{print $3}' /etc/passwd | sort -n | tail -1) + 1 ))
  usermod -u "$novo_uid" "$u"
done

# [239] Ensure root PATH Integrity
echo "[239] Verificar PATH do root — revisar diretórios e permissões antes de alterar"

# [240] Ensure all users' home directories exist
echo "[240] Criar diretórios home ausentes"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $1":"$6}' /etc/passwd | while IFS=: read u d; do
  [ -d "$d" ] || mkdir -p "$d"
done

# [241] Ensure users own their home directories
echo "[241] Corrigir dono dos diretórios home"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $1":"$6}' /etc/passwd | while IFS=: read u d; do
  [ -d "$d" ] && chown "$u":"$u" "$d" 2>/dev/null
done

# [242] Ensure users' home directories permissions are 750 or more restrictive
echo "[242] Ajustar permissões dos diretórios home"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6}' /etc/passwd | while read d; do
  [ -d "$d" ] && chmod 750 "$d"
done

# [243] Ensure users' dot files are not group or world writable
echo "[243] Remover permissão de escrita em arquivos ocultos"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6}' /etc/passwd | while read d; do
  [ -d "$d" ] && find "$d" -maxdepth 1 -name ".*" -perm /022 -type f -exec chmod go-w {} \;
done

# [244] Ensure no users have .forward files
echo "[244] Remover arquivos .forward"
awk -F: '$1!~/(root|halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6"/.forward"}' /etc/passwd | xargs -r -n1 rm -f

# [245] Ensure no users have .netrc files
echo "[245] Remover arquivos .netrc"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6"/.netrc"}' /etc/passwd | xargs -r -n1 rm -f

# [246] Ensure no users have .rhosts files
echo "[246] Remover arquivos .rhosts"
awk -F: '$1!~/(root|halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6"/.rhosts"}' /etc/passwd | xargs -r -n1 rm -f
