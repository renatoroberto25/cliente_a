#!/usr/bin/env bash
set -u
echo "[220 - 228] Remediação do Auditd e Logs"

backup_file() {
    local f="$1"
    [[ -f "$f" ]] && cp -p "$f" "$f.bak_$(date +%Y%m%d_%H%M%S)"
}

# 220
echo -e "\n [220] Ajustando permissões dos arquivos de log"
while IFS= read -r line; do
    file=$(echo "$line" | awk '{print $1}')
    mode=$(echo "$line" | awk '{print $2}')
    if [[ "$mode" -gt 640 && "$mode" -ne 664 ]]; then
        echo "  Corrigindo $file (modo $mode → 640)"
        chmod 640 "$file" 2>/dev/null || true
    fi
done < <(find /var/log -type f -printf "%p %m\n" 2>/dev/null)
echo "✅ Finalizado"

# 221
echo -e "\n [221] Garantindo que audit e audit-libs estejam instalados"
if ! rpm -q audit audit-libs &>/dev/null; then
    dnf install -y audit audit-libs
    echo "✅ Pacotes instalados"
else
    echo "✅ Já instalados"
fi

# 222
echo -e "\n [222] Habilitar audit=1 no GRUB (necessário reboot)"
if ! grep -Pq '^\h*GRUB_CMDLINE_LINUX=".*\baudit=1\b' /etc/default/grub; then
    backup_file /etc/default/grub
    sed -ri 's/^(GRUB_CMDLINE_LINUX=".*)"/\1 audit=1"/' /etc/default/grub
    echo "❗ Alterado, executar: grub2-mkconfig -o /boot/grub2/grub.cfg && reboot"
else
    echo "✅ Já configurado"
fi

# 223
echo -e "\n [223] Configurar audit_backlog_limit no GRUB (necessário reboot)"
if ! grep -Pq 'audit_backlog_limit=\d+' /etc/default/grub; then
    backup_file /etc/default/grub
    sed -ri 's/^(GRUB_CMDLINE_LINUX=".*)"/\1 audit_backlog_limit=8192"/' /etc/default/grub
    echo "❗ Alterado, executar: grub2-mkconfig -o /boot/grub2/grub.cfg && reboot"
else
    echo "✅ Já configurado"
fi

# 224
echo -e "\n [224] Habilitar auditd.service"
systemctl enable --now auditd 2>/dev/null && echo "✅ auditd habilitado" || echo "❗ Falha ao habilitar auditd"

# 225
echo -e "\n [225] Configurar max_log_file em /etc/audit/auditd.conf"
if ! grep -Pq '^\h*max_log_file\h*=\h*\d+' /etc/audit/auditd.conf; then
    backup_file /etc/audit/auditd.conf
    echo "max_log_file = 8" >> /etc/audit/auditd.conf
    echo "✅ max_log_file adicionado (8MB)"
else
    echo "✅ Já configurado"
fi

# 226
echo -e "\n [226] Configurar max_log_file_action != ROTATE"
if grep -Pq '^\h*max_log_file_action\h*=\h*(rotate|ROTATE)\b' /etc/audit/auditd.conf; then
    backup_file /etc/audit/auditd.conf
    sed -ri 's/^\s*max_log_file_action\s*=.*/max_log_file_action = keep_logs/' /etc/audit/auditd.conf
    echo "✅ Alterado para keep_logs"
else
    echo "✅ Já configurado corretamente"
fi

# 227
echo -e "\n [227] Configurar disk_full_action (alto impacto)"
if ! grep -Pq '^\h*disk_full_action\h*=\h*(halt|single)\b' /etc/audit/auditd.conf; then
    echo "❗ Necessário configurar manualmente: disk_full_action = halt (ou single) em /etc/audit/auditd.conf"
else
    echo "✅ Já configurado"
fi

# 228
echo -e "\n [228] Configurar space_left_action"
if ! grep -Pq '^\h*space_left_action\h*=\h*(email|exec|single|halt)\b' /etc/audit/auditd.conf; then
    backup_file /etc/audit/auditd.conf
    echo "space_left_action = email" >> /etc/audit/auditd.conf
    echo "✅ space_left_action definido como email (necessário mailx/postfix configurado)"
else
    echo "✅ Já configurado"
fi