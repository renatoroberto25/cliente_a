#!/usr/bin/env bash
set -u
echo "[210 - 219] Configuração journald"

# 210 (Manual)
echo -e "\n [210] Verifique se systemd-journal-remote está instalado"
(rpm -q systemd-journal-remote &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 211 (Manual)
echo -e "\n [211] Verifique se systemd-journal-remote está configurado"
echo "⚠️ REPROVADO"

# 212 (Manual)
echo -e "\n [212] Verifique se systemd-journal-remote está habilitado"
(systemctl list-unit-files | grep -q systemd-journal-remote.socket && \
 systemctl is-enabled systemd-journal-remote.socket 2>/dev/null | grep -q enabled) \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 213
echo -e "\n [213] Verifique se journald não está configurado para receber logs remotos"
if grep -Eiq '^\s*ListenStream=' /etc/systemd/journal-remote.conf /etc/systemd/journal-remote.conf.d/*.conf 2>/dev/null; then
    echo "⚠️ REPROVADO"
else
    echo "✅ APROVADO"
fi

# 214
echo -e "\n [214] Verifique se o serviço systemd-journald está ativo"
(systemctl is-active systemd-journald 2>/dev/null | grep -q active) \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 215
echo -e "\n [215] Verifique se journald está configurado para compressão"
grep -Eiq '^[[:space:]]*Compress=yes' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 216
echo -e "\n [216] Verifique se journald está configurado para escrita persistente"
grep -Eiq '^[[:space:]]*Storage=persistent' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf 2>/dev/null \
   && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 217 (Manual)
echo -e "\n [217] Verifique se journald não envia logs para rsyslog"
echo "⚠️ REPROVADO"

# 218 (Manual)
echo -e "\n [218] Verifique se a rotação de logs do journald está conforme política"
echo "⚠️ REPROVADO"

# 219 (Manual)
echo -e "\n [219] Verifique se logrotate está configurado"
if [ -f /etc/logrotate.conf ] || compgen -G "/etc/logrotate.d/*" > /dev/null; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi
