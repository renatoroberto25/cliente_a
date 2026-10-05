#!/usr/bin/env bash
# [39–46] Remediação HITSS - SELinux e serviços relacionados (Servidores baseados em RHEL 7)
# Não instala pacotes; apenas corrige o que já existe.
set -euo pipefail

echo -e "\n[39] Verificar se o SELinux está instalado"
rpm -q libselinux &>/dev/null && echo "✅ SELinux instalado." || echo "⚠️ SELinux não encontrado. Instalação manual se aplicável."

echo -e "\n[40] Garantir que SELinux não esteja desabilitado no bootloader"
for f in $(find /boot /boot/efi /etc -type f -name 'grub*.cfg' -o -name 'grub' 2>/dev/null); do
  cp -a "$f" "$f.bak.$(date +%F_%H%M%S)" && sed -i 's/\s*selinux=0//g; s/\s*enforcing=0//g' "$f"
done
command -v grub2-mkconfig &>/dev/null && grub2-mkconfig -o "$(dirname $(find /boot /boot/efi -type f -name 'grub*.cfg' | head -n1))/grub.cfg" >/dev/null 2>&1
grep -Eiq 'selinux=0|enforcing=0' $(find /boot /boot/efi /etc -type f -name 'grub*.cfg' 2>/dev/null | head -n1) && echo "⚠️ Bootloader ainda contém parâmetros SELinux=0" || echo "✅ Bootloader sem parâmetros que desativem SELinux."

echo -e "\n[41] Garantir que uma política SELinux esteja configurada"
cfg="/etc/selinux/config"
[ -f "$cfg" ] && cp -a "$cfg" "$cfg.bak.$(date +%F_%H%M%S)" || touch "$cfg"
grep -q '^SELINUXTYPE=' "$cfg" || echo "SELINUXTYPE=targeted" >> "$cfg"
echo "✅ Política SELinux configurada (targeted)."

echo -e "\n[42] Garantir que SELinux esteja ativo (enforcing ou permissive)"
selinuxenabled 2>/dev/null && getenforce | grep -Eq 'Enforcing|Permissive' && echo "✅ Modo atual: $(getenforce)" || echo "⚠️ SELinux desativado — ajuste manual exigido."

echo -e "\n[43] Garantir que SELinux esteja em modo enforcing"
[ -f "$cfg" ] && sed -i '/^SELINUX=/d' "$cfg"; echo "SELINUX=enforcing" >> "$cfg"; echo "✅ SELINUX=enforcing configurado em $cfg"

echo -e "\n[44] Verificar serviços não confinados"
ps -eZ | grep -q unconfined_service_t && echo "⚠️ Existem serviços não confinados — análise manual necessária." || echo "✅ Nenhum serviço não confinado detectado."

echo -e "\n[45] Remover SETroubleshoot se instalado"
rpm -q setroubleshoot &>/dev/null && yum remove -y setroubleshoot || echo "✅ SETroubleshoot ausente."

echo -e "\n[46] Remover mcstrans se instalado"
rpm -q mcstrans &>/dev/null && yum remove -y mcstrans || echo "✅ mcstrans ausente."