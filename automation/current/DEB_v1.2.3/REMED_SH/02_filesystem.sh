#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"


manual 23 'Partição dedicada para /tmp' 'Criar a partição, migrar os dados e ajustar /etc/fstab em janela de manutenção.'
manual 24 'Partição dedicada para /dev/shm' 'Definir o tmpfs de /dev/shm e ajustar /etc/fstab conforme a carga do servidor.'
manual 25 'Partição dedicada para /var' 'Criar a partição, migrar /var e validar serviços e boot em janela de manutenção.'
manual 26 'Partição dedicada para /var/tmp' 'Criar a partição, migrar /var/tmp e validar a montagem em janela de manutenção.'
manual 27 'Partição dedicada para /var/log' 'Criar a partição, migrar os logs e validar os serviços de logging.'
manual 28 'Partição dedicada para /var/log/audit' 'Criar a partição, migrar os logs e validar o auditd.'
manual 29 'Partição dedicada para /home' 'Criar a partição, migrar os diretórios e preservar ownership e permissões.'
manual 30 'Partição dedicada para /historico' 'Definir o volume, migrar o conteúdo e ajustar /etc/fstab.'
manual 31 'Partição dedicada para /crash' 'Definir o volume conforme o crash dump e ajustar /etc/fstab.'
manual 32 'Partição dedicada para /UNIX' 'Definir o volume, migrar o conteúdo e ajustar /etc/fstab.'
manual 33 'Nodev removíveis' 'Revisar as montagens removíveis autorizadas e aplicar nodev em /etc/fstab.'
manual 34 'Nodev partições críticas' 'Validar o layout e aplicar nodev apenas nas partições compatíveis.'
manual 35 'Segurança /var/log' 'Validar a aplicação e ajustar as opções de montagem de /var/log.'
manual 36 'Segurança audit log' 'Validar o auditd e ajustar as opções de montagem de /var/log/audit.'
manual 37 'Segurança /home' 'Validar usuários e aplicações e ajustar as opções de montagem de /home.'
