#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.remed_common"


manual 77 'Assinaturas dos repositórios APT verificadas' 'Revisar repositórios e manter somente chaves e fontes aprovadas.'
manual 78 'Atualizações de segurança aplicadas' 'Aplicar as atualizações em janela aprovada e validar serviços e reboot.'
