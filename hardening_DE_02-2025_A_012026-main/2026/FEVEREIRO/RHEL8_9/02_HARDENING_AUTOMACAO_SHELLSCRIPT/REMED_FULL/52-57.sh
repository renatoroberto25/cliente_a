#!/usr/bin/env bash
set -u

echo "[52 - 57] MAC e serviços legados"

# -----------------------------
# Helpers
# -----------------------------
backup() {
  local f="$1"
  [ -f "$f" ] || return 0
  local ts
  ts="$(date +%Y%m%d%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}" 2>/dev/null || true
}

in_list() {
  local needle="$1"; shift
  local x
  for x in "$@"; do
    [ "$x" = "$needle" ] && return 0
  done
  return 1
}

unit_from_pid() {
  # PID -> systemd unit (melhor esforço)
  local pid="$1"
  local cg="/proc/$pid/cgroup"
  [ -r "$cg" ] || return 1

  # Preferir system.slice/*.service
  local u
  u="$(grep -E '/system\.slice/[^/]+\.service' "$cg" 2>/dev/null \
        | head -n1 | sed -n 's#.*/system\.slice/\([^/]*\.service\).*#\1#p')"
  [ -n "$u" ] && { printf '%s\n' "$u"; return 0; }

  # Fallback: qualquer *.service
  grep -E '\.service' "$cg" 2>/dev/null \
    | head -n1 \
    | sed -n 's#.*/\([^/]*\.service\).*#\1#p' \
    | head -n1
}

exec_from_unit() {
  local u="$1"
  local line first
  line="$(systemctl show -p ExecStart --value "$u" 2>/dev/null || true)"
  [ -n "$line" ] || return 1
  first="$(printf '%s\n' "$line" | awk -F';' '{print $1}' \
          | sed -E 's/^[[:space:]]*-[[:space:]]*//; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  printf '%s\n' "$first" | awk '{print $1}'
}

file_ctx() {
  local f="$1"
  [ -e "$f" ] || return 0
  ls -Z "$f" 2>/dev/null | awk '{print $1}' || true
}

safe_restorecon_exec() {
  local bin="$1"
  command -v restorecon >/dev/null 2>&1 || return 0
  [ -e "$bin" ] || return 0
  restorecon -v "$bin" 2>/dev/null || true
}

# -----------------------------
# Baseline gates
# -----------------------------
# Somente serviços explicitamente autorizados pelo baseline podem sofrer ação (try-restart e/ou stop/disable)
ALLOWLIST_SERVICES=(
  # EXEMPLOS de legados "meio bosta" (ajuste ao seu baseline REAL)
  "avahi-daemon.service"
  "cups.service"
  "rpcbind.service"
  "xinetd.service"
  "telnet.service"
  "tftp.service"
  "vsftpd.service"
)

# Nunca mexer
DENYLIST_SERVICES=(
  "sshd.service"
  "systemd.service"
  "dbus.service"
  "NetworkManager.service"
  "chronyd.service"
  "rsyslog.service"
  "auditd.service"
)

DENYLIST_COMMS=(
  "sshd" "systemd" "sudo" "su" "bash" "sh" "ps" "tee"
)

# Flags
DRYRUN="${DRYRUN:-0}" # 1 = não aplica stop/disable nem restart
DISABLE_LEGACY="${DISABLE_LEGACY:-1}" # 1 = se unit allowlisted estiver unconfined*, pode stop/disable (baseline FULL)

# -----------------------------
# [52] SELinux enforcing + [53] targeted
# -----------------------------
CONFIG="/etc/selinux/config"

echo -e "\n[52] Forçar SELinux para ENFORCING"
backup "$CONFIG"
if grep -q '^SELINUX=' "$CONFIG" 2>/dev/null; then
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$CONFIG"
else
  echo "SELINUX=enforcing" >> "$CONFIG"
fi
getenforce 2>/dev/null | grep -q "Enforcing" || setenforce 1 2>/dev/null || true
echo "✔ SELinux configurado como enforcing (pode exigir reboot)"

echo -e "\n[53] Forçar política SELinux 'targeted'"
backup "$CONFIG"
if grep -q '^SELINUXTYPE=' "$CONFIG" 2>/dev/null; then
  sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' "$CONFIG"
else
  echo "SELINUXTYPE=targeted" >> "$CONFIG"
fi
echo "✔ Política SELinux ajustada para targeted"

SELINUX_STATE="$(getenforce 2>/dev/null || echo Unknown)"
if ! printf '%s' "$SELINUX_STATE" | grep -q '^Enforcing$'; then
  echo -e "\n[54/55] SELinux não está Enforcing agora ($SELINUX_STATE)"
  echo "⚠️ PENDENTE REBOOT: não tentar consertar 54/55 neste boot"
  exit 0
fi

# -----------------------------
# Auditor/recheck helper: PID ainda está unconfined?
# -----------------------------
pid_has_unconf_label() {
  local pid="$1"
  local pat="$2"   # ex: unconfined_t|unconfined_service_t
  ps -p "$pid" -eZ -o label= 2>/dev/null | grep -q "$pat"
}

