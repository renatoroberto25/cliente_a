#!/usr/bin/env bash

# [230] Verifique se as contas em /etc/passwd usam senhas sombreadas
echo "[230] Verifique se as contas em /etc/passwd usam senhas sombreadas"
awk -F: '$2 != "x" {print $1}' /etc/passwd | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [231] Verifique se os campos de senha em /etc/shadow não estão vazios
echo "[231] Verifique se os campos de senha em /etc/shadow não estão vazios"
awk -F: '$2 == "" {print $1}' /etc/shadow | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [232] Verifique se todos os grupos em /etc/passwd existem em /etc/group
echo "[232] Verifique se todos os grupos em /etc/passwd existem em /etc/group"
awk -F: 'NR==FNR{g[$3];next} $4!="" && !($4 in g){print $1}' /etc/group /etc/passwd | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [233] Verifique se o grupo shadow está vazio (exceto root)
echo "[233] Verifique se o grupo shadow está vazio (exceto root)"
gid=$(grep '^shadow:' /etc/group | cut -d: -f3)
grep -v '^root:' /etc/passwd | awk -F: -v gid="$gid" '$4 == gid' | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [234] Verifique se não existem nomes de usuários duplicados
echo "[234] Verifique se não existem nomes de usuários duplicados"
cut -d: -f1 /etc/passwd | sort | uniq -d | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [235] Verifique se não existem nomes de grupos duplicados
echo "[235] Verifique se não existem nomes de grupos duplicados"
cut -d: -f1 /etc/group | sort | uniq -d | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [236] Verifique se não existem UIDs duplicados
echo "[236] Verifique se não existem UIDs duplicados"
cut -d: -f3 /etc/passwd | sort | uniq -d | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [237] Verifique se não existem GIDs duplicados
echo "[237] Verifique se não existem GIDs duplicados"
cut -d: -f3 /etc/group | sort | uniq -d | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [238] Verifique se apenas root possui UID 0
echo "[238] Verifique se apenas root possui UID 0"
awk -F: '$3 == 0 && $1 != "root"' /etc/passwd | read && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [239] Verifique a integridade do PATH do root
echo "[239] Verifique a integridade do PATH do root"
sudo -Hiu root env | awk -F= '/^PATH=/{print $2}' | grep -Eq '(^|:)(\.($|/)|$)|::|:$' && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [240] Verifique se todos os diretórios home existem
echo "[240] Verifique se todos os diretórios home existem"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6}' /etc/passwd |
while read -r dir; do
  [ ! -d "$dir" ] && echo "⚠️ REPROVADO" && break
done || echo "✅ APROVADO"

# [241] Verifique se os usuários são donos de seus diretórios home
echo "[241] Verifique se os usuários são donos de seus diretórios home"
awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $1":"$6}' /etc/passwd |
while IFS=: read -r user dir; do
  [ "$(stat -Lc %U "$dir" 2>/dev/null)" != "$user" ] && echo "⚠️ REPROVADO" && exit 1
done && echo "✅ APROVADO"


# [242] Verifique se os diretórios home possuem permissões 750 ou mais restritivas
echo "[242] Verifique se os diretórios home possuem permissões 750 ou mais restritivas"
reprovado=0
for dir in $(awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6}' /etc/passwd); do
  perm=$(stat -Lc '%a' "$dir" 2>/dev/null)
  if [ "$perm" -gt 750 ]; then
    echo "⚠️ REPROVADO"
    reprovado=1
    break
  fi
done
[ "$reprovado" -eq 0 ] && echo "✅ APROVADO"

# [243] Verifique se arquivos ocultos não são graváveis por grupo ou outros
echo "[243] Verifique se arquivos ocultos não são graváveis por grupo ou outros"
reprovado=0
for dir in $(awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6}' /etc/passwd); do
  if find "$dir" -maxdepth 1 -name ".*" -perm /022 -type f -print -quit | grep -q .; then
    echo "⚠️ REPROVADO"
    reprovado=1
    break
  fi
done
[ "$reprovado" -eq 0 ] && echo "✅ APROVADO"

# [244] Verifique se não existem arquivos .forward nos diretórios home
echo "[244] Verifique se não existem arquivos .forward nos diretórios home"
reprovado=0
for file in $(awk -F: '$1!~/(root|halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6"/.forward"}' /etc/passwd); do
  [ -f "$file" ] && echo "⚠️ REPROVADO" && reprovado=1 && break
done
[ "$reprovado" -eq 0 ] && echo "✅ APROVADO"

# [245] Verifique se não existem arquivos .netrc nos diretórios home
echo "[245] Verifique se não existem arquivos .netrc nos diretórios home"
reprovado=0
for file in $(awk -F: '$1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6"/.netrc"}' /etc/passwd); do
  [ -f "$file" ] && echo "⚠️ REPROVADO" && reprovado=1 && break
done
[ "$reprovado" -eq 0 ] && echo "✅ APROVADO"

# [246] Verifique se não existem arquivos .rhosts nos diretórios home
echo "[246] Verifique se não existem arquivos .rhosts nos diretórios home"
reprovado=0
for file in $(awk -F: '$1!~/(root|halt|sync|shutdown|nfsnobody)/ && $7!~/nologin|false/ {print $6"/.rhosts"}' /etc/passwd); do
  [ -f "$file" ] && echo "⚠️ REPROVADO" && reprovado=1 && break
done
[ "$reprovado" -eq 0 ] && echo "✅ APROVADO"
