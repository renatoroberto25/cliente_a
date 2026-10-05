
#!/usr/bin/env bash

echo -e "\n[52] MAC (SELinux/AppArmor) ativo"
( aa-status 2>/dev/null | grep -q 'profiles are loaded' && echo "✅ APROVADO" || echo "⚠️ REPROVADO" )

echo -e "\n[53] Política MAC definida"
( aa-status 2>/dev/null | grep -q 'enforce mode' && echo "✅ APROVADO" || echo "⚠️ REPROVADO" )

echo -e "\n[54] Serviços unconfined minimizados"
( aa-status 2>/dev/null | grep -q 'unconfined' && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )

# Debian/AppArmor não diferencia unconfined_service vs unconfined_t
#echo -e "\n[55] Sem serviços sem restrições MAC"
#( aa-status 2>/dev/null | grep -q 'unconfined' && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )

echo -e "\n[56] Prelink removido"
( dpkg -l | grep -q '^ii\s\+prelink' && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )

echo -e "\n[57] xinetd removido"
( dpkg -l | grep -q '^ii\s\+xinetd' && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )

#MUDAR NO BASELINE