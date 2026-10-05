#!/usr/bin/env bash

echo "[148] Root é o único UID 0"
awk -F: '($3==0 && $1!="root"){found=1} END{if(found) exit 1}' /etc/passwd 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[149] Root é o único GID 0"
[ "$(awk -F: '/^root:/ {print $4}' /etc/passwd 2>/dev/null)" = "0" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[150] Contas de sistema com shell interativo (Debian: UID < 1000, exceto root, shell != nologin/false)"
awk -F: '($3<1000 && $1!="root" && $7 !~ /(\/usr\/sbin\/nologin|\/sbin\/nologin|\/bin\/false)$/){exit 1} END{exit 0}' /etc/passwd 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

#151 Inconsistente com o 193

echo "[152] PATH do root configurado corretamente (Debian: validar /etc/environment e /etc/profile, não /root/.bash_profile)"
( grep -Eq '^[[:space:]]*PATH="?/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' /etc/environment 2>/dev/null || grep -RqsE '^[[:space:]]*PATH="?/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' /etc/profile /etc/profile.d 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo "[153] umask global configurado como 027 (Debian: /etc/profile e /etc/profile.d)"
grep -RqsE '^[[:space:]]*umask[[:space:]]+027\b' /etc/profile /etc/profile.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo "[154] TMOUT configurado como 900 ou mais (Debian: export TMOUT e readonly recomendado)"
grep -RqsE '^[[:space:]]*(readonly[[:space:]]+)?TMOUT[[:space:]]*=[[:space:]]*(900|9[0-9]{2}|[1-9][0-9]{3,})\b' /etc/profile /etc/profile.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo "[155] Ausência de regras amplas (%grupo ALL=(ALL))"
grep -RqsE '^[[:space:]]*%[^#[:space:]]+[[:space:]]+ALL=\(ALL(:ALL)?\)[[:space:]]+ALL\b' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo "[156] sudo usa pty"
grep -RqsE '^[[:space:]]*Defaults[[:space:]]+use_pty\b' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo "[157] sudo tem logfile configurado"
grep -RqsE '^[[:space:]]*Defaults[[:space:]]+logfile=' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[158] !authenticate não está presente"
grep -RqsE '^[[:space:]]*Defaults[[:space:]]+!authenticate\b' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[159] timestamp_timeout = 5"
grep -RqsE '^[[:space:]]*Defaults[[:space:]]+timestamp_timeout=5\b' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE

echo "[160] su restrito ao grupo sudo (Debian: grupo sudo; wheel geralmente não existe)"
grep -Eq '^[[:space:]]*auth[[:space:]]+(required|requisite)[[:space:]]+pam_wheel\.so\b.*\bgroup=sudo\b' /etc/pam.d/su 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#MUDAR NO TENABLE AUDIT
#ADAPTAR NO BASELINE
