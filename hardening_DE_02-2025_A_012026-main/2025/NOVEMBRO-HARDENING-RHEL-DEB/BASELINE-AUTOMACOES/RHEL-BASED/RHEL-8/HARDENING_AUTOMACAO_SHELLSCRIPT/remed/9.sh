#!/usr/bin/env bash
# remediate_hitss_9-34_aggressive.sh
# Versão intrusiva: aplica opções de montagem no /etc/fstab e remonta os pontos
# Use com console de recuperação disponível — TESTE ANTES EM VM.
set -eu
FSTAB="/etc/fstab"
BACKUP_DIR="/var/backups/hitss"
TS=$(date +%F-%H%M%S)
FSTAB_BKP="$BACKUP_DIR/fstab.$TS.bak"
mkdir -p "$BACKUP_DIR"
echo "[REM] HITSS 9-34 - Remediação agressiva (aplica opções em /etc/fstab e remonta)"
echo "❗ Faz backup do /etc/fstab em: $FSTAB_BKP"
cp -a "$FSTAB" "$FSTAB_BKP" && echo "✔ Backup do fstab criado" || { echo "✖ Falha ao criar backup"; exit 1; }
# Lista de alvo: ponto:exige_separada:opcoes_desejadas
TARGETS=(
  "/tmp:no:nodev,nosuid,noexec"
  "/dev/shm:no:nodev,nosuid,noexec"
  "/home:yes:nodev,nosuid"
  "/var:yes:nodev,nosuid"
  "/var/tmp:yes:nodev,nosuid,noexec"
  "/var/log:yes:nodev,nosuid,noexec"
  "/var/log/audit:yes:nodev,nosuid,noexec"
  # partições extras
  "/boot:no:nodev"
  "/UNIX:yes:nodev,nosuid,noexec"
  "/crash:yes:nodev,nosuid,noexec"
  "/historico:yes:nodev,nosuid,noexec"
)
# util: junta opções sem duplicar, preservando ordem (mantém defaults se presente)
merge_opts() {
  # args: existing opts, desired opts
  local existing="$1"
  local desired="$2"
  local out=""
  # normalize commas -> space
  read -ra ex <<< "${existing//,/ }"
  read -ra de <<< "${desired//,/ }"
  for e in "${ex[@]}"; do
    [[ -z "$e" ]] && continue
    [[ " $out " == *" $e "* ]] || out="$out $e"
  done
  for d in "${de[@]}"; do
    [[ -z "$d" ]] && continue
    [[ " $out " == *" $d "* ]] || out="$out $d"
  done
  # trim & convert to comma list
  out="${out#"${out%%[![:space:]]*}"}"
  out="${out%"${out##*[![:space:]]}"}"
  echo "${out// /,}"
}
# util: escapa / para sed
escape_sed() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
# Aplica uma alteração em fstab: substitui/insere linha para o ponto alvo
apply_fstab_entry() {
  local src="$1"    # dispositivo (UUID=/dev/..., tmpfs, etc.)
  local tgt="$2"    # mountpoint
  local fstype="$3" # ex: ext4,tmpfs
  local opts="$4"   # opções finais (comma-separated)
  local freq="$5"   # dump (0)
  local pass="$6"   # fsck pass (0/1/2)
  # se já existe entrada (não comentada) para o ponto, substitui mantendo src/fstype/freq/pass se dados vazios
  if grep -qE "^[[:space:]]*([^#].*\s+)$tgt\s+" "$FSTAB"; then
    # pega campos atuais pra preservar quando necessário
    local cur_spec cur_vfstype cur_freq cur_pass
    cur_spec=$(awk -v tgt="$tgt" '$0 !~ /^#/ && $2==tgt {print $1; exit}' "$FSTAB" || true)
    cur_vfstype=$(awk -v tgt="$tgt" '$0 !~ /^#/ && $2==tgt {print $3; exit}' "$FSTAB" || true)
    cur_freq=$(awk -v tgt="$tgt" '$0 !~ /^#/ && $2==tgt {print $5; exit}' "$FSTAB" || true)
    cur_pass=$(awk -v tgt="$tgt" '$0 !~ /^#/ && $2==tgt {print $6; exit}' "$FSTAB" || true)
    [[ -z "$src" ]] && src="$cur_spec"
    [[ -z "$fstype" ]] && fstype="$cur_vfstype"
    [[ -z "$freq" ]] && freq="$cur_freq"
    [[ -z "$pass" ]] && pass="$cur_pass"
    src=$(escape_sed "$src")
    tgt_esc=$(escape_sed "$tgt")
    fstype=$(escape_sed "$fstype")
    opts_esc=$(escape_sed "$opts")
    freq=${freq:-0}
    pass=${pass:-0}
    # substitui a linha correspondente
    sed -ri "s|^[[:space:]]*([^#].*\s+)$tgt_esc\s+.*$|$src\t$tgt\t$fstype\t$opts_esc\t$freq\t$pass|" "$FSTAB"
    return $?
  else
    # não existe: acrescenta linha
    echo -e "${src}\t${tgt}\t${fstype}\t${opts}\t${freq}\t${pass}" >> "$FSTAB"
    return $?
  fi
}
# remonta o ponto com opções (remount)
do_remount() {
  local tgt="$1"
  local opts="$2"
  # remount com as opções (preserva outras com remount,OPT)
  if mountpoint -q "$tgt"; then
    mount -o remount,"$opts" "$tgt" && return 0 || return 1
  else
    # se não está montado, tenta montar (se houver entrada no fstab)
    if grep -qE "^[[:space:]]*([^#].*\s+)$tgt\s+" "$FSTAB"; then
      mount "$tgt" && return 0 || return 1
    else
      return 2
    fi
  fi
}
# loop
FAILS=()
for entry in "${TARGETS[@]}"; do
  IFS=':' read -r point requires_sep want_opts <<< "$entry"
  echo
  echo "----"
  echo "[REM] Alvo: $point  (requere_sep=$requires_sep)  desired_opts=$want_opts"
  # não mexer na raiz
  if [ "$point" = "/" ]; then
    echo "⚠️  Pular / (raiz) — não alterar opções de /"
    continue
  fi
  # existe o ponto?
  if [ ! -d "$point" ]; then
    echo "⚠️  Ponto $point não existe no sistema; pulando"
    FAILS+=("$point - mountpoint ausente")
    continue
  fi
  # Estado atual: montado? fonte? fstype? opções atuais?
  mounted=$(findmnt -n -o TARGET --target "$point" 2>/dev/null || true)
  src=$(findmnt -n -o SOURCE --target "$point" 2>/dev/null || true)
  fstype=$(findmnt -n -o FSTYPE --target "$point" 2>/dev/null || true)
  cur_opts=$(findmnt -n -o OPTIONS --target "$point" 2>/dev/null || true)
  # Se exige partição separada e não está montado separadamente -> falha/skip
  if [ "$requires_sep" = "yes" ]; then
    if [ -z "$mounted" ] || [ "$mounted" != "$point" ]; then
      echo "⚠️  $point não está montado separadamente. NÃO será criada partição automaticamente."
      FAILS+=("$point - não montado separadamente")
      continue
    fi
  fi
  # se não tem fonte (src vazio) e não está montado, pulamos
  if [ -z "$src" ]; then
    echo "⚠️  Não foi possível identificar dispositivo/fonte para $point. Pulando."
    FAILS+=("$point - fonte desconhecida")
    continue
  fi
  # Se fonte parece ser swap, skip
  if echo "$src" | grep -qiE 'swap'; then
    echo "⚠️  Fonte aparenta ser swap; pular alterações."
    continue
  fi
  # calcula opções novas: junta atuais com desejadas
  new_opts=$(merge_opts "$cur_opts" "$want_opts")
  echo "✔ Fonte: $src   Tipo: ${fstype:-unknown}   Opções atuais: ${cur_opts:-(none)}"
  echo "✔ Opções alvo: $new_opts"
  # Atualiza /etc/fstab
  # Se a entrada em fstab existe, tenta preservar tipo se detectado; senão usa detectado
  # Campos freq/pass setados para 0 por padrão
  if grep -qE "^[[:space:]]*([^#].*\s+)$point\s+" "$FSTAB"; then
    echo "✔ Atualizando entrada existente em $FSTAB para $point..."
    if apply_fstab_entry "$src" "$point" "$fstype" "$new_opts" "0" "0"; then
      echo "✔ fstab atualizado para $point"
    else
      echo "✖ Falha ao atualizar fstab para $point"
      FAILS+=("$point - erro atualização fstab")
      continue
    fi
  else
    echo "✔ Inserindo nova entrada no $FSTAB para $point..."
    if apply_fstab_entry "$src" "$point" "${fstype:-auto}" "$new_opts" "0" "0"; then
      echo "✔ Entrada adicionada ao fstab"
    else
      echo "✖ Falha ao adicionar entrada ao fstab"
      FAILS+=("$point - erro adicionar fstab")
      continue
    fi
  fi
  # Tenta remount/mount com as novas opções
  echo "✔ Aplicando remount/mount com opções: $new_opts"
  if do_remount "$point" "$new_opts"; then
    # verifica
    applied_opts=$(findmnt -n -o OPTIONS --target "$point" 2>/dev/null || true)
    if grep -qw "$(echo "$want_opts" | cut -d',' -f1)" <<< "$applied_opts" || true; then
      echo "✔ Remount bem sucedido. Opções atuais: $applied_opts"
    else
      echo "⚠️  Remount executado, mas não foi possível confirmar todas as opções desejadas. Atuais: $applied_opts"
      # não falha fatalmente; registra
      FAILS+=("$point - remount incompleto")
    fi
  else
    echo "✖ Falha ao remount/mount $point"
    FAILS+=("$point - falha remount")
  fi
done
# resumo
echo
echo "==== RESUMO REMEDIAÇÃO ===="
if [ ${#FAILS[@]} -eq 0 ]; then
  echo "✔ Todas as remediações aplicadas com sucesso."
else
  echo "⚠️  Alguns alvos não foram totalmente remediados:"
  for f in "${FAILS[@]}"; do
    echo "   - $f"
  done
  echo
  echo "❗ Verifique os itens acima manualmente. Backup do fstab: $FSTAB_BKP"
fi
echo
echo "✔ Fim do script (verifique logs e teste reboot em ambiente controlado)"
exit 0