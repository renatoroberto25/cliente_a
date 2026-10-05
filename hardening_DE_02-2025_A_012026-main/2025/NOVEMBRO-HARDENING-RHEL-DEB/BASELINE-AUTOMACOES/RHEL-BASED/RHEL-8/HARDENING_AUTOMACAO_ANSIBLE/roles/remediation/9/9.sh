#!/usr/bin/env bash

# HITSS 9 - 34: Particionamento e opções de montagem
cat <<EOF
[9 - 34] Particionamento e opções de montagem

❗ Este script NÃO aplica mudanças automaticamente.
   Ele serve como orientação para ajustes manuais e seguros.

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

Atenção:
  - Configurações incorretas podem impedir o boot do sistema!
  - Teste sempre em ambiente controlado ou com console de recuperação disponível.

✅ Aplique essas recomendações nas imagens base e pipelines de provisionamento de servidores.
EOF

exit 0
