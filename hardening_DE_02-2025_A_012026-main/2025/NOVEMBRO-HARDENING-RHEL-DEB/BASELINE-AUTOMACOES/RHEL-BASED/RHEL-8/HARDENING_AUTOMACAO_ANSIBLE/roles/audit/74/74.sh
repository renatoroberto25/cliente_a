#!/usr/bin/env bash
echo "[74 - 78] Verificar sincronização de tempo e serviços desnecessários"

# 74 - Time sync ativo
echo "[74] Verificando sincronização de tempo"
timed_status=$(timedatectl | grep "System clock synchronized" | grep -q yes && echo "✅ APROVADO" || echo "⚠️ REPROVADO")
echo "$timed_status"

# 75 - chrony configurado
echo "[75] Verificando se chrony está configurado"
[ -s /etc/chrony.conf ] && echo "✅ APROVADO - chrony.conf presente" || echo "⚠️ REPROVADO - chrony.conf ausente ou vazio"

# 76 - chronyd não como root
echo "[76] Verificando se chronyd roda como usuário não-root"
ps -eo user:20,comm | grep -w chronyd | grep -vq root && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

# 77 - autofs não em uso
echo "[77] Verificando se autofs está desabilitado"
systemctl is-enabled autofs &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"

# 78 - avahi-daemon não em uso
echo "[78] Verificando se avahi-daemon está desabilitado"
systemctl is-enabled avahi-daemon &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO"