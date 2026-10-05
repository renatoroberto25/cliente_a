#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"


purge_packages 63 'Servidor NIS removido' nis
purge_packages 64 'Servidor Telnet removido' telnetd
manual 65 'MTA local only' 'Configurar o MTA instalado para escutar somente no endereço local.'
purge_packages 69 'Cliente NIS removido' nis
purge_packages 70 'Cliente rsh removido' rsh-client
purge_packages 71 'Cliente talk removido' talk
purge_packages 72 'Cliente telnet removido' telnet
purge_packages 75 'Servidor TFTP removido' tftpd-hpa
manual 76 'PolicyKit sem autorizações locais irrestritas' 'Revisar regras locais e remover somente concessões irrestritas não aprovadas.'
