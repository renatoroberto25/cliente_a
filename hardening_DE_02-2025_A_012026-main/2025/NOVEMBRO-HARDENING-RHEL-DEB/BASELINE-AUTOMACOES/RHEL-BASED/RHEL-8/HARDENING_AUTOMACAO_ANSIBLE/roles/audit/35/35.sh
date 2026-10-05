#!/usr/bin/env bash

echo -e "\n[35 - 39] Repositórios e verificações de segurança de pacotes\n"

# [35] Verifique se os repositórios possuem chaves GPG configuradas
echo "[35] Verifique se os repositórios possuem chaves GPG configuradas"
if grep -r gpgkey /etc/yum.repos.d/* /etc/dnf/dnf.conf > /dev/null 2>&1; then
   echo "✅ APROVADO"
else
   echo "⚠️ REPROVADO"
fi

# [36] Verifique se a opção gpgcheck está ativada globalmente
echo -e "\n[36] Verifique se a opção gpgcheck está ativada globalmente"
if grep -Pi -- '^\h*gpgcheck\h*=\h*(1|true|yes)\b' /etc/dnf/dnf.conf > /dev/null 2>&1; then
   echo "✅ APROVADO"
else
   echo "⚠️ REPROVADO"
fi

# [37] Verifique se a opção repo_gpgcheck está ativada globalmente
echo -e "\n[37] Verifique se a opção repo_gpgcheck está ativada globalmente"
if grep -Pi -- '^\h*repo_gpgcheck\h*=\h*(1|true|yes)\b' /etc/dnf/dnf.conf > /dev/null 2>&1; then
   echo "✅ APROVADO"
else
   echo "⚠️ REPROVADO"
fi

# [38] Verifique se os repositórios estão configurados corretamente
#echo -e "\n[38] Verifique se os repositórios estão configurados corretamente"
#if dnf -q repolist > /dev/null 2>&1; then
#   echo "✅ APROVADO"
#else
#   echo "⚠️ REPROVADO"
#fi

# [39] Verifique se o sistema está atualizado com patches e se não requer reinicialização"
# Verifica se há atualizações pendentes (ignorando metadata e linhas vazias)
#if dnf -q check-update > /tmp/checkupdate.$$ 2>/dev/null; then
#   # check-update terminou sem atualizações
#   if dnf -q needs-restarting -r > /dev/null 2>&1; then
#       echo "✅ APROVADO"
#   else
#       echo "⚠️ REPROVADO: O sistema requer reinicialização para aplicar atualizações"
#   fi
#else
#   # check-update retorna 100 quando há updates pendentes
#   if grep -qE "^[a-zA-Z0-9]" /tmp/checkupdate.$$; then
#       echo "⚠️ REPROVADO: Há atualizações pendentes no sistema"
#   else
#       echo "⚠️ REPROVADO: Erro ao verificar atualizações"
#   fi
#fi
#rm -f /tmp/checkupdate.$$


exit 0