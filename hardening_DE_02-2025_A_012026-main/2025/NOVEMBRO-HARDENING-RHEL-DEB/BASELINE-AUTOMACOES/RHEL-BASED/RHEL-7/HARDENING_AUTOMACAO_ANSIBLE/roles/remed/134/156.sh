#!/usr/bin/env bash
echo "[156–166] Remediação automática segura - Rsyslog, Journald e Logrotate"

# 156 - Ensure rsyslog is installed
echo "[156] Garantindo que o rsyslog esteja instalado"
if ! rpm -q rsyslog &>/dev/null; then
  dnf install -y rsyslog && echo "✅ rsyslog instalado com sucesso"
else
  echo "✅ rsyslog já instalado"
fi

# 157 - Ensure rsyslog service is enabled and running
echo "[157] Garantindo que o rsyslog esteja habilitado e em execução"
if ! systemctl is-enabled rsyslog &>/dev/null || ! systemctl is-active rsyslog &>/dev/null; then
  systemctl enable --now rsyslog && echo "✅ rsyslog habilitado e iniciado"
else
  echo "✅ rsyslog já ativo"
fi

# 158 - Ensure default file permissions configured
echo "[158] Garantindo permissões padrão de log (0640)"
if grep -q "FileCreateMode" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  sed -i 's/^.*FileCreateMode.*/$FileCreateMode 0640/' /etc/rsyslog.conf
else
  echo '$FileCreateMode 0640' >> /etc/rsyslog.conf
fi
echo "✅ FileCreateMode configurado"

# 159 - Ensure logging is configured
echo "[159] Verifique se o rsyslog está configurado corretamente"
[ -s /etc/rsyslog.conf ] && echo "✅ Arquivo de configuração presente" || echo "⚠️ REPROVADO - Manual: revise /etc/rsyslog.conf conforme política do site"

# 160 - Ensure rsyslog sends logs to remote host
echo "[160] Verifique se o envio remoto de logs está configurado"
if grep -Eq '@@?[^ ]+' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  echo "✅ Envio remoto configurado"
else
  echo "⚠️ Manual — adicione linha de envio remoto no formato: *.* @@<ip_loghost>:514"
fi

# 161 - Ensure remote messages accepted only on log hosts
echo "[161] Verifique se o rsyslog aceita logs remotos apenas quando designado"
if grep -q "imtcp" /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  echo "✅ Host configurado para aceitar logs"
else
  echo "⚠️ Manual — habilite apenas em log hosts: adicione '$ModLoad imtcp' e '$InputTCPServerRun 514' quando aplicável"
fi

# 162 - Ensure journald forwards logs to rsyslog
echo "[162] Garantindo encaminhamento do journald para o rsyslog"
if grep -q "ForwardToSyslog=yes" /etc/systemd/journald.conf 2>/dev/null; then
  echo "✅ ForwardToSyslog já configurado"
else
  sed -i '/^#*ForwardToSyslog/d' /etc/systemd/journald.conf
  echo "ForwardToSyslog=yes" >> /etc/systemd/journald.conf
  systemctl restart systemd-journald
  echo "✅ Encaminhamento habilitado"
fi

# 163 - Ensure journald compresses large logs
echo "[163] Garantindo compressão de logs do journald"
if grep -q "Compress=yes" /etc/systemd/journald.conf 2>/dev/null; then
  echo "✅ Compressão já configurada"
else
  sed -i '/^#*Compress/d' /etc/systemd/journald.conf
  echo "Compress=yes" >> /etc/systemd/journald.conf
  systemctl restart systemd-journald
  echo "✅ Compressão habilitada"
fi

# 164 - Ensure journald stores logs persistently
echo "[164] Garantindo persistência dos logs do journald"
if grep -q "Storage=persistent" /etc/systemd/journald.conf 2>/dev/null; then
  echo "✅ Persistência já configurada"
else
  sed -i '/^#*Storage/d' /etc/systemd/journald.conf
  echo "Storage=persistent" >> /etc/systemd/journald.conf
  systemctl restart systemd-journald
  echo "✅ Configuração de armazenamento persistente aplicada"
fi

echo "[165] Corrigindo permissões em /var/log conforme CIS/HITSS"

echo "✅ Aplicando 0640 em arquivos e 0750 em diretórios dentro de /var/log..."
find /var/log -type d -exec chmod 0750 {} \; 2>/dev/null
find /var/log -type f -exec chmod 0640 {} \; 2>/dev/null

echo "✅ Permissões ajustadas com sucesso"

# 166 - Ensure logrotate is configured
echo "[166] Verifique se o logrotate está configurado"
if [ -s /etc/logrotate.conf ] && ls /etc/logrotate.d/* &>/dev/null; then
  echo "✅ Logrotate configurado"
else
  echo "⚠️ Manual — revise /etc/logrotate.conf e /etc/logrotate.d/* conforme política de retenção"
fi