#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d%H%M%S)"
LD="/etc/login.defs"
SHADOW="/etc/shadow"
USERADD="/etc/default/useradd"

echo "[209] Remediar PASS_MAX_DAYS ≤ 365"
if ! awk '/^\s*PASS_MAX_DAYS/{if($2<=365&&$2>0)exit 0;else exit 1}' "$LD" >/dev/null; then
  cp "$LD" "$LD.bak_$TS"
  if grep -q 'PASS_MAX_DAYS' "$LD"; then
    sed -ri 's/^\s*PASS_MAX_DAYS\s+.*/PASS_MAX_DAYS   365/' "$LD"
  else
    echo "PASS_MAX_DAYS   365" >> "$LD"
  fi
fi

echo "[210] Remediar PASS_MIN_DAYS ≥ 1"
if ! awk '/^\s*PASS_MIN_DAYS/{if($2>=1)exit 0;else exit 1}' "$LD" >/dev/null; then
  cp "$LD" "$LD.bak_$TS"
  if grep -q 'PASS_MIN_DAYS' "$LD"; then
    sed -ri 's/^\s*PASS_MIN_DAYS\s+.*/PASS_MIN_DAYS   1/' "$LD"
  else
    echo "PASS_MIN_DAYS   1" >> "$LD"
  fi
fi

echo "[211] Remediar PASS_WARN_AGE ≥ 7"
if ! awk '/^\s*PASS_WARN_AGE/{if($2>=7)exit 0;else exit 1}' "$LD" >/dev/null; then
  cp "$LD" "$LD.bak_$TS"
  if grep -q 'PASS_WARN_AGE' "$LD"; then
    sed -ri 's/^\s*PASS_WARN_AGE\s+.*/PASS_WARN_AGE   7/' "$LD"
  else
    echo "PASS_WARN_AGE   7" >> "$LD"
  fi
fi

echo "[212] Remediar algoritmo de hashing (sha512/yescrypt)"
if ! grep -Pi '^\s*ENCRYPT_METHOD\s+(SHA512|YESCRYPT)\b' "$LD" >/dev/null; then
  cp "$LD" "$LD.bak_$TS"
  if grep -q 'ENCRYPT_METHOD' "$LD"; then
    sed -ri 's/^\s*ENCRYPT_METHOD\s+.*/ENCRYPT_METHOD SHA512/' "$LD"
  else
    echo "ENCRYPT_METHOD SHA512" >> "$LD"
  fi
fi

echo "[213] Remediar INACTIVE ≤ 45"
inactive="$(useradd -D | awk -F= '/INACTIVE=/{print $2}')"
if [ -z "$inactive" ] || [ "$inactive" -gt 45 ] || [ "$inactive" -lt 0 ]; then
  cp "$USERADD" "$USERADD.bak_$TS"
  if grep -q '^INACTIVE=' "$USERADD"; then
    sed -ri 's/^INACTIVE=.*/INACTIVE=30/' "$USERADD"
  else
    echo "INACTIVE=30" >> "$USERADD"
  fi
fi

echo "[214] Remediar últimas alterações de senha futuras/ausentes"
today_days="$(( $(date +%s) / 86400 ))"
awk -F: -v today="$today_days" '$2~/^\$/ && ($3=="" || $3==0 || $3>today){print $1}' "$SHADOW" | while read -r user; do
  if [ -n "$user" ]; then
    chage -d 0 "$user"
  fi
done