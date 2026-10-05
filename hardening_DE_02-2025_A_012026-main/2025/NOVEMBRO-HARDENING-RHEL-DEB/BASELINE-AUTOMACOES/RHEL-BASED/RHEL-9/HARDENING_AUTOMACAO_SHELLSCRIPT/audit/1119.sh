#! /usr/bin/env bash

{
   a_output=(); a_output2=(); a_modprope_config=(); a_excluded=(); a_available_modules=()
   a_ignore=("xfs" "vfat" "ext2" "ext3" "ext4")
   a_cve_exists=("afs" "ceph" "cifs" "exfat" "ext" "fat" "fscache" "fuse" "gfs2" "nfs_common" "nfsd" "smbfs_common")
   f_module_chk()
   {
      l_out2=""; grep -Pq -- "\b$l_mod_name\b" <<< "${a_cve_exists[*]}" && l_out2=" <- CVE exists!"
      if ! grep -Pq -- '\bblacklist\h+'"$l_mod_name"'\b' <<< "${a_modprope_config[*]}"; then
         a_output2+=("  - Modulo do kernel: \"$l_mod_name\" nao esta totalmente desativado $l_out2")
      elif ! grep -Pq -- '\binstall\h+'"$l_mod_name"'\h+\/bin\/(false|true)\b' <<< "${a_modprope_config[*]}"; then
         a_output2+=("  - Modulo do kernel: \"$l_mod_name\" nao esta totalmente desativado $l_out2")
      fi
      if lsmod | grep "$l_mod_name" &> /dev/null; then # Verificar se o modulo esta carregado
         l_output2+=("  - Modulo do kernel: \"$l_mod_name\" esta carregado" "")
      fi
   }
   while IFS= read -r -d $'\0' l_module_dir; do
      a_available_modules+=("$(basename "$l_module_dir")")
   done < <(find "$(readlink -f /lib/modules/"$(uname -r)"/kernel/fs)" -mindepth 1 -maxdepth 1 -type d ! -empty -print0)
   while IFS= read -r l_exclude; do
      if grep -Pq -- "\b$l_exclude\b" <<< "${a_cve_exists[*]}"; then
         a_output2+=("  - AVISO: modulo do kernel: \"$l_exclude\" tem um CVE e esta atualmente montado!")
      elif 
         grep -Pq -- "\b$l_exclude\b" <<< "${a_available_modules[*]}"; then
         a_output+=("  - Modulo do kernel: \"$l_exclude\" esta atualmente montado - NAO descarregar ou desativar")
      fi
      ! grep -Pq -- "\b$l_exclude\b" <<< "${a_ignore[*]}" && a_ignore+=("$l_exclude")
   done < <(findmnt -knD | awk '{print $2}' | sort -u)
   while IFS= read -r l_config; do
      a_modprope_config+=("$l_config")
   done < <(modprobe --showconfig | grep -P '^\h*(blacklist|install)')
   for l_mod_name in "${a_available_modules[@]}"; do # Iterar sobre todos os modulos de sistema de arquivos
      [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"
      if grep -Pq -- "\b$l_mod_name\b" <<< "${a_ignore[*]}"; then
         a_excluded+=(" - Modulo do kernel: \"$l_mod_name\"")
      else
         f_module_chk
      fi
   done
   [ "${#a_excluded[@]}" -gt 0 ] && printf '%s\n' "" " -- INFO --" \
   "Os seguintes foram intencionalmente ignorados" \
    "${a_excluded[@]}"
   if [ "${#a_output2[@]}" -le 0 ]; then
      printf '%s\n' "" "  - Nenhum modulo de kernel de sistema de arquivos nao utilizado esta habilitado" "${a_output[@]}" ""
   else
      printf '%s\n' "" "-- Resultado da Auditoria: --" "  REVISE o seguinte" "${a_output2[@]}"
      [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "-- Configurado corretamente: --" "${a_output[@]}" ""
   fi
}