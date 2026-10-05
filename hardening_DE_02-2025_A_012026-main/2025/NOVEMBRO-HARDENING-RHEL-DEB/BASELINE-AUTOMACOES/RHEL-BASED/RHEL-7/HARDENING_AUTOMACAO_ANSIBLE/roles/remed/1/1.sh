#!/usr/bin/env bash

set -euo pipefail

BK_DIR="/var/backups/hardening_modprobe"
TS="$(date +%F_%H%M%S)"
mkdir -p "$BK_DIR"

info(){ printf "\n[INFO] %s\n" "$*"; }
ok(){ printf "[OK] %s\n" "$*"; }
warn(){ printf "[WARN] %s\n" "$*"; }
note(){ printf "[NOTE] %s\n" "$*"; }

# helper: safe append of a line to conf if not already present (word boundary)
append_if_missing(){
  local conf="$1"; shift
  local line="$*"
  grep -Pq -- "\b$(echo "$line" | sed -E 's/[^[:alnum:]]+/\\W/g')" "$conf" 2>/dev/null || {
    printf '%s\n' "$line" >> "$conf"
    ok "Adicionado em $conf: $line"
  }
}

# helper: write or create conf safely with backup
ensure_conf_and_append(){
  local mod="$1"; shift
  local conf="/etc/modprobe.d/${mod}.conf"
  if [ -f "$conf" ]; then
    cp -a "$conf" "$BK_DIR/$(basename $conf).bak_$TS"
    ok "Backup $conf -> $BK_DIR/$(basename $conf).bak_$TS"
  fi
  touch "$conf"
  chmod 0644 "$conf"
  append_if_missing "$conf" "$*"
}

# Function: remediate a module (install /bin/false + blacklist) - idempotent
remediate_module(){
  local l_mod="$1"
  info "Remediando módulo: $l_mod"

  # Check current compliance (matches seu audit check)
  if ( (modinfo "$l_mod" &>/dev/null \
       && (modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+'${l_mod//-/_}'\b') \
       && ! lsmod | grep -q "^${l_mod}\b" ) \
      || (! modinfo "$l_mod" &>/dev/null) ); then
    ok "Módulo \"$l_mod\" já está desativado corretamente. Nenhuma ação necessária."
    return 0
  fi

  # locate module base dirs (safe fallback)
  local mod_dirs
  mod_dirs="$(find /lib/modules -maxdepth 3 -type d -name 'kernel' -print 2>/dev/null || true)"
  [ -z "$mod_dirs" ] && mod_dirs="/lib/modules"

  local actions=()

  # try unloading if loaded
  if lsmod | grep -q "^${l_mod}\b"; then
    actions+=(" - descarregando módulo: $l_mod")
    modprobe -r "$l_mod" 2>/dev/null || rmmod "$l_mod" 2>/dev/null || true
  fi

  # ensure conf and add install/blacklist lines idempotently
  # use /bin/false (mais explícito) — compatível com tua preferência
  ensure_conf_and_append "$l_mod" "install ${l_mod} /bin/false"
  ensure_conf_and_append "$l_mod" "blacklist ${l_mod}"

  # final check and report
  if ( (modinfo "$l_mod" &>/dev/null \
         && (modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+'${l_mod//-/_}'\b') \
         && ! lsmod | grep -q "^${l_mod}\b" ) \
       || (! modinfo "$l_mod" &>/dev/null) ); then
    ok "Remediação concluída para $l_mod -> ✅ APROVADO (verificação audit match)."
    return 0
  else
    warn "Remediação aplicada para $l_mod, mas verificação final falhou -> ⚠️ REPROVADO (verificar manualmente)"
    return 1
  fi
}

# MODULE LIST (aplica somente o que está no escopo)
MODULES_TO_HANDLE=(cramfs squashfs udf usb-storage usb_storage)

for m in "${MODULES_TO_HANDLE[@]}"; do
  # for usb we might run twice for underscore/dash variants; remediate_module handles idempotence
  remediate_module "$m" || true
done

# Sticky bit: aplicar onde faltar (idempotente)
info "Garantindo sticky bit (+t) em diretórios world-writable (idempotente)"
df --local -P | awk 'NR!=1 {print $6}' | xargs -r -I '{}' find '{}' -xdev -type d -perm -0002 -a ! -perm -1000 -exec chmod +t {} + 2>/dev/null || true
if df --local -P | awk 'NR!=1 {print $6}' | xargs -r -I '{}' find '{}' -xdev -type d -perm -0002 -a ! -perm -1000 -print 2>/dev/null | grep -q .; then
  warn "Existem diretórios world-writable sem sticky bit — verifique manualmente"
else
  ok "Sticky bit aplicado onde necessário -> ✅ APROVADO"
fi

# Disable autofs if present (safe, reversible)
info "Desabilitar autofs se presente (safe)"
if systemctl list-unit-files | grep -q '^autofs'; then
  systemctl disable --now autofs 2>/dev/null || warn "Não foi possível desabilitar autofs sem erro (verificar)"
  if systemctl is-enabled autofs &>/dev/null; then
    warn "autofs ainda habilitado (verificar)"
  else
    ok "autofs desabilitado -> ✅ APROVADO"
  fi
else
  ok "autofs não presente -> ✅ APROVADO"
fi

# Guidance (não executa alterações estruturais)
cat <<'EOF'

[GUIDANCE] Particionamento e opções de montagem — NENHUMA alteração estrutural foi executada.
Se precisar que o audit reporte "APROVADO" nestes pontos, siga esta orientação manual e segura:

  /tmp       -> nodev,nosuid,noexec  (aplicar somente se /tmp for mountpoint separado)
  /dev/shm   -> nodev,nosuid,noexec  (prefer tmpfs; remount+fstab)
  /var/tmp   -> nodev,nosuid,noexec  (aplicar somente se for partição separada)
  /home      -> nodev                (aplicar somente se for partição separada)
  /var       -> nodev,nosuid         (migração manual com janela)
  /var/log   -> nodev,nosuid,noexec  (migração manual com janela)
  /var/log/audit -> nodev,nosuid,noexec (migração manual com janela)

Exemplo (testar remount antes de persistir):
  sudo mount -o remount,noexec,nodev,nosuid /tmp
  # Se OK:
  sudo cp /etc/fstab /etc/fstab.bak.$TS
  # Adicionar ou ajustar linha /tmp em /etc/fstab com options
  # THEN sudo mount -a

Nota: Não criamos entradas em /etc/fstab para dispositivos removíveis por padrão.
Se realmente quiser bloquear montagem kernel-side (impacto: impede uso legítimo), faça manual ou via Ansible com backups.

Backups de confs criados em: ${BK_DIR}  (timestamp: ${TS})

EOF

exit 0