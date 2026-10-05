#!/usr/bin/env bash

# HITSS 10 - 35 - Remediação orientativa para particionamento e opções de montagem
# Este script é educativo e não aplica alterações.

cat <<EOF
[10 - 35] Remediação educativa: Particionamento e opções de montagem
Este script NÃO aplica mudanças automaticamente. Use como guia para configuração manual.
Recomendação: utilize partições separadas com as seguintes opções de montagem:
  /tmp               → nodev,nosuid,noexec
  /dev/shm           → nodev,nosuid,noexec
  /home              → nodev
  /var               → nodev,nosuid
  /var/tmp           → nodev,nosuid,noexec
  /var/log           → nodev,nosuid,noexec
  /var/log/audit     → nodev,nosuid,noexec
Validação:
  findmnt -kn [ponto] | grep -E 'nodev|nosuid|noexec'
Exemplo de entrada no /etc/fstab:
  tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0
Aplicar temporariamente (até reboot):
  mount -o remount,nodev,nosuid,noexec /tmp
Notas:
  - Use 'lsblk -f' para identificar partições e sistemas de arquivos
  - Edite o /etc/fstab com cautela
  - Reinicie o sistema após alterações permanentes
⚠️ Atenção: configurações incorretas podem impedir o boot!
✅ Execute em ambiente controlado ou com console de recuperação disponível.
EOF
exit 0