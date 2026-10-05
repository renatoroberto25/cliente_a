#!/usr/bin/env bash
echo -e "\n[35 - 39] Repositórios e segurança de pacotes"

# [35] GPG keys nos repositórios
echo -e "\n[35] Verificação: GPG keys em repositórios"
echo "❗ Esta configuração deve ser feita manualmente no arquivo de repositórios .repo."
echo "   Verifique se cada repositório possui a linha: gpgkey=<URL>"
echo "   Exemplo: gpgkey=https://repo.oracle.com/RPM-GPG-KEY-oracle-ol8"

# [36] Ativar gpgcheck globalmente
echo -e "\n[36] Ativar gpgcheck=1 globalmente em /etc/dnf/dnf.conf"
if grep -Piq '^\h*gpgcheck\h*=\h*(1|true|yes)\b' /etc/dnf/dnf.conf; then
   echo "✅ gpgcheck já está ativado"
else
   if grep -qi '^\h*gpgcheck' /etc/dnf/dnf.conf; then
      sed -i 's/^\s*gpgcheck\s*=.*/gpgcheck=1/' /etc/dnf/dnf.conf
      echo "gpgcheck atualizado para 1"
   else
      echo "gpgcheck=1" >> /etc/dnf/dnf.conf
      echo "Linha adicionada: gpgcheck=1"
   fi
fi

# [37] Ativar repo_gpgcheck globalmente
echo -e "\n[37] Ativar repo_gpgcheck=1 globalmente em /etc/dnf/dnf.conf"
if grep -Piq '^\h*repo_gpgcheck\h*=\h*(1|true|yes)\b' /etc/dnf/dnf.conf; then
   echo "✅ repo_gpgcheck já está ativado"
else
   if grep -qi '^\h*repo_gpgcheck' /etc/dnf/dnf.conf; then
      sed -i 's/^\s*repo_gpgcheck\s*=.*/repo_gpgcheck=1/' /etc/dnf/dnf.conf
      echo "repo_gpgcheck atualizado para 1"
   else
      echo "repo_gpgcheck=1" >> /etc/dnf/dnf.conf
      echo "Linha adicionada: repo_gpgcheck=1"
   fi
fi

# [38] Nenhuma ação necessária — validação apenas
#echo -e "\n[38] Validação da configuração dos repositórios"
#echo "✅ Nenhuma alteração aplicada neste item. A verificação ocorre na auditoria via 'dnf repolist'."

## [39] Atualização de pacotes
#echo -e "\n[39] Atualização de pacotes com correções de segurança"
#echo "⚠️ Atualizações de segurança devem ser aplicadas com planejamento de mudança."
#echo "   Use: dnf update --security"
#echo "   Ou: dnf upgrade-minimal --security --advisory=RHSA"
#echo "❗ A execução automática está desabilitada neste script."

exit 0