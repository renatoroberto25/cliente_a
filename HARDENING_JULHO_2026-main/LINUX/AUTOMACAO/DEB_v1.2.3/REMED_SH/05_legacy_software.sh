#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"


purge_packages 46 'Prelink removido' prelink
purge_packages 47 'xinetd removido' xinetd
