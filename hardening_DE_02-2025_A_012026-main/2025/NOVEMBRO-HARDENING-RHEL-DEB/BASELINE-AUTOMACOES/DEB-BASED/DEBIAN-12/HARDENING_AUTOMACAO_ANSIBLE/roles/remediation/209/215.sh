#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%Y%m%d%H%M%S)"
PASSWD="/etc/passwd"
GROUP="/etc/group"
SHADOW="/etc/shadow"

echo "[215] Remediar apenas root com UID 0"
bad_users="$(awk -F: '($3==0 && $1!="root"){print $1}' "$PASSWD")"
if [ -n "$bad_users" ]; then
  cp "$PASSWD" "$PASSWD.bak_$TS"
  for u in $bad_users; do
    # força UID != 0 (1000+) — precisa de política local, aqui setamos 1000+
    new_uid="$(awk -F: '($3>=1000){max=$3} END{print (max+1)}' "$PASSWD")"
    usermod -u "$new_uid" "$u"
  done
fi

echo "[216] Remediar apenas root com GID 0"
bad_gid_users="$(awk -F: '($4==0 && $1!~/^(root|sync|shutdown|halt|operator)$/){print $1}' "$PASSWD")"
if [ -n "$bad_gid_users" ]; then
  cp "$PASSWD" "$PASSWD.bak_$TS"
  for u in $bad_gid_users; do
    usermod -g 1 "$u"   # move para 'daemon' (ou outro GID != 0 conforme política)
  done
fi

echo "[217] Remediar apenas grupo root com GID 0"
bad_groups="$(awk -F: '($3==0 && $1!="root"){print $1}' "$GROUP")"
if [ -n "$bad_groups" ]; then
  cp "$GROUP" "$GROUP.bak_$TS"
  for g in $bad_groups; do
    groupmod -g 1 "$g"   # altera GID para algo ≠ 0
  done
fi

echo "[218] Remediar senha da conta root (definida ou bloqueada)"
status="$(passwd -S root | awk '{print $2}')"
if ! [[ "$status" =~ ^(P|L)$ ]]; then
  cp "$SHADOW" "$SHADOW.bak_$TS"
  passwd -l root   # bloqueia root se não tiver senha definida
fi

echo "[219] Remediar integridade do PATH do root"
root_path="$(sudo -Hiu root env | grep '^PATH=' | cut -d= -f2)"
# remove :: , . , entradas vazias
if echo "$root_path" | grep -Eq '(^|:)(:|\.(:|$))'; then
  file="/root/.bash_profile"
  cp "$file" "$file.bak_$TS"
  sed -ri 's#(^PATH=.*)(:|\.\:?)(.*)#\1\3#' "$file"
fi

echo "[220] Remediar umask do root (027)"
TS="$(date +%Y%m%d_%H%M%S)"
files="/root/.bashrc /root/.bash_profile"
ok=0

for f in $files; do
  if [ -f "$f" ] && grep -Pi '^\s*umask\s+(027|077)\b' "$f" >/dev/null 2>&1; then
    ok=1
  fi
done

if [ $ok -eq 0 ]; then
  f="/root/.bashrc"
  cp "$f" "$f.bak_$TS"
  echo "umask 027" >> "$f"
  echo "  Ajustado: umask 027 incluído em $f"
else
  echo "  OK: umask já configurada"
fi
