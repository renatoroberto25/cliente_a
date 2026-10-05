#!/usr/bin/env bash
echo "[46-50] Remediação SELinux - Servidores baseados em RHEL 8"

selinux_config="/etc/selinux/config"
datahora="$(date +%F_%H%M%S)"

# 46 - Instalar libselinux se ausente
echo "[46] Garantir que o pacote libselinux esteja instalado"
if ! rpm -q libselinux &>/dev/null; then
  echo "⚠️ libselinux ausente, instalando..."
  dnf install -y libselinux || echo "❌ Falha ao instalar libselinux"
else
  echo "libselinux já instalado"
fi

# 47 - Não permitir selinux=0 no GRUB (não altera, só avisa)
echo "[47] Verificar se o SELinux está desabilitado no GRUB (selinux=0)"
if grep -q 'selinux=0' /etc/default/grub; then
  echo "⚠️ Entrada 'selinux=0' encontrada no GRUB."
  echo "Remoção **não automatizada**. Execute manualmente:"
  echo "   sed -i 's/selinux=0//g' /etc/default/grub && grub2-mkconfig -o /boot/grub2/grub.cfg"
else
  echo "GRUB não contém 'selinux=0'"
fi

# 48 - Garantir SELINUXTYPE=targeted (aplica se necessário)
echo "[48] Garantir que SELINUXTYPE esteja como targeted ou mls"
if ! grep -Eq '^\s*SELINUXTYPE=(targeted|mls)' "$selinux_config"; then
  echo "⚠️ SELINUXTYPE não conforme. Corrigindo..."
  cp "$selinux_config" "${selinux_config}.bak_${datahora}"
  sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' "$selinux_config" || echo "❌ Falha ao ajustar SELINUXTYPE"
else
  echo "SELINUXTYPE já configurado corretamente"
fi

# 49 - Verificar SELINUX=disabled (não altera, só avisa)
echo "[49] Verificar se o modo do SELinux está desabilitado"
if grep -q '^SELINUX=disabled' "$selinux_config"; then
  echo "⚠️ SELINUX=disabled detectado."
  echo "Corrija manualmente para permissive ou enforcing, seguido de relabelling:"
  echo "   sed -i 's/^SELINUX=disabled/SELINUX=permissive/' $selinux_config"
  echo "   touch /.autorelabel && reboot"
else
  echo "SELINUX está ativo (permissive ou enforcing)"
fi

# 50 - Garantir SELINUX=enforcing (aplica se já não for enforcing, mas não altera se estiver disabled)
echo "[50] Verificar se o SELinux está em modo enforcing"
if grep -q '^SELINUX=disabled' "$selinux_config"; then
  echo "⚠️ Modo SELINUX=disabled — não seguro alterar via script."
elif grep -q '^SELINUX=enforcing' "$selinux_config"; then
  echo "SELINUX já configurado como enforcing"
else
  echo "⚠️ Ajustando SELINUX para enforcing"
  cp "$selinux_config" "${selinux_config}.bak_${datahora}_enforcing"
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' "$selinux_config"
fi
