#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d%H%M%S)"
PASSWD="/etc/passwd"
SHELLS="/etc/shells"

echo "[221] Remediar contas de sistema sem shell válido"
uid_min="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"
[ -z "$uid_min" ] && uid_min=1000
bad_users="$(awk -F: -v umin="$uid_min" '($3<umin && $1!~/^(root|halt|sync|shutdown|nfsnobody)$/ && $7!~/nologin$/){print $1}' "$PASSWD")"
if [ -n "$bad_users" ]; then
  cp "$PASSWD" "$PASSWD.bak_$TS"
  for u in $bad_users; do
    usermod -s /usr/sbin/nologin "$u"
  done
fi

echo "[222] Remediar contas sem shell válido mas não bloqueadas"
TS="$(date +%Y%m%d_%H%M%S)"
PASSWD="/etc/passwd"

awk -F: '($7~/nologin$|false$/ && $1!="root"){print $1}' "$PASSWD" | while read -r u; do
  if [ -n "$u" ]; then
    status="$(passwd -S "$u" 2>/dev/null | awk '{print $2}')"
    if [ "$status" != "L" ]; then
      cp /etc/shadow /etc/shadow.bak_"$TS"
      passwd -l "$u"
      echo "  Conta $u bloqueada"
    fi
  fi
done

echo "[223] Remediar /etc/shells sem /nologin"
if grep -Eq '^[^#].*/nologin' "$SHELLS"; then
  cp "$SHELLS" "$SHELLS.bak_$TS"
  sed -ri '/nologin/d' "$SHELLS"
fi

echo "[224] Remediar TMOUT <= 900 configurado, readonly e exportado"
files=("/etc/profile" "/etc/bashrc")
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  if ! grep -Pq '^\s*TMOUT=(900|[1-8][0-9]{2}|[1-9][0-9]?)\b' "$f"; then
    cp "$f" "$f.bak_$TS"
    echo "TMOUT=900" >> "$f"
    echo "readonly TMOUT" >> "$f"
    echo "export TMOUT" >> "$f"
  fi
done

echo "[225] Remediar umask padrão 027"
files=("/etc/profile" "/etc/bashrc" "/etc/login.defs")
ok=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  if grep -Pq '^\s*umask\s+0?27\b' "$f"; then
    ok=1
  fi
done
if [ $ok -eq 0 ]; then
  f="/etc/profile"
  cp "$f" "$f.bak_$TS"
  echo "umask 027" >> "$f"
fi