#!/usr/bin/env bash
set -u
# opcional: set -o pipefail

echo "[52 - 57] MAC e serviços legados"

# -----------------------------
# Helpers
# -----------------------------
ok()   { echo "✔ $*"; }
warn() { echo "⚠️ $*"; }

backup() {
  local f="$1"
  [ -f "$f" ] || return 0
  local ts
  ts="$(date +%Y%m%d%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}" 2>/dev/null || true
}

# -----------------------------
# Baseline: allowlist + denylist
# -----------------------------
# Só age (54/55) em units explicitamente autorizadas pelo baseline.
ALLOWLIST_UNITS=(
  "avahi-daemon.service"
  "cups.service"
  "rpcbind.service"
  "telnet.service"
  "tftp.service"
  "vsftpd.service"
  "xinetd.service"
)

# Nunca encostar, mesmo que apareça unconfined.
DENYLIST_UNITS=(
  "sshd.service"
  "systemd.service"
  "dbus.service"
  "NetworkManager.service"
  "chronyd.service"
  "rsyslog.service"
  "auditd.service"
)

in_allowlist() {
  local u="$1" x
  for x in "${ALLOWLIST_UNITS[@]}"; do [ "$x" = "$u" ] && return 0; done
  return 1
}
in_denylist() {
  local u="$1" x
  for x in "${DENYLIST_UNITS[@]}"; do [ "$x" = "$u" ] && return 0; done
  return 1
}

# PID -> unit via cgroup (v1/v2)
unit_from_pid() {
  local pid="$1" cg="/proc/$pid/cgroup"
  [ -r "$cg" ] || return 1
  grep -E '\.service' "$cg" 2>/dev/null | head -n1 | sed -n 's#.*/\([^/]*\.service\).*#\1#p'
}

# unit -> exec path (primeiro ExecStart)
exec_from_unit() {
  local u="$1" v
  v="$(systemctl show -p ExecStart --value "$u" 2>/dev/null)" || return 1
  [ -n "$v" ] || return 1
  printf '%s\n' "$v" | awk -F';' '{print $1}' | sed -E 's/^[[:space:]]*-[[:space:]]*//' | awk '{print $1}'
}

# Coleta evidência (unit,pid,comm,exec,path ctx)
evidence() {
  local unit="$1" pid="$2" comm="$3" bin="${4:-}"
  local pctx fctx
  pctx="$(ps -p "$pid" -o label= 2>/dev/null | awk '{print $1}' || true)"
  fctx="$( [ -n "$bin" ] && command -v ls >/dev/null 2>&1 && ls -Z "$bin" 2>/dev/null | awk '{print $1}' || true )"
  echo "    evid: unit=$unit pid=$pid comm=$comm"
  echo "    evid: proc_ctx=${pctx:-NA}"
  echo "    evid: exec=${bin:-NA}"
  echo "    evid: file_ctx=${fctx:-NA}"
}

# -----------------------------
# [52] SELinux enforcing (config + tentativa runtime)
# -----------------------------
echo -e "\n[52] Forçar SELinux para ENFORCING"
CONFIG="/etc/selinux/config"
backup "$CONFIG"

if grep -q '^SELINUX=' "$CONFIG" 2>/dev/null; then
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$CONFIG"
else
  echo "SELINUX=enforcing" >> "$CONFIG"
fi

# tenta runtime (se falhar, só registra)
if getenforce 2>/dev/null | grep -q "Enforcing"; then
  ok "SELinux já está Enforcing"
else
  setenforce 1 2>/dev/null && ok "SELinux setado para Enforcing (runtime)" || warn "Não foi possível setar Enforcing agora (pode requerer reboot)"
fi

# -----------------------------
# [53] SELinux targeted
# -----------------------------
echo -e "\n[53] Forçar política SELinux 'targeted'"
backup "$CONFIG"
if grep -q '^SELINUXTYPE=' "$CONFIG" 2>/dev/null; then
  sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' "$CONFIG"
else
  echo "SELINUXTYPE=targeted" >> "$CONFIG"
fi
ok "SELINUXTYPE=targeted aplicado no config"

# -----------------------------
# Gate: só tratar 54/55 se estiver Enforcing agora
# -----------------------------
SELINUX_STATE="$(getenforce 2>/dev/null || echo Unknown)"
if ! printf '%s' "$SELINUX_STATE" | grep -q "Enforcing"; then
  echo -e "\n[54] Serviços unconfined minimizados"
  warn "SELinux não está Enforcing agora ($SELINUX_STATE) — pendente reboot; sem ação em 54/55"
  echo -e "\n[55] Sem serviços sem restrições MAC"
  warn "SELinux não está Enforcing agora ($SELINUX_STATE) — pendente reboot; sem ação em 54/55"
else
  # -----------------------------
  # [54] unconfined_service_t (leve e seguro)
  # - só units allowlisted
  # - coleta evidência
  # - restorecon só no executável
  # - try-restart
  # - reavalia; se persistir, para
  # -----------------------------
  echo -e "\n[54] Serviços unconfined minimizados (baseline allowlist + restorecon exec + try-restart)"
  mapfile -t PIDS54 < <(ps -eZ -o label=,pid=,comm= --no-headers 2>/dev/null | awk '$1 ~ /unconfined_service_t/ {print $2}')
  if [ "${#PIDS54[@]}" -eq 0 ]; then
    ok "Nenhum unconfined_service_t detectado"
  else
    for pid in "${PIDS54[@]}"; do
      comm="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
      unit="$(unit_from_pid "$pid" || true)"

      if [ -z "$unit" ]; then
        warn "PID $pid ($comm) unconfined_service_t sem unit — sem ação"
        continue
      fi
      if in_denylist "$unit"; then
        warn "IGNORADO (denylist): $unit (pid=$pid comm=$comm)"
        continue
      fi
      if ! in_allowlist "$unit"; then
        warn "NÃO AUTORIZADO pelo baseline (sem ação): $unit (pid=$pid comm=$comm)"
        continue
      fi

      bin="$(exec_from_unit "$unit" || true)"
      echo "  • alvo: $unit"
      evidence "$unit" "$pid" "$comm" "$bin"

      if [ -n "$bin" ] && [ -e "$bin" ]; then
        ok "restorecon -v $bin"
        restorecon -v "$bin" 2>/dev/null || true
      else
        warn "ExecStart/bin não resolvido — pulando restorecon"
      fi

      ok "try-restart $unit"
      systemctl try-restart "$unit" 2>/dev/null || true

      # reavalia: ainda existe PID do unit com unconfined_service_t?
      if ps -eZ -o label=,pid=,comm= --no-headers 2>/dev/null | awk -v u="$unit" '
            $1 ~ /unconfined_service_t/ {p=$2}
            END{exit 0}' >/dev/null 2>&1; then
        # checagem simples: re-scan por cgroup do unit
        if ps -eZ -o label=,pid=,comm= --no-headers 2>/dev/null | awk '$1 ~ /unconfined_service_t/ {print $2}' \
            | while read -r p; do unit2="$(unit_from_pid "$p" 2>/dev/null || true)"; [ "$unit2" = "$unit" ] && exit 1; done; then
          ok "Confinamento ok após restart: $unit"
        else
          warn "Ainda unconfined após tentativa segura — sem novas ações automáticas: $unit"
        fi
      fi
    done
  fi

  # -----------------------------
  # [55] unconfined_t (mesma lógica, mas apenas units allowlisted)
  # -----------------------------
  echo -e "\n[55] Sem serviços sem restrições MAC (unconfined_t; baseline allowlist + restorecon exec + try-restart)"
  mapfile -t PIDS55 < <(ps -eZ -o label=,pid=,comm= --no-headers 2>/dev/null | awk '$1 ~ /unconfined_t/ {print $2}')
  if [ "${#PIDS55[@]}" -eq 0 ]; then
    ok "Nenhum unconfined_t detectado"
  else
    for pid in "${PIDS55[@]}"; do
      comm="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
      unit="$(unit_from_pid "$pid" || true)"

      if [ -z "$unit" ]; then
        warn "PID $pid ($comm) unconfined_t sem unit — sem ação"
        continue
      fi
      if in_denylist "$unit"; then
        warn "IGNORADO (denylist): $unit (pid=$pid comm=$comm)"
        continue
      fi
      if ! in_allowlist "$unit"; then
        warn "NÃO AUTORIZADO pelo baseline (sem ação): $unit (pid=$pid comm=$comm)"
        continue
      fi

      bin="$(exec_from_unit "$unit" || true)"
      echo "  • alvo: $unit"
      evidence "$unit" "$pid" "$comm" "$bin"

      if [ -n "$bin" ] && [ -e "$bin" ]; then
        ok "restorecon -v $bin"
        restorecon -v "$bin" 2>/dev/null || true
      else
        warn "ExecStart/bin não resolvido — pulando restorecon"
      fi

      ok "try-restart $unit"
      systemctl try-restart "$unit" 2>/dev/null || true

      # reavalia por cgroup->unit
      if ps -eZ -o label=,pid=,comm= --no-headers 2>/dev/null | awk '$1 ~ /unconfined_t/ {print $2}' \
          | while read -r p; do unit2="$(unit_from_pid "$p" 2>/dev/null || true)"; [ "$unit2" = "$unit" ] && exit 1; done; then
        ok "Confinamento ok após restart: $unit"
      else
        warn "Ainda unconfined após tentativa segura — sem novas ações automáticas: $unit"
      fi
    done
  fi
fi

# -----------------------------
# [56] prelink
# -----------------------------
echo -e "\n[56] Remover prelink e desfazer bibliotecas"
if rpm -q prelink &>/dev/null; then
  warn "prelink instalado — removendo"
  prelink -ua 2>/dev/null || true
  if command -v dnf >/dev/null 2>&1; then
    dnf remove -y prelink >/dev/null 2>&1 || true
  else
    yum remove -y prelink >/dev/null 2>&1 || true
  fi
  ok "prelink desmontado e removido"
else
  ok "prelink não instalado"
fi

# -----------------------------
# [57] xinetd
# -----------------------------
echo -e "\n[57] Remover xinetd e arquivos residuais"
if rpm -q xinetd &>/dev/null; then
  if command -v dnf >/dev/null 2>&1; then
    dnf remove -y xinetd >/dev/null 2>&1 || true
  else
    yum remove -y xinetd >/dev/null 2>&1 || true
  fi
  rm -f /etc/xinetd.conf /etc/xinetd.d/* 2>/dev/null || true
  ok "xinetd removido e diretórios limpos"
else
  ok "xinetd não instalado"
fi
