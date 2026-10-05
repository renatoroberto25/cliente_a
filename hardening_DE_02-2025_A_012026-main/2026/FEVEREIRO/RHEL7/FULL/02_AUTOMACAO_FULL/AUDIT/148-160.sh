
#!/usr/bin/env bash

echo "[148] Root é o único UID 0"
awk -F: '($3==0 && $1!="root"){found=1} END{if(found) exit 1}' /etc/passwd && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[149] Root é o único GID 0"
[ "$(awk -F: '/^root:/ {print $4}' /etc/passwd)" = "0" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[150] Contas de sistema com shell interativo"
awk -F: '($3<1000 && $1!="root" && $7 ~ /(bash|sh|zsh)$/){exit 1} END{exit 0}' /etc/passwd && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# Inconsistente com o 193 Verificar se /etc/shells não lista nologin
#echo "[151] /sbin/nologin presente em /etc/shells"
#grep -Eq '^(\/usr)?\/sbin\/nologin$' /etc/shells && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[152] PATH do root configurado corretamente"
grep -Eq '^PATH=\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin' /root/.bash_profile && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[153] umask global configurado como 027"
grep -Rqs '^\s*umask\s\+027\b' /etc/profile /etc/bashrc /etc/profile.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[154] TMOUT configurado como 900 ou mais"
grep -Rqs '^\s*TMOUT\s*=\s*(900|9[0-9]{2}|[1-9][0-9]{3,})' /etc/profile /etc/bashrc /etc/profile.d 2>/dev/null && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[155] Ausência de regras amplas (%grupo ALL=(ALL))"
grep -RqsE '^%.*ALL=\(ALL\)' /etc/sudoers /etc/sudoers.d 2>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[156] sudo usa pty"
grep -Rqs 'Defaults\s\+use_pty' /etc/sudoers /etc/sudoers.d && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[157] sudo tem logfile configurado"
grep -Rqs 'Defaults\s\+logfile=' /etc/sudoers /etc/sudoers.d && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[158] !authenticate não está presente"
grep -Rqs 'Defaults\s\+!authenticate' /etc/sudoers /etc/sudoers.d && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo "[159] timestamp_timeout = 5"
grep -Rqs 'timestamp_timeout=5' /etc/sudoers /etc/sudoers.d && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[160] su restrito ao grupo wheel"
grep -Eq '^auth\s+(required|requisite)\s+pam_wheel\.so' /etc/pam.d/su && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
