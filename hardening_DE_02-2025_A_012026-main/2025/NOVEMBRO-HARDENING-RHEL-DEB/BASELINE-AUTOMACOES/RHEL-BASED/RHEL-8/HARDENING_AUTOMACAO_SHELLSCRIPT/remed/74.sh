#!/usr/bin/env bash
echo "[74 - 78] Verificar sincronização de tempo e serviços desnecessários"

# 74 - Garantir time sync via chronyd
echo "[74] Garantindo sincronização de tempo com chrony"
if ! rpm -q chrony &>/dev/null; then
  yum install -y chrony
fi
systemctl enable chronyd --now

# 75 - Garantir presença de configuração
echo "[75] Verificando /etc/chrony.conf"
[ ! -s /etc/chrony.conf ] && echo "# created by HITSS" > /etc/chrony.conf

# 76 - Verificar UID do chronyd
echo "[76] Verificando execução de chronyd"
chrony_uid=$(ps -eo user,comm | grep chronyd | awk '{print $1}')
if [ "$chrony_uid" == "root" ]; then
  echo "⚠️ chronyd está rodando como root. Recomenda-se revisar a configuração de segurança do serviço."
else
  echo "✅ chronyd roda como usuário não-root ($chrony_uid)"
fi

# 77 - Desabilitar autofs
echo "[77] Desabilitando autofs se presente"
systemctl disable autofs --now 2>/dev/null

# 78 - Desabilitar avahi-daemon
echo "[78] Desabilitando avahi-daemon se presente"
systemctl disable avahi-daemon --now 2>/dev/null