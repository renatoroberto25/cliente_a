#!/usr/bin/env bash
echo "[210–215] Reforço de segurança de contas e ambiente de login"

# [210] Secure system accounts
echo "[210] Bloquear contas de sistema e definir shell nologin"
awk -F: '($1!="root" && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false") {print $1}' /etc/passwd | while read -r user; do
  if [[ -n "$user" ]]; then
    chsh -s /sbin/nologin "$user" 2>/dev/null
    usermod -L "$user" 2>/dev/null
    echo "✅ $user bloqueado e shell definido como /sbin/nologin"
  fi
done

# [211] Root GID = 0
echo "[211] Garantir que o grupo padrão do root é GID 0"
gid=$(grep "^root:" /etc/passwd | cut -d: -f4)
if [[ "$gid" != "0" ]]; then
  usermod -g 0 root && echo "✅ root ajustado para GID 0"
else
  echo "ℹ️ root já está com GID 0"
fi

# [212] TMOUT ≤ 900
echo "[212] Configurar TMOUT global para 900 segundos"
file="/etc/profile.d/tmout.sh"
if [[ ! -f "$file" ]]; then
  echo "TMOUT=900" > "$file"
  echo "readonly TMOUT" >> "$file"
  echo "export TMOUT" >> "$file"
  chmod 644 "$file"
  echo "✅ TMOUT criado em $file"
else
  if grep -q "TMOUT=900" "$file"; then
    echo "ℹ️ TMOUT já configurado corretamente"
  else
    cp -p "$file" "${file}.bak.$(date +%F_%H%M%S)"
    sed -i 's/^TMOUT=.*/TMOUT=900/' "$file"
    echo "✅ TMOUT atualizado em $file"
  fi
fi

# [214] Root console restriction
echo "[214] Restringir login root à console e tty1"
cp -p /etc/securetty /etc/securetty.bak.$(date +%F_%H%M%S) 2>/dev/null
cat <<EOF > /etc/securetty
console
tty1
EOF
chmod 600 /etc/securetty
echo "✅ /etc/securetty restrito a console e tty1"

# [215] Restringir uso do comando su a grupo dedicado
echo "[215] Restringir uso do comando su a grupo dedicado"
groupadd -f sugroup
if ! grep -Eq '^auth\s+(required|requisite)\s+pam_wheel\.so' /etc/pam.d/su; then
  cp -p /etc/pam.d/su /etc/pam.d/su.bak.$(date +%F_%H%M%S)
  sed -i '/pam_rootok.so/a auth required pam_wheel.so use_uid group=sugroup' /etc/pam.d/su
  echo "✅ Restrição de su adicionada após pam_rootok.so"
else
  echo "ℹ️ Restrição pam_wheel já presente"
fi


echo "[ℹ️ FIM]"
exit 0