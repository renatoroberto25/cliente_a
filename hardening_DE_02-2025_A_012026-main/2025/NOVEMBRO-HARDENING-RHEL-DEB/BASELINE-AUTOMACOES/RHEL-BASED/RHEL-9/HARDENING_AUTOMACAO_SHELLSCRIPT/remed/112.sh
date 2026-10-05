#!/usr/bin/env bash
# HITSS 10-35  – Remediação agressiva para particionamento e opções de montagem
# Aplica opções de segurança no /etc/fstab e remonta partições críticas

set -eu

FSTAB="/etc/fstab"
BACKUP_DIR="/var/backups/hitss"
TS=$(date +%F-%H%M%S)
FSTAB_BKP="$BACKUP_DIR/fstab.$TS.bak"
mkdir -p "$BACKUP_DIR"

echo "[REM] HITSS 10-35 - Remediação agressiva (aplica opções em /etc/fstab e remonta)"
echo "❗ Backup do /etc/fstab em: $FSTAB_BKP"
cp -a "$FSTAB" "$FSTAB_BKP" && echo "✔ Backup criado" || { echo "✖ Falha ao criar backup"; exit 1; }

# Alvos: ponto:exige_separada:opções_recomendadas
TARGETS=(
  "/tmp:no:nodev,nosuid,noexec"
  "/dev/shm:no:nodev,nosuid,noexec"
  "/home:yes:nodev,nosuid"
  "/var:yes:nodev,nosuid"
  "/var/tmp:yes:nodev,nosuid,noexec"
  "/var/log:yes:nodev,nosuid,noexec"
  "/var/log/audit:yes:nodev,nosuid,noexec"
  # extras / baseline
  "/boot:no:nodev"
  "/UNIX:yes:nodev,nosuid,noexec"
  "/crash:yes:nodev,nosuid,noexec"
  "/historico:yes:nodev,nosuid,noexec"
)

# Funções utilitárias  ────────────────────────────────────────────────
merge_opts() {
  local existing="$1" desired="$2" out=""
  read -ra ex <<< "${existing//,/ }"
  read -ra de <<< "${desired//,/ }"
  for e in "${ex[@]}"; do [[ -z "$e" ]] && continue; [[ " $out " == *" $e "* ]] || out="$out $e"; done
  for d in "${de[@]}"; do [[ -z "$d" ]] && continue; [[ " $out " == *" $d "* ]] || out="$out $d"; done
  out="${out#"${out%%[![:space:]]*}"}"; out="${out%"${out##*[![:space:]]}"}"
  echo "${out// /,}"
}

escape_sed() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }

apply_fstab_entry() {
  local src="$1" tgt="$2" fstype="$3" opts="$4" freq="$5" pass="$6"
  if grep -qE "^[[:space:]]*([^#].*\s+)$tgt\s+" "$FSTAB"; then
    local cur_spec cur_vfstype cur_freq cur_pass
    cur_spec=$(awk -v t="$tgt" '$0!~/^#/ && $2==t {print $1;exit}' "$FSTAB"||true)
    cur_vfstype=$(awk -v t="$tgt" '$0!~/^#/ && $2==t {print $3;exit}' "$FSTAB"||true)
    cur_freq=$(awk -v t="$tgt" '$0!~/^#/ && $2==t {print $5;exit}' "$FSTAB"||true)
    cur_pass=$(awk -v t="$tgt" '$0!~/^#/ && $2==t {print $6;exit}' "$FSTAB"||true)
    [[ -z "$src" ]] && src="$cur_spec"; [[ -z "$fstype" ]] && fstype="$cur_vfstype"
    [[ -z "$freq" ]] && freq="$cur_freq"; [[ -z "$pass" ]] && pass="$cur_pass"
    sed -ri "s|^[[:space:]]*([^#].*\s+)$tgt\s+.*$|$(escape_sed "$src")\t$tgt\t$(escape_sed "$fstype")\t$(escape_sed "$opts")\t${freq:-0}\t${pass:-0}|" "$FSTAB"
  else
    echo -e "${src}\t${tgt}\t${fstype}\t${opts}\t${freq}\t${pass}" >> "$FSTAB"
  fi
}

do_remount() {
  local tgt="$1" opts="$2"
  if mountpoint -q "$tgt"; then
    mount -o remount,"$opts" "$tgt"
  elif grep -qE "^[[:space:]]*([^#].*\s+)$tgt\s+" "$FSTAB"; then
    mount "$tgt"
  fi
}

# Execução principal  ────────────────────────────────────────────────
FAILS=()
for entry in "${TARGETS[@]}"; do
  IFS=':' read -r point requires_sep want_opts <<< "$entry"
  echo; echo "----"; echo "[REM] Alvo: $point (requires_sep=$requires_sep)"
  [[ "$point" == "/" ]] && { echo "⚠️  Pular / (raiz)"; continue; }
  [[ ! -d "$point" ]] && { echo "⚠️  Diretório $point ausente"; FAILS+=("$point ausente"); continue; }

  src=$(findmnt -n -o SOURCE --target "$point" 2>/dev/null || true)
  fstype=$(findmnt -n -o FSTYPE --target "$point" 2>/dev/null || true)
  cur_opts=$(findmnt -n -o OPTIONS --target "$point" 2>/dev/null || true)
  new_opts=$(merge_opts "$cur_opts" "$want_opts")

  echo "✔ Fonte: ${src:-desconhecida}  Tipo: ${fstype:-desconhecido}"
  echo "✔ Opções atuais: ${cur_opts:-nenhuma}"
  echo "✔ Aplicando opções alvo: $new_opts"

  apply_fstab_entry "$src" "$point" "$fstype" "$new_opts" "0" "0" || FAILS+=("$point - erro fstab")
  do_remount "$point" "$new_opts" || FAILS+=("$point - falha remount")

  echo "✔ Remount concluído para $point"
  findmnt -n -o OPTIONS "$point" || true
done

# Resumo
echo; echo "==== RESUMO HITSS 10-35 ===="
if [ ${#FAILS[@]} -eq 0 ]; then
  echo "✔ Todas as remediações aplicadas com sucesso."
else
  echo "⚠️  Pendências:"
  printf '   - %s\n' "${FAILS[@]}"
  echo "❗ Verifique manualmente. Backup: $FSTAB_BKP"
fi
exit 0