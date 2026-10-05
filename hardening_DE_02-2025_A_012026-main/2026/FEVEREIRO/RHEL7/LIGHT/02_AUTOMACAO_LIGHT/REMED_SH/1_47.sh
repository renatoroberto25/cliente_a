#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 15–24 (RHEL 7)"


# --- NOVO BLOCO: Remediações 1, 2, 3 e 9 (módulos kernel) ---

block_module() {
  local mod="$1"
  local conf="/etc/modprobe.d/${mod}.conf"
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"

  # Backup se existir
  if [ -f "$conf" ]; then
    cp -a "$conf" "${conf}.bkp_${ts}"
  fi

  # Bloqueio persistente
  # RHEL7: abordagem suportada é 'install <mod> /bin/true'
  {
    echo "# Hardened ${mod} - ${ts}"
    echo "install ${mod} /bin/true"
    # Opcionalmente manter blacklist para scanners que verificam essa chave:
    echo "blacklist ${mod}"
  } > "$conf"

  # Remoção em runtime (se carregado)
  if lsmod | awk '{print $1}' | grep -qx "${mod}"; then
    if ! rmmod "${mod}" 2>/dev/null; then
      echo " [WARN] ${mod} está em uso e não pôde ser removido agora"
    else
      echo " [OK] ${mod} removido (runtime)"
    fi
  fi

  echo " [OK] ${mod} bloqueado (persistente em ${conf})"
}

echo -e "\n[HARDENING] Remediações 1–3 e 9 (RHEL 7) - módulos kernel"

echo -e "\n[1] Bloquear cramfs"
block_module cramfs

echo -e "\n[2] Bloquear squashfs"
block_module squashfs

echo -e "\n[3] Bloquear udf"
block_module udf

echo -e "\n[9] Bloquear usb_storage"
block_module usb_storage

# --- ANTIGO BLOCO: Remediações 15 47 ---


SYSCTLFILE="/etc/sysctl.d/99-hardening.conf"

if [ -f "$SYSCTLFILE" ]; then
  cp -a "$SYSCTLFILE" "$SYSCTLFILE.bkp_$(date +%Y%m%d_%H%M%S)"
fi

touch "$SYSCTLFILE"

echo -e "\n[15] fs.suid_dumpable=0 persistente"
if sysctl -n fs.suid_dumpable >/dev/null 2>&1; then
  if grep -q '^fs.suid_dumpable' "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's|^fs\.suid_dumpable.*|fs.suid_dumpable = 0|' "$SYSCTLFILE"
  else
    echo "fs.suid_dumpable = 0" >> "$SYSCTLFILE"
  fi
  sysctl -w fs.suid_dumpable=0 >/dev/null 2>&1 || true
  echo " fs.suid_dumpable = 0"
else
  echo " fs.suid_dumpable não suportado neste kernel"
fi

echo -e "\n[16] Fora do escopo automático deste script"
echo " Ajuste conforme baseline HITSS"

echo -e "\n[17] Fora do escopo automático deste script"
echo " Ajuste conforme baseline HITSS"

echo -e "\n[18] ASLR completo (kernel.randomize_va_space=2)"
if sysctl -n kernel.randomize_va_space >/dev/null 2>&1; then
  if grep -q '^kernel.randomize_va_space' "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's|^kernel\.randomize_va_space.*|kernel.randomize_va_space = 2|' "$SYSCTLFILE"
  else
    echo "kernel.randomize_va_space = 2" >> "$SYSCTLFILE"
  fi
  sysctl -w kernel.randomize_va_space=2 >/dev/null 2>&1 || true
  echo " kernel.randomize_va_space = 2"
else
  echo " kernel.randomize_va_space não suportado neste kernel"
fi

echo -e "\n[19] Fora do escopo automático deste script"
echo " Ajuste conforme baseline HITSS"

echo -e "\n[20] perf_event_paranoid restritivo (3)"
if sysctl -n kernel.perf_event_paranoid >/dev/null 2>&1; then
  if grep -q '^kernel.perf_event_paranoid' "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's|^kernel\.perf_event_paranoid.*|kernel.perf_event_paranoid = 3|' "$SYSCTLFILE"
  else
    echo "kernel.perf_event_paranoid = 3" >> "$SYSCTLFILE"
  fi
  sysctl -w kernel.perf_event_paranoid=3 >/dev/null 2>&1 || true
  echo " kernel.perf_event_paranoid = 3"
else
  echo " kernel.perf_event_paranoid não suportado neste kernel"
fi

echo -e "\n[21] dmesg_restrict=1"
if sysctl -n kernel.dmesg_restrict >/dev/null 2>&1; then
  if grep -q '^kernel.dmesg_restrict' "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's|^kernel\.dmesg_restrict.*|kernel.dmesg_restrict = 1|' "$SYSCTLFILE"
  else
    echo "kernel.dmesg_restrict = 1" >> "$SYSCTLFILE"
  fi
  sysctl -w kernel.dmesg_restrict=1 >/dev/null 2>&1 || true
  echo " kernel.dmesg_restrict = 1"
else
  echo " kernel.dmesg_restrict não suportado neste kernel"
fi

echo -e "\n[22] Fora do escopo automático deste script"
echo " Ajuste conforme baseline HITSS"

echo -e "\n[23] fs.protected_symlinks=1"
if sysctl -n fs.protected_symlinks >/dev/null 2>&1; then
  if grep -q '^fs.protected_symlinks' "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's|^fs\.protected_symlinks.*|fs.protected_symlinks = 1|' "$SYSCTLFILE"
  else
    echo "fs.protected_symlinks = 1" >> "$SYSCTLFILE"
  fi
  sysctl -w fs.protected_symlinks=1 >/dev/null 2>&1 || true
  echo " fs.protected_symlinks = 1"
else
  echo " fs.protected_symlinks não suportado neste kernel"
fi

echo -e "\n[24] fs.protected_hardlinks=1"
if sysctl -n fs.protected_hardlinks >/dev/null 2>&1; then
  if grep -q '^fs.protected_hardlinks' "$SYSCTLFILE" 2>/dev/null; then
    sed -i 's|^fs\.protected_hardlinks.*|fs.protected_hardlinks = 1|' "$SYSCTLFILE"
  else
    echo "fs.protected_hardlinks = 1" >> "$SYSCTLFILE"
  fi
  sysctl -w fs.protected_hardlinks=1 >/dev/null 2>&1 || true
  echo " fs.protected_hardlinks = 1"
else
  echo " fs.protected_hardlinks não suportado neste kernel"
fi
