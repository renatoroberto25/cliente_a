#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"

disable_wireless() { local id="$1" name="$2" m file=/etc/modprobe.d/99-hitss-wireless.conf; echo "[$id] $name"; disable_unit "$id" "$name" bluetooth.service; ensure_file "$file"; backup_file "$file"; for m in bluetooth btusb cfg80211 mac80211; do ensure_line "$file" "install $m /bin/false"; ensure_line "$file" "blacklist $m"; done; echo "OK: bloqueio persistido"; }

disable_wireless 89 'Wireless e bluetooth ausentes'
