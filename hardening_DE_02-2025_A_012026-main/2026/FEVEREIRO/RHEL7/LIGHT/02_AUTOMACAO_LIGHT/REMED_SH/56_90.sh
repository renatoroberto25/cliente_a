#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 56–90 (Serviços e Pacotes – RHEL 7)"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

############################################
# 56,61,69–74,79–83,85 – REMOÇÃO PACOTES
############################################
echo -e "\n[Pacotes não requeridos]"

PKGS_REMOVE=(
  prelink
  xinetd
  dovecot
  cyrus-imapd
  samba
  squid
  ypserv
  telnet-server
  ypbind
  rsh
  talk
  telnet
  openldap-clients
  tftp-server
)

for p in "${PKGS_REMOVE[@]}"; do
  if rpm -q "$p" >/dev/null 2>&1; then
    yum -y remove "$p" >/devnull 2>&1 || true
    echo " removido: $p"
  fi
done

# X11 (match por prefixo)
X11_PKGS=$(rpm -qa | grep -E '^(xorg-x11|xorg-x11-server)' || true)
if [ -n "$X11_PKGS" ]; then
  yum -y remove $X11_PKGS >/dev/null 2>&1 || true
  echo " componentes X11 removidos"
fi

############################################
# 62,63,72,76–78 – DESABILITAR SERVIÇOS
############################################
echo -e "\n[Serviços desnecessários]"

SERVICES_DISABLE=(
  avahi-daemon
  cups
  snmpd
  nfs-server
  rpcbind
  rsyncd
)

for s in "${SERVICES_DISABLE[@]}"; do
  systemctl disable --now "$s" >/dev/null 2>&1 || true
  echo " desabilitado: $s (se presente)"
done

############################################
# 58,59,60,89 – SINCRONIZAÇÃO DE TEMPO
############################################]
echo -e "\n[Sincronização de tempo]"

if ! rpm -q chrony >/dev/null 2>&1; then
  yum -y install chrony >/dev/null 2>&1
fi

systemctl disable --now ntpd systemd-timesyncd >/dev/null 2>&1 || true
systemctl enable --now chronyd >/dev/null 2>&1 || true

CONF="/etc/chrony.conf"
backup "$CONF"

if ! grep -Eq '^\s*server\s+' "$CONF"; then
  echo "server pool.ntp.org iburst" >> "$CONF"
fi

systemctl restart chronyd >/dev/null 2>&1 || true
echo " chronyd ativo e configurado"

############################################
# 75 – MTA LOCAL ONLY
############################################
echo -e "\n[MTA local-only]"

if command -v postconf >/dev/null 2>&1; then
  postconf -e "inet_interfaces = localhost" >/dev/null 2>&1 || true
  systemctl restart postfix >/dev/null 2>&1 || true
  echo " postfix ajustado para localhost"
fi

############################################
# 86 – PolicyKit
############################################
echo -e "\n[86] PolicyKit – quarentena de regras permissivas"

POLKIT_DIR="/etc/polkit-1/rules.d"
QUAR_DIR="/root/polkit_quarantine"

mkdir -p "$QUAR_DIR"

# Função segura de detecção de regra permissiva
is_permissive_rule() {
    grep -Eq 'polkit\.Result\.YES' "$1"
}

# Itera apenas regras reais; ignora backups e arquivos já desativados
shopt -s nullglob
for f in "$POLKIT_DIR"/*.rules; do
    # ignorar regras já quarentenadas ou renomeadas
    case "$f" in
        *.disabled_*|*.bak|*.backup|*.old)
            continue
            ;;
    esac

    [ -f "$f" ] || continue

    if is_permissive_rule "$f"; then
        backup "$f"
        ts="$(date +%Y%m%d_%H%M%S)"
        new="${QUAR_DIR}/$(basename "$f").disabled_${ts}"
        mv "$f" "$new"
        echo " Regra movida para quarentena: $f -> $new"
    fi
done

echo -e "\n86 PolicyKit endurecido"

# Verificação idempotente pós-remediação
remaining=$(grep -REl 'polkit\.Result\.YES' "$POLKIT_DIR"/*.rules 2>/dev/null || true)

if [ -n "$remaining" ]; then
    echo "FAIL"
else
    echo "PASS"
fi


############################################
# 87 – GPGCHECK
############################################
echo -e "\n[GPGCheck obrigatório]"

for f in /etc/yum.repos.d/*.repo; do
  [ -f "$f" ] || continue
  backup "$f"
  if grep -q '^\s*gpgcheck' "$f"; then
    sed -i 's/^\s*gpgcheck\s*=.*/gpgcheck=1/' "$f"
  else
    echo "gpgcheck=1" >> "$f"
  fi
done

############################################
# 88 – ATUALIZAÇÕES DE SEGURANÇA
############################################
#echo -e "\n[Atualizações de segurança]"
#yum -y update --security >/dev/null 2>&1 || true
#echo " updates aplicados"

############################################
# 90 – CRON / AT RESTRITO
############################################
echo -e "\n[Cron e at restritos]"

echo "root" > /etc/cron.allow
echo "root" > /etc/at.allow
chmod 600 /etc/cron.allow /etc/at.allow
echo " cron/at restritos a root"
