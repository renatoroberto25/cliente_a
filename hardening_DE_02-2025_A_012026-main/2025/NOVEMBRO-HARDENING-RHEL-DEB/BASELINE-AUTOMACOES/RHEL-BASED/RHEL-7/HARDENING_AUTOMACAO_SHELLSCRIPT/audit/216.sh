#!/usr/bin/env bash
# [216] Audite permissões de arquivos de sistema
echo "[216] Permissões de arquivos de sistema"
rpm -Va --nomtime --nosize --nomd5 --nolinkto | grep -vw c &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# [217] /etc/passwd
echo "[217] /etc/passwd"
[ "$(stat -Lc '%a %U %G' /etc/passwd)" = "644 root root" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [218] /etc/passwd-
echo "[218] /etc/passwd-"
[ -f /etc/passwd- ] && [ "$(stat -Lc '%a %U %G' /etc/passwd-)" = "644 root root" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [219] /etc/shadow
echo "[219] /etc/shadow"
[ "$(stat -Lc '%a %U %G' /etc/shadow)" = "0 root root" ] || [ "$(stat -Lc '%a %U %G' /etc/shadow)" = "000 root root" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [220] /etc/shadow-
echo "[220] /etc/shadow-"
[ -f /etc/shadow- ] && ( [ "$(stat -Lc '%a %U %G' /etc/shadow-)" = "0 root root" ] || [ "$(stat -Lc '%a %U %G' /etc/shadow-)" = "000 root root" ] ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [221] /etc/gshadow-
echo "[221] /etc/gshadow-"
[ -f /etc/gshadow- ] && ( [ "$(stat -Lc '%a %U %G' /etc/gshadow-)" = "0 root root" ] || [ "$(stat -Lc '%a %U %G' /etc/gshadow-)" = "000 root root" ] ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [222] /etc/gshadow
echo "[222] /etc/gshadow"
[ "$(stat -Lc '%a %U %G' /etc/gshadow)" = "0 root root" ] || [ "$(stat -Lc '%a %U %G' /etc/gshadow)" = "000 root root" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [223] /etc/group
echo "[223] /etc/group"
[ "$(stat -Lc '%a %U %G' /etc/group)" = "644 root root" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# [224] /etc/group-
echo "[224] /etc/group-"
[ -f /etc/group- ] && [ "$(stat -Lc '%a %U %G' /etc/group-)" = "644 root root" ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO"


# [225] Arquivos world-writable
echo "[225] Arquivos world-writable"
WW_COUNT=$(df --local -P | awk 'NR!=1 {print $6}' | xargs -I '{}' find '{}' -xdev -type f -perm -0002 2>/dev/null | wc -l)
[ "$WW_COUNT" -eq 0 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO ($WW_COUNT arquivos)"

# [226] Arquivos sem dono
echo "[226] Arquivos sem dono"
NU_COUNT=$(df --local -P | awk 'NR!=1 {print $6}' | xargs -I '{}' find '{}' -xdev -nouser 2>/dev/null | wc -l)
[ "$NU_COUNT" -eq 0 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO ($NU_COUNT arquivos)"

# [227] Arquivos sem grupo
echo "[227] Arquivos sem grupo"
NG_COUNT=$(df --local -P | awk 'NR!=1 {print $6}' | xargs -I '{}' find '{}' -xdev -nogroup 2>/dev/null | wc -l)
[ "$NG_COUNT" -eq 0 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO ($NG_COUNT arquivos)"

# [228] Arquivos com bit SUID
echo "[228] Arquivos com bit SUID"
SUID_COUNT=$(df --local -P | awk 'NR!=1 {print $6}' | xargs -I '{}' find '{}' -xdev -type f -perm -4000 2>/dev/null | wc -l)
[ "$SUID_COUNT" -eq 0 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO ($SUID_COUNT arquivos com SUID)"

# [229] Arquivos com bit SGID
echo "[229] Arquivos com bit SGID"
SGID_COUNT=$(df --local -P | awk 'NR!=1 {print $6}' | xargs -I '{}' find '{}' -xdev -type f -perm -2000 2>/dev/null | wc -l)
[ "$SGID_COUNT" -eq 0 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO ($SGID_COUNT arquivos com SGID)"

echo -e "\n[000] Verifique permissões de /etc/shells"
(test -e /etc/shells && [ $(stat -c "%a" /etc/shells) -le 644 ] && [ $(stat -c "%u" /etc/shells) -eq 0 ] && [ $(stat -c "%g" /etc/shells) -eq 0 ]) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[000] Verifique permissões de /etc/security/opasswd"
[ -e /etc/security/opasswd ] && ( [ "$(stat -c '%a' /etc/security/opasswd)" -le 600 ] && [ "$(stat -c '%u' /etc/security/opasswd)" -eq 0 ] && [ "$(stat -c '%g' /etc/security/opasswd)" -eq 0 ] && echo "✅ APROVADO" || echo "⚠️ REPROVADO" ) || echo "⚠️ IGNORADO: O arquivo /etc/security/opasswd não existe neste sistema."
