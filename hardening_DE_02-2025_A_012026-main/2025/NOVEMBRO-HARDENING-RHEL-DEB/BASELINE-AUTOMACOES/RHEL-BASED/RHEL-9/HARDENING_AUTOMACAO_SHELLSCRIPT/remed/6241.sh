#!/usr/bin/env bash

echo "236 Ensure access to all logfiles has been configured"
echo

log()  { echo "[✅ SUCESSO] $1"; }
mod()  { echo "[⚠️ MODIFICAÇÃO] $1"; }
err()  { echo "[⚠️ FALHA] $1"; }

{
   l_output2=""
   l_uidmin="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"

   file_test_fix() {
      local changed=""
      local msg="Arquivo: \"$l_fname\""

      # Permissão
      if [ $(( l_mode & perm_mask )) -gt 0 ]; then
         chmod "$l_rperms" "$l_fname" && \
         msg+="\n   - Permissões ajustadas para até $maxperm" && changed=1
      fi

      # Dono
      if [[ ! "$l_user" =~ $l_auser ]]; then
         chown "$l_fuser" "$l_fname" && \
         msg+="\n   - Proprietário ajustado para $l_fuser" && changed=1
      fi

      # Grupo
      if [[ ! "$l_group" =~ $l_agroup ]]; then
         chgrp "$l_fgroup" "$l_fname" && \
         msg+="\n   - Grupo ajustado para $l_fgroup" && changed=1
      fi

      [ "$changed" = "1" ] && l_output2+="\n[⚠️ MODIFICAÇÃO] $msg\n"
   }

   unset a_file && a_file=()
   while IFS= read -r -d $'\0' l_file; do
      a_file+=("$(stat -Lc '%n^%#a^%U^%u^%G^%g' "$l_file")")
   done < <(find -L /var/log -type f \( -perm /0137 -o ! -user root -o ! -group root \) -print0)

   for entry in "${a_file[@]}"; do
      IFS="^" read -r l_fname l_mode l_user l_uid l_group l_gid <<< "$entry"
      l_bname="$(basename "$l_fname")"
      l_fuser="root"; l_fgroup="root"

      case "$l_bname" in
         lastlog | lastlog.* | wtmp | wtmp.* | wtmp-* | btmp | btmp.* | btmp-*)
            perm_mask=0113; l_rperms="ug-x,o-wx"; l_auser="root"; l_agroup="(root|utmp)"
            ;;
         secure | auth.log | syslog | messages)
            perm_mask=0137; l_rperms="u-x,g-wx,o-rwx"; l_auser="(root|syslog)"; l_agroup="(root|adm)"
            ;;
         SSSD | sssd)
            perm_mask=0117; l_rperms="ug-x,o-rwx"; l_auser="(root|SSSD)"; l_agroup="(root|SSSD)"
            ;;
         gdm | gdm3)
            perm_mask=0117; l_rperms="ug-x,o-rwx"; l_auser="root"; l_agroup="(root|gdm|gdm3)"
            ;;
         *.journal | *.journal~)
            perm_mask=0137; l_rperms="u-x,g-wx,o-rwx"; l_auser="root"; l_agroup="(root|systemd-journal)"
            ;;
         *)
            perm_mask=0137; l_rperms="u-x,g-wx,o-rwx"; l_auser="(root|syslog)"; l_agroup="(root|adm)"
            if [ "$l_uid" -lt "$l_uidmin" ] && [ -z "$(awk -v grp="$l_group" -F: '$1==grp {print $4}' /etc/group)" ]; then
               [[ ! "$l_user" =~ $l_auser ]] && l_auser="(root|syslog|$l_user)"
               if [[ ! "$l_group" =~ $l_agroup ]]; then
                  l_tst=""
                  while read -r l_duid; do
                     [ "$l_duid" -ge "$l_uidmin" ] && l_tst="fail"
                  done <<< "$(awk -F: -v gid="$l_gid" '$4==gid {print $3}' /etc/passwd)"
                  [ "$l_tst" != "fail" ] && l_agroup="(root|adm|$l_group)"
               fi
            fi
            ;;
      esac

      maxperm="$(printf '%o' $((0777 & ~perm_mask)))"
      file_test_fix
   done

   if [ -z "$l_output2" ]; then
      log "Todos os arquivos em /var/log estão corretos. Nenhuma modificação aplicada."
   else
      echo -e "$l_output2"
   fi
}