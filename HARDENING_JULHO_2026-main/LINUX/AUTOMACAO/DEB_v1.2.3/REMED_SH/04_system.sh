#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

secure_sticky() { echo "[$1] $2"; backup_metadata "$3"; chmod 1777 "$3" && chown root:root "$3" && echo "OK: $3" || echo "WARN: $3"; }

manual 38 'Sticky world-writable' 'Revisar os diretórios world-writable e aplicar sticky bit somente nos aprovados.'
secure_sticky 39 'Sticky /tmp' /tmp
secure_sticky 40 'Sticky /var/tmp' /var/tmp
secure_sticky 41 'Sticky /dev/shm' /dev/shm
disable_unit 42 'Autofs desabilitado' autofs.service