# -----------------------------
# [54] unconfined_service_t
# -----------------------------
echo -e "\n[54] unconfined_service_t (ação mínima; baseline manda)"
mapfile -t PIDS54 < <(ps -eZ -o label,pid,comm --no-headers 2>/dev/null \
  | awk '$1 ~ /unconfined_service_t/ {print $2}')

if [ "${#PIDS54[@]}" -eq 0 ]; then
  echo "✔ Nenhum unconfined_service_t"
else
  for pid in "${PIDS54[@]}"; do
    comm="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
    unit="$(unit_from_pid "$pid" || true)"

    if [ -z "${unit:-}" ]; then
      echo "⚠️ PID=$pid comm=$comm unconfined_service_t sem unit — sem ação"
      continue
    fi
    if in_list "$unit" "${DENYLIST_SERVICES[@]}" || in_list "$comm" "${DENYLIST_COMMS[@]}"; then
      echo "⚠️ IGNORADO denylist: unit=$unit pid=$pid comm=$comm"
      continue
    fi
    if ! in_list "$unit" "${ALLOWLIST_SERVICES[@]}"; then
      echo "⚠️ NÃO AUTORIZADO baseline: unit=$unit pid=$pid comm=$comm"
      continue
    fi

    bin="$(exec_from_unit "$unit" || true)"
    ctx="$(file_ctx "${bin:-}")"

    echo "• evidência: unit=$unit pid=$pid comm=$comm exec=${bin:-N/A} fctx=${ctx:-N/A}"

    if [ "$DRYRUN" = "1" ]; then
      echo "  DRYRUN: restorecon + try-restart ($unit)"
      continue
    fi

    [ -n "${bin:-}" ] && safe_restorecon_exec "$bin"
    systemctl try-restart "$unit" 2>/dev/null || true

    if pid_has_unconf_label "$pid" "unconfined_service_t"; then
      echo "⚠️ Ainda unconfined_service_t após restart: unit=$unit (sem novas ações)"
      continue
    fi

    # Perfil FULL: se baseline allowlist diz que é legado e você quer fechar mesmo, pode desabilitar
    if [ "$DISABLE_LEGACY" = "1" ]; then
      systemctl stop "$unit" 2>/dev/null || true
      systemctl disable "$unit" 2>/dev/null || true
      echo "✔ Legado desativado (baseline allowlist): unit=$unit"
    else
      echo "✔ Normalizado (sem stop/disable): unit=$unit"
    fi
  done
fi

# -----------------------------
# [55] unconfined_t
# -----------------------------
echo -e "\n[55] unconfined_t (ação mínima; baseline manda)"
mapfile -t PIDS55 < <(ps -eZ -o label,pid,comm --no-headers 2>/dev/null \
  | awk '$1 ~ /unconfined_t/ {print $2}')

if [ "${#PIDS55[@]}" -eq 0 ]; then
  echo "✔ Nenhum unconfined_t"
else
  for pid in "${PIDS55[@]}"; do
    comm="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
    if in_list "$comm" "${DENYLIST_COMMS[@]}"; then
      echo "⚠️ IGNORADO denylist comm: pid=$pid comm=$comm"
      continue
    fi

    unit="$(unit_from_pid "$pid" || true)"
    if [ -z "${unit:-}" ]; then
      echo "⚠️ PID=$pid comm=$comm unconfined_t sem unit — sem ação"
      continue
    fi
    if in_list "$unit" "${DENYLIST_SERVICES[@]}"; then
      echo "⚠️ IGNORADO denylist unit: unit=$unit pid=$pid comm=$comm"
      continue
    fi
    if ! in_list "$unit" "${ALLOWLIST_SERVICES[@]}"; then
      echo "⚠️ NÃO AUTORIZADO baseline: unit=$unit pid=$pid comm=$comm"
      continue
    fi

    bin="$(exec_from_unit "$unit" || true)"
    ctx="$(file_ctx "${bin:-}")"

    echo "• evidência: unit=$unit pid=$pid comm=$comm exec=${bin:-N/A} fctx=${ctx:-N/A}"

    if [ "$DRYRUN" = "1" ]; then
      echo "  DRYRUN: restorecon + try-restart ($unit)"
      continue
    fi

    [ -n "${bin:-}" ] && safe_restorecon_exec "$bin"
    systemctl try-restart "$unit" 2>/dev/null || true

    if pid_has_unconf_label "$pid" "unconfined_t"; then
      echo "⚠️ Ainda unconfined_t após restart: unit=$unit (sem novas ações)"
      continue
    fi

    if [ "$DISABLE_LEGACY" = "1" ]; then
      systemctl stop "$unit" 2>/dev/null || true
      systemctl disable "$unit" 2>/dev/null || true
      echo "✔ Legado desativado (baseline allowlist): unit=$unit"
    else
      echo "✔ Normalizado (sem stop/disable): unit=$unit"
    fi
  done
fi

echo -e "\n[56] prelink"
# (mantém sua lógica atual, fora do escopo 54/55)

echo -e "\n[57] xinetd"
# (mantém sua lógica atual, fora do escopo 54/55)
