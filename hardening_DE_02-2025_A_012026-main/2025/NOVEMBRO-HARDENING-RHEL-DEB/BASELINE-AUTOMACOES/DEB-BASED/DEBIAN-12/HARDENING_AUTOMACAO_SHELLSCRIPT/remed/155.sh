#!/usr/bin/env bash
echo "[155 - 159] SSH - Remediação"

backup_file() {
  [ -f "$1" ] && cp "$1" "$1.bak_$(date +%Y%m%d_%H%M%S)"
}

# 155 - sshd_config e .conf
echo -e "\n[155] Corrigindo permissões de /etc/ssh/sshd_config e arquivos .conf"
chmod 600 /etc/ssh/sshd_config 2>/dev/null
chown root:root /etc/ssh/sshd_config 2>/dev/null
find /etc/ssh/sshd_config.d -type f -exec chmod 600 {} \; -exec chown root:root {} \;
echo "✅ Permissões ajustadas"

# 156 - Chaves privadas
echo -e "\n[156] Corrigindo permissões das chaves privadas SSH"
find /etc/ssh -type f -name "ssh_host_*_key" ! -name "*.pub" -exec chmod 600 {} \; -exec chown root:root {} \;
echo "✅ Permissões ajustadas"

# 157 - Chaves públicas
echo -e "\n[157] Corrigindo permissões das chaves públicas SSH"
find /etc/ssh -type f -name "ssh_host_*_key.pub" -exec chmod 644 {} \; -exec chown root:root {} \;
echo "✅ Permissões ajustadas"

# 158 - Acesso sshd (manual)
echo -e "\n[158] Revisar configuração de AllowUsers/Groups ou DenyUsers/Groups em /etc/ssh/sshd_config"
echo "⚠️ Ajuste manual recomendado"

# 159 - Banner (manual)
echo -e "\n[159] Revisar parâmetro Banner em /etc/ssh/sshd_config"
echo "⚠️ Ajuste manual recomendado"