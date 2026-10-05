#!/usr/bin/env bash
set -euo pipefail; shopt -s nullglob
TS="$(date +%Y%m%d_%H%M%S)"; bk(){ [ -f "$1" ] && cp -p "$1" "$1.bak_${TS}"; }
SUDO_MAIN=/etc/sudoers; SUDO_DIR=/etc/sudoers.d; HITSS="$SUDO_DIR/zzz_hitss_sudo.conf"; mkdir -p "$SUDO_DIR"; [ -f "$HITSS" ] || { touch "$HITSS"; chmod 440 "$HITSS"; chown root:root "$HITSS"; }

echo -e "\n [160] Garantir que os comandos sudo usem pty"
(command -v sudo &>/dev/null) || dnf -y install sudo &>/dev/null; (command -v sudo &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [161] Ensure sudo commands use pty"
grep -qiP '^\s*Defaults(?:\s+[^#\n]*)?\buse_pty\b' "$HITSS" || { bk "$HITSS"; printf "\n# HITSS[161]\nDefaults use_pty\n" >> "$HITSS"; }
for f in "$SUDO_MAIN" "$SUDO_DIR"/*; do [[ "$f" =~ \.bak|~|rpm(new|save)$ ]] && continue; [ -f "$f" ] && sed -ri 's/\!use_pty//g; s/\s{2,}/ /g' "$f"; done
visudo -cf "$SUDO_MAIN" >/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [162] Certifique-se de que o arquivo de log sudo esteja configurado e exista"
LOG=/var/log/sudo.log
grep -Rsiq '^\s*Defaults\b.*logfile=' /etc/sudoers /etc/sudoers.d || { bk "$HITSS"; printf "\n# HITSS[162]\nDefaults logfile=\"%s\"\n" "$LOG" >> "$HITSS"; }
[ -f "$LOG" ] || install -m 600 -o root -g root /dev/null "$LOG"; chown root:root "$LOG"; chmod 600 "$LOG"
(f=$(grep -Rsi '^\s*Defaults\b.*logfile=' /etc/sudoers /etc/sudoers.d 2>/dev/null | sed -E 's/.*logfile=\"?([^\", ]+)\"?.*/\1/' | head -n1); [ -n "$f" ] && [ -f "$f" ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [163] Certifique-se de que NOPASSWD não seja usado"
if egrep -Rsi '^\s*[^#].*\bNOPASSWD\b' /etc/sudoers /etc/sudoers.d 2>/dev/null; then echo "⚠️ REPROVADO"; echo "   ℹ️ Remover NOPASSWD manualmente (pode quebrar automação)"; else echo "✅ APROVADO"; fi

echo -e "\n [164] Certifique-se de que !authenticate não esteja definido"
if egrep -Rsi '^\s*Defaults(?:\s+[^#\n]*)?\!authenticate\b' /etc/sudoers /etc/sudoers.d 2>/dev/null; then echo "⚠️ REPROVADO"; echo "   ℹ️ Remover !authenticate manualmente (risco operacional)"; else echo "✅ APROVADO"; fi

echo -e "\n [165] Certifique-se de que sudo timestamp_timeout esteja ausente ou menor que 5"
for f in "$SUDO_MAIN" "$SUDO_DIR"/*; do [ -f "$f" ] || continue; if grep -Eq '^\s*Defaults\b.*timestamp_timeout=' "$f"; then cur=$(grep -Eo 'timestamp_timeout=-?[0-9]+' "$f" | tail -n1 | cut -d= -f2); { [ "${cur:-0}" -ge 0 ] && [ "$cur" -le 5 ]; } || { bk "$f"; sed -ri 's/\btimestamp_timeout=-?[0-9]+/timestamp_timeout=5/g' "$f"; }; fi; done
(v=$(awk '/^\s*Defaults/ && /timestamp_timeout=/{match($0,/timestamp_timeout=([0-9-]+)/,a); if(a[1]!=""){print a[1]; exit}}' /etc/sudoers /etc/sudoers.d/* 2>/dev/null); [ -z "$v" ] || { [ "$v" -ge 0 ] 2>/dev/null && [ "$v" -le 5 ] 2>/dev/null; }) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [166] Garantir que o acesso ao su seja restrito via pam_wheel (o grupo existe)"
getent group wheel >/dev/null || groupadd wheel
PAM_SU=/etc/pam.d/su; [ -f "$PAM_SU" ] || touch "$PAM_SU"
if grep -Pqs '^\s*auth\s+(required|requisite)\s+pam_wheel\.so\b' "$PAM_SU"; then bk "$PAM_SU"; sed -ri '/^\s*auth\s+(required|requisite)\s+pam_wheel\.so\b/ { /use_uid/! s/$/ use_uid/; /group=/{:a;n;ba}; s/$/ group=wheel/ }' "$PAM_SU"; else bk "$PAM_SU"; echo "auth required pam_wheel.so use_uid group=wheel" >> "$PAM_SU"; fi
(g=$(grep -Poi '^\s*auth\s+(required|requisite)\s+pam_wheel\.so\b.*\bgroup=\K[[:alnum:]_.-]+' "$PAM_SU" | head -n1); [ -n "$g" ] && getent group "$g" >/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [167] Certifique-se de que o pam mais recente esteja instalado (sem atualizações pendentes)"
(rpm -q pam &>/dev/null && dnf -y upgrade pam &>/dev/null) || dnf -y install pam &>/dev/null || true
(sh -c 'rpm -q pam &>/dev/null || exit 1; dnf -q check-update pam &>/dev/null; [ $? -ne 100 ]') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [168] Certifique-se de que o authselect mais recente esteja instalado (sem atualizações pendentes)"
(rpm -q authselect &>/dev/null && dnf -y upgrade authselect &>/dev/null) || dnf -y install authselect &>/dev/null || true
(sh -c 'rpm -q authselect &>/dev/null || exit 1; dnf -q check-update authselect &>/devnull; [ $? -ne 100 ]') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n [169] Garanta que o authselect gerencie com recursos (ou fallback do PAM)"
if authselect current &>/dev/null; then authselect enable-feature with-faillock &>/dev/null || true; authselect enable-feature with-pwquality &>/dev/null || true; authselect apply-changes &>/dev/null || true; fi
( (authselect current &>/dev/null && authselect current | grep -q 'with-faillock' && authselect current | grep -q 'with-pwquality') \
  || (grep -Pqs '\bpam_faillock\.so\b' /etc/pam.d/{system,password}-auth 2>/dev/null && grep -Pqs '\bpam_pwquality\.so\b' /etc/pam.d/{system,password}-auth 2>/dev/null) ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"