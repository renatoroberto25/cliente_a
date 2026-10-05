#!/usr/bin/env bash
echo "HITSS Audit - Tópicos 160 a 169"

echo -e "\n [160] Certifique-se de que o sudo esteja instalado"
(command -v sudo &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [161] Garantir que os comandos sudo usem pty"
( grep -RsiP --exclude='*.bak*' --exclude='*~' --exclude='*.rpm*' '^\s*Defaults(?:\s+[^#\n]*)?\buse_pty\b' /etc/sudoers /etc/sudoers.d 2>/dev/null \
  && ! grep -RsiP --exclude='*.bak*' --exclude='*~' --exclude='*.rpm*' '^\s*Defaults(?:\s+[^#\n]*)?\!use_pty\b' /etc/sudoers /etc/sudoers.d 2>/dev/null ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [162] Certifique-se de que o arquivo de log sudo esteja configurado e exista"
(f=$(grep -Rsi --exclude='*.bak*' --exclude='*~' --exclude='*.rpm*' '^\s*Defaults\b.*logfile=' /etc/sudoers /etc/sudoers.d 2>/dev/null | sed -E 's/.*logfile=\"?([^\", ]+)\"?.*/\1/' | head -n1); [ -n "$f" ] && [ -f "$f" ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [163] Certifique-se de que NOPASSWD não seja usado"
(! egrep -Rsi '^\s*[^#].*\bNOPASSWD\b' /etc/sudoers /etc/sudoers.d 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [164] Certifique-se de que !authenticate não esteja definido"
(! egrep -Rsi '^\s*Defaults(?:\s+[^#\n]*)?\!authenticate\b' /etc/sudoers /etc/sudoers.d 2>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [165] Certifique-se de que sudo timestamp_timeout esteja ausente ou menor que 5"
(v=$(awk '/^\s*Defaults/ && /timestamp_timeout=/{match($0,/timestamp_timeout=([0-9-]+)/,a); if(a[1]!=""){print a[1]; exit}}' /etc/sudoers /etc/sudoers.d/* 2>/dev/null); [ -z "$v" ] || { [ "$v" -ge 0 ] 2>/dev/null && [ "$v" -le 5 ] 2>/dev/null; }) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [166] Garantir que o acesso ao su seja restrito via pam_wheel (o grupo existe)"
(g=$(grep -Poi '^\s*auth\s+(required|requisite)\s+pam_wheel\.so\b.*\bgroup=\K[[:alnum:]_.-]+' /etc/pam.d/su 2>/dev/null | head -n1); [ -n "$g" ] && getent group "$g" >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [167] Certifique-se de que o pam mais recente esteja instalado (sem atualizações pendentes)"
(sh -c 'rpm -q pam &>/dev/null || exit 1; dnf -q check-update pam &>/dev/null; [ $? -ne 100 ]') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [168] Certifique-se de que o authselect mais recente esteja instalado (sem atualizações pendentes)"
(sh -c 'rpm -q authselect &>/dev/null || exit 1; dnf -q check-update authselect &>/devnull; [ $? -ne 100 ]') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [169] Garanta que o authselect gerencie com recursos (ou fallback do PAM)"
( (authselect current &>/dev/null && authselect current | grep -q 'with-faillock' && authselect current | grep -q 'with-pwquality') \
  || (grep -Pqs '\bpam_faillock\.so\b' /etc/pam.d/{system,password}-auth 2>/dev/null && grep -Pqs '\bpam_pwquality\.so\b' /etc/pam.d/{system,password}-auth 2>/dev/null) ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"