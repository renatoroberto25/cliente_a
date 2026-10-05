#!/usr/bin/env bash
echo "Iniciando remediação: 214 - Configurações de armazenamento e ações do auditd"

CONFIG="/etc/audit/auditd.conf"
BACKUP="/etc/audit/auditd.conf.bkp-632-$(date +%F_%T)"

echo "Backup do arquivo original em: $BACKUP"
cp -p "$CONFIG" "$BACKUP"

# Garantir max_log_file
echo "241 Garantindo configuração do tamanho máximo do log (max_log_file)..."
if grep -q '^\s*max_log_file' "$CONFIG"; then
    sed -i 's/^\s*max_log_file\s*=.*/max_log_file = 8/' "$CONFIG"
    echo "✅ SUCESSO: max_log_file ajustado para 8"
else
    echo -e "\n# Adicionado via remediação tópico 241\nmax_log_file = 8" >> "$CONFIG"
    echo "✅ SUCESSO: max_log_file adicionado ao final do arquivo"
fi

# Garantir max_log_file_action
echo "242 Garantindo que logs não sejam apagados automaticamente (max_log_file_action != ROTATE)..."
if grep -q '^\s*max_log_file_action\s*=' "$CONFIG"; then
    sed -i 's/^\s*max_log_file_action\s*=.*/max_log_file_action = keep_logs/' "$CONFIG"
    echo "✅ SUCESSO: max_log_file_action ajustado para keep_logs"
else
    echo -e "\n# Adicionado via remediação tópico 242\nmax_log_file_action = keep_logs" >> "$CONFIG"
    echo "✅ SUCESSO: max_log_file_action adicionado ao final do arquivo"
fi

# Garantir disk_full_action
echo "243 Garantindo ação quando os logs estiverem cheios (disk_full_action)..."
if grep -q '^\s*disk_full_action' "$CONFIG"; then
    sed -i 's/^\s*disk_full_action\s*=.*/disk_full_action = halt/' "$CONFIG"
    echo "✅ SUCESSO: disk_full_action ajustado para halt"
else
    echo -e "\n# Adicionado via remediação tópico 243\ndisk_full_action = halt" >> "$CONFIG"
    echo "✅ SUCESSO: disk_full_action adicionado ao final do arquivo"
fi

# Garantir space_left_action
echo "244 Garantindo ação quando o espaço estiver acabando (admin_space_left_action)..."
if grep -q '^\s*space_left_action' "$CONFIG"; then
    sed -i 's/^\s*space_left_action\s*=.*/space_left_action = email/' "$CONFIG"
    echo "✅ SUCESSO: space_left_action ajustado para email"
else
    echo -e "\n# Adicionado via remediação tópico 244\nspace_left_action = email" >> "$CONFIG"
    echo "✅ SUCESSO: space_left_action adicionado ao final do arquivo"
fi

echo "✅ Remediação finalizada para a seção 214"