#!/usr/bin/env bash
echo -e "\n [263 - 272] Permissões de arquivo do sistema"

echo "[263] Verifique se as permissões de /etc/passwd estão configuradas"
[ -e /etc/passwd ] && stat -Lc '%a %u %g' /etc/passwd | egrep -q '^([0-6][0-4][0-4]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[264] Verifique se as permissões de /etc/passwd- estão configuradas"
[ ! -e /etc/passwd- ] && echo "✔ IGNORADO" || (stat -Lc '%a %u %g' /etc/passwd- | egrep -q '^([0-6][0-4][0-4]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo "[265] Verifique se as permissões de /etc/security/opasswd estão configuradas"
[ ! -e /etc/security/opasswd ] && echo "✔ IGNORADO" || (stat -Lc '%a %u %g' /etc/security/opasswd | egrep -q '^(600|60[0-9]|[0-5][0-9]{2}) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo "[266] Verifique se as permissões de /etc/group estão configuradas"
[ -e /etc/group ] && stat -Lc '%a %u %g' /etc/group | egrep -q '^([0-6][0-4][0-4]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[267] Verifique se as permissões de /etc/group- estão configuradas"
[ ! -e /etc/group- ] && echo "✔ IGNORADO" || (stat -Lc '%a %u %g' /etc/group- | egrep -q '^([0-6][0-4][0-4]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo "[268] Verifique se as permissões de /etc/shadow estão configuradas"
[ -e /etc/shadow ] && stat -Lc '%a %u %g' /etc/shadow | egrep -q '^0+ 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[269] Verifique se as permissões de /etc/shadow- estão configuradas"
[ ! -e /etc/shadow- ] && echo "✔ IGNORADO" || (stat -Lc '%a %u %g' /etc/shadow- | egrep -q '^0+ 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo "[270] Verifique se as permissões de /etc/gshadow estão configuradas"
[ -e /etc/gshadow ] && stat -Lc '%a %u %g' /etc/gshadow | egrep -q '^0+ 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo "[271] Verifique se as permissões de /etc/gshadow- estão configuradas"
[ ! -e /etc/gshadow- ] && echo "✔ IGNORADO" || (stat -Lc '%a %u %g' /etc/gshadow- | egrep -q '^0+ 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo "[272] Verifique se as permissões de /etc/shells estão configuradas"
[ -e /etc/shells ] && stat -Lc '%a %u %g' /etc/shells | egrep -q '^([0-6][0-4][0-4]) 0 0$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
