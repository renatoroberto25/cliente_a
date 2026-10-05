#!/usr/bin/env bash
set -euo pipefail

echo -e "\n[HARDENING] Remediações 183–197 (Integridade e Permissões – RHEL 7)"

backup() {
  [ -f "$1" ] && cp -a "$1" "$1.bkp_$(date +%Y%m%d_%H%M%S)"
}

############################################
# 183 – AIDE (somente se instalado)
############################################
echo -e "\n[183] AIDE – verificação periódica"

if rpm -q aide >/dev/null 2>&1; then
  if ! grep -REq '\baide\b' /etc/cron.* 2>/dev/null; then
    echo "0 3 * * * root /usr/sbin/aide --check" > /etc/cron.d/aide-check
    chmod 600 /etc/cron.d/aide-check
    echo " agendamento AIDE criado"
  else
    echo " AIDE já agendado"
  fi
else
  echo " AIDE não instalado – Validar manualmente"
fi

############################################
# 185–192 – Permissões arquivos críticos
############################################
echo -e "\n[185–192] Permissões arquivos sensíveis"

chmod 644 /etc/passwd
[ -f /etc/passwd- ] && chmod 644 /etc/passwd-

chown root:root /etc/shadow
chmod 000 /etc/shadow

[ -f /etc/shadow- ] && { chown root:root /etc/shadow-; chmod 000 /etc/shadow-; }

chown root:root /etc/gshadow
chmod 000 /etc/gshadow

[ -f /etc/gshadow- ] && { chown root:root /etc/gshadow-; chmod 000 /etc/gshadow-; }

chmod 644 /etc/group
[ -f /etc/group- ] && chmod 644 /etc/group-

############################################
# 194 – opasswd
############################################
echo -e "\n[194] /etc/security/opasswd"

if [ -f /etc/security/opasswd ]; then
  chown root:root /etc/security/opasswd
  chmod 600 /etc/security/opasswd
fi

############################################
# 195 / 197 – Arquivos órfãos (somente reporta)
############################################
echo -e "\n[195–197] Arquivos órfãos"

if find / -xdev -nouser -o -nogroup 2>/dev/null | grep -q .; then
  echo " ATENÇÃO: arquivos órfãos detectados – avaliar manualmente"
else
  echo " nenhum arquivo órfão detectado"
fi

############################################
# 196 – Sticky bit global
############################################
echo -e "\n[196] Sticky bit world-writable"

find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null -exec chmod +t {} \;

echo -e "\n[OK] Bloco 183–197 aplicado"
