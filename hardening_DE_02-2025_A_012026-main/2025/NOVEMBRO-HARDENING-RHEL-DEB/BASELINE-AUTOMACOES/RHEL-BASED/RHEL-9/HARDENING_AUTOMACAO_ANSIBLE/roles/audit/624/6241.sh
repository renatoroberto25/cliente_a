#!/usr/bin/env bash

# Hitss 236 - Ensure access to all logfiles has been configured
echo "236 Ensure access to all logfiles has been configured"

log()   { echo "✅ [APROVADO] $1"; }
fail()  { echo "[⚠️[REPROVADO]] $1"; }

output=""

# Determinar UID_MIN
uid_min="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"

# Função para verificar cada arquivo
check_file() {
  local fpath="$1"
  local fname="$(basename "$fpath")"
  local mode owner group
  mode=$(stat -c '%a' "$fpath")
  owner=$(stat -c '%U' "$fpath")
  group=$(stat -c '%G' "$fpath")

  case "$fname" in
    lastlog | lastlog.* | wtmp | wtmp.* | wtmp-* | btmp | btmp.* | btmp-*)
      [[ "$owner" != "root" || ! "$group" =~ ^(root|utmp)$ || "$mode" -gt 664 ]] &&
      output+="\n - $fpath: modo $mode, dono $owner:$group — esperado root:(root|utmp) e perm ≤ 664"
      ;;
    secure | auth.log | syslog | messages)
      [[ ! "$owner" =~ ^(root|syslog)$ || ! "$group" =~ ^(root|adm)$ || "$mode" -gt 640 ]] &&
      output+="\n - $fpath: modo $mode, dono $owner:$group — esperado (root|syslog):(root|adm) e perm ≤ 640"
      ;;
    *.journal | *.journal~)
      [[ "$owner" != "root" || ! "$group" =~ ^(root|systemd-journal)$ || "$mode" -gt 640 ]] &&
      output+="\n - $fpath: modo $mode, dono $owner:$group — esperado root:(root|systemd-journal) e perm ≤ 640"
      ;;
    gdm | gdm3 | SSSD | sssd)
      [[ ! "$owner" =~ ^(root|SSSD)$ || ! "$group" =~ ^(root|SSSD|gdm|gdm3)$ || "$mode" -gt 660 ]] &&
      output+="\n - $fpath: modo $mode, dono $owner:$group — esperado (root|SSSD):(root|SSSD|gdm|gdm3) e perm ≤ 660"
      ;;
    *)
      # Arquivos genéricos
      if [[ "$owner" =~ ^[a-zA-Z0-9._-]+$ && "$group" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        uid=$(id -u "$owner" 2>/dev/null || echo 99999)
        if [[ "$uid" -lt "$uid_min" ]]; then
          [[ ! "$owner" =~ ^(root|syslog)$ || ! "$group" =~ ^(root|adm)$ || "$mode" -gt 640 ]] &&
          output+="\n - $fpath: modo $mode, dono $owner:$group — esperado (root|syslog):(root|adm) e perm ≤ 640"
        fi
      fi
      ;;
  esac
}

# Buscar arquivos problemáticos
while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find /var/log -type f -print0)

# Exibir resultados
if [[ -z "$output" ]]; then
  echo -e "\n✅ [APROVADO]: Todos os arquivos em /var/log estão com permissões e donos adequados."
else
  echo -e "\n[⚠️[REPROVADO]]: Foram encontrados arquivos com configurações incorretas:"
  echo -e "$output"
fi