#!/usr/bin/env bash

{
   #iniciação de variáveis
   l_output="" l_output2=""
   l_perm_mask="0177"
   #verifica se o auditd.conf existe
   if [ -e "/etc/audit/auditd.conf" ]; then
      #se existe extrai o conteúdo de log_file
      l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' /etc/audit/auditd.conf | xargs)")"
      #verifica se o diretório audit_log_directory existe
      if [ -d "$l_audit_log_directory" ]; then
         #define a permissão máxima aceitável que será comparada
         l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )"
         #loop para ler cada arquivo retornado pelo find, usando \0 como delimitador (suporta nomes com espaços).
         while IFS= read -r -d $'\0' l_file; do
         #para cada arquivo, stat mostra permissões em octal (%#a) e modo legível (%A), se a permissão for mais aberta que o esperado, adiciona uma linha de erro à l_output2
            while IFS=: read -r l_file_mode l_hr_file_mode; do
               l_output2="$l_output2 - Arquivo: \"$l_file\" está: \"$l_file_mode\"    (deveria ser: \"$l_maxperm\" ou mais restritivo.)\n"
            done <<< "$(stat -Lc '%#a:%A' "$l_file")"
            #find procura arquivos diretamente no diretório de log com permissões perigosas (com base na máscara), -print0 garante que nomes com espaço sejam lidos corretamente.
         done < <(find "$l_audit_log_directory" -maxdepth 1 -type f -perm /"$l_perm_mask" -print0)
      else
         #caso o diretório informado no auditd.conf não exista, exibe um aviso.
         l_output2="$l_output2 - Diretório de logs não configurado em \"/etc/audit/auditd.conf\" por favor definir."
      fi
   else
      #caso o próprio auditd.conf não exista, mostra mensagem de erro.
      l_output2="$l_output2 - Arquivo: \"/etc/audit/auditd.conf\" não encontrado. - Verificque se o auditd está instalado."
   fi
   #se nenhum erro foi acumulado em l_output2, exibe mensagem de aprovação com o diretório e permissão segura.
   if [ -z "$l_output2" ]; then
      l_output="$l_output - Todos os arquivos em \"$l_audit_log_directory\" estão: \"$l_maxperm\" ou mais restritivo."
echo "✅ [APROVADO]: $l_output"
   else
echo "⚠️[REPROVADO]: $l_output2\n"
   fi
}