#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

enable_time() { local id="$1" name="$2" u; echo "[$id] $name"; for u in chrony.service ntpsec.service ntp.service systemd-timesyncd.service; do if systemctl list-unit-files "$u" --no-legend 2>/dev/null | grep -q .; then backup_unit "$u"; systemctl enable --now "$u" >/dev/null 2>&1 && echo "OK: $u" || echo "WARN: $u"; return; fi; done; echo "SKIP: nenhum mecanismo instalado"; }
single_time() { local id="$1" name="$2" active=() u; echo "[$id] $name"; for u in chrony.service ntpsec.service ntp.service systemd-timesyncd.service; do systemctl is-active --quiet "$u" 2>/dev/null && active+=("$u"); done; (( ${#active[@]} <= 1 )) && echo "OK: mecanismo unico" || echo "SKIP: ativos: ${active[*]}; selecao exige politica"; }

enable_time 48 'Time sync ativo'
manual 49 'Fontes NTP confiáveis' 'Configurar no daemon ativo somente os servidores NTP aprovados.'
enable_time 50 'NTP desde o boot'
single_time 79 'Sincronização de tempo única'
