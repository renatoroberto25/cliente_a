#!/usr/bin/env bash
echo -e "\n[288] Verifique permissões de /etc/passwd"
[ -f /etc/passwd ] && stat -Lc "%a %u %g" /etc/passwd | grep -Eq '^6(4[0-4]|[0-3][0-7]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[289] Verifique permissões de /etc/passwd-"
[ -f /etc/passwd- ] && stat -Lc "%a %u %g" /etc/passwd- | grep -Eq '^6(4[0-4]|[0-3][0-7]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[290] Verifique permissões de /etc/group"
[ -f /etc/group ] && stat -Lc "%a %u %g" /etc/group | grep -Eq '^6(4[0-4]|[0-3][0-7]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[291] Verifique permissões de /etc/group-"
[ -f /etc/group- ] && stat -Lc "%a %u %g" /etc/group- | grep -Eq '^6(4[0-4]|[0-3][0-7]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[292] Verifique permissões de /etc/shadow"
[ -f /etc/shadow ] && stat -Lc "%a %u %g" /etc/shadow | grep -Eq '^(64[0]?|60[0]?) 0 (0|42)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[293] Verifique permissões de /etc/shadow-"
[ -f /etc/shadow- ] && stat -Lc "%a %u %g" /etc/shadow- | grep -Eq '^(64[0]?|60[0]?) 0 (0|42)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[294] Verifique permissões de /etc/gshadow"
[ -f /etc/gshadow ] && stat -Lc "%a %u %g" /etc/gshadow | grep -Eq '^(64[0]?|60[0]?) 0 (0|42)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[295] Verifique permissões de /etc/gshadow-"
[ -f /etc/gshadow- ] && stat -Lc "%a %u %g" /etc/gshadow- | grep -Eq '^(64[0]?|60[0]?) 0 (0|42)$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[296] Verifique permissões de /etc/shells"
[ -f /etc/shells ] && stat -Lc "%a %u %g" /etc/shells | grep -Eq '^6(4[0-4]|[0-3][0-7]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[297] Verifique permissões de /etc/security/opasswd"
[ -f /etc/security/opasswd ] && stat -Lc "%a %u %g" /etc/security/opasswd | grep -Eq '^60[0] 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"