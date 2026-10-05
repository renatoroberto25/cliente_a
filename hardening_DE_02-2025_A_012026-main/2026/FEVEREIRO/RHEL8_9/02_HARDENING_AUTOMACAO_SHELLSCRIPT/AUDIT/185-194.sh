#!/usr/bin/env bash
echo -e "\n[185] Verificar permissões de /etc/passwd"
( [ -f /etc/passwd ] && stat -Lc "%a %u %g" /etc/passwd | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[186] Verificar permissões de /etc/passwd-"
( [ -f /etc/passwd- ] && stat -Lc "%a %u %g" /etc/passwd- | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[187] Verificar permissões de /etc/shadow"
( [ -f /etc/shadow ] && stat -Lc "%a %u %g" /etc/shadow | grep -Eq '^0+ 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[188] Verificar permissões de /etc/shadow-"
( [ -f /etc/shadow- ] && stat -Lc "%a %u %g" /etc/shadow- | grep -Eq '^0+ 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[189] Verificar permissões de /etc/gshadow-"
( [ -f /etc/gshadow- ] && stat -Lc "%a %u %g" /etc/gshadow- | grep -Eq '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[190] Verificar permissões de /etc/gshadow"
( [ -f /etc/gshadow ] && stat -Lc "%a %u %g" /etc/gshadow | grep -Eq '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[191] Verificar permissões de /etc/group"
( [ -f /etc/group ] && stat -Lc "%a %u %g" /etc/group | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[192] Verificar permissões de /etc/group-"
( [ -f /etc/group- ] && stat -Lc "%a %u %g" /etc/group- | grep -Eq '^64[0-9] 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[193] Verificar se /etc/shells não lista nologin"
( grep -Eq 'nologin' /etc/shells ) && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

echo -e "\n[194] Verificar permissões de /etc/security/opasswd"
( [ -f /etc/security/opasswd ] && stat -Lc "%a %u %g" /etc/security/opasswd | grep -Eq '^600 0 0$' ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

