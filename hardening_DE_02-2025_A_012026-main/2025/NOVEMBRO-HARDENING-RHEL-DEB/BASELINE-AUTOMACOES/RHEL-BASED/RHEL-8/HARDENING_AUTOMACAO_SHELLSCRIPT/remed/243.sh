#!/usr/bin/env bash
set -u
echo -e "\n [243 - 249] Configurações de regras de audit"
# Função genérica para verificar e remediar comandos auditados
check_and_fix_cmd() {
  local id="$1"
  local cmd="$2"
  local path="$3"
  local file="/etc/audit/rules.d/${id}-${cmd}.rules"

  echo "[${id}] Verifique se o uso do comando ${cmd} é auditado"

  if egrep -iq "${cmd}" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
     auditctl -l 2>/dev/null | egrep -iq "${cmd}"; then
    echo "✅ APROVADO - Já auditado"
  else
    echo "⚠️ REPROVADO - Não auditado"
    echo "⚠️ Aplicando regra em ${file}"
    echo "-a always,exit -F path=${path} -F perm=x -F auid>=1000 -F auid!=-1 -k ${cmd}" > "$file"
    augenrules --load &>/dev/null
    echo "✅ Regra adicionada e recarregada"
  fi
}

# 243 - chcon
check_and_fix_cmd 243 "chcon" "/usr/bin/chcon"

# 244 - setfacl
check_and_fix_cmd 244 "setfacl" "/usr/bin/setfacl"

# 245 - chacl
check_and_fix_cmd 245 "chacl" "/usr/bin/chacl"

# 246 - usermod
check_and_fix_cmd 246 "usermod" "/usr/sbin/usermod"

# 247 - kernel module loading/unloading/modification
echo "[247] Verifique se carregamento, descarregamento e modificação de módulos do kernel são auditados"
file="/etc/audit/rules.d/247-kernel-mod.rules"
if egrep -iq "init_module|finit_module|delete_module" /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null || \
   auditctl -l 2>/dev/null | egrep -iq "init_module|finit_module|delete_module"; then
  echo "✅ APROVADO - Já auditado"
else
  echo "⚠️ REPROVADO - Não auditado"
  echo "⚠️ Aplicando regra em ${file}"
  cat <<EOF > "$file"
-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k kernel_modules
-a always,exit -F arch=b32 -S init_module,finit_module,delete_module -k kernel_modules
EOF
  augenrules --load &>/dev/null
  echo "✅ Regra adicionada e recarregada"
fi

# 248 - auditd configuração imutável (somente alerta!)
echo "[248] Auditoria imutável (-e 2)"
IMMUTABLE_FOUND=$(egrep -Ph '^\s*-e\s+2' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)
if [[ "$IMMUTABLE_FOUND" == "-e 2" ]]; then
  echo "✅ Já está configurado como imutável"
else
  echo "⚠️ Crítico: Configuração '-e 2' não encontrada"
  echo "ℹ️ Para corrigir manualmente, adicione e recarregue:"
  echo "    echo '-e 2' >> /etc/audit/rules.d/99-finalize.rules && augenrules --load"
fi

# 249 - sincronização entre configuração em disco e em execução
echo "[249] Verifique se configuração em disco e em execução estão sincronizadas"
if augenrules --check 2>&1 | grep -q "No change"; then
  echo "✅ APROVADO - Configuração alinhada"
else
  echo "⚠️ REPROVADO - Divergência encontrada"
  echo "⚠️ Forçando recarregamento..."
  augenrules --load &>/dev/null
  echo "✅ Configuração recarregada"
fi