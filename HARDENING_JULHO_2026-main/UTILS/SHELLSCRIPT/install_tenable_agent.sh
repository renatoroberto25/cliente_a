#!/bin/bash
#curl -H 'X-Key: 45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac' 'https://sensor.cloud.tenable.com/install/agent?name=$(hostname)&groups=LAB_RHEL' | bash
#curl -H 'X-Key: 45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac' 'https://sensor.cloud.tenable.com/install/agent?name=$(hostname)&groups=LINUX_DEFAULT' | bash
#set -euo pipefail

FLAG_FILE="/var/lib/tenable/nessusagent/.first-boot-done"
T_KEY="${T_KEY:-45b85b603d4f4ed07d445151eacc6db46715a19318c42da539327de707dedbac}"
T_HOST="${T_HOST:-sensor.cloud.tenable.com}"
T_PORT="${T_PORT:-443}"
T_GROUPS="${T_GROUPS:-LAB_RHEL}"
HNAME="${HNAME:-$(hostname -s 2>/dev/null || hostname)}"
CLI="/opt/nessus_agent/sbin/nessuscli"
EXPECTED_VERSION="${EXPECTED_VERSION:-11.1.4}"

log() { echo "[$1] $2"; }

if [ ! -x "$CLI" ]; then
  log "INFO" "Instalando Tenable Agent em $HNAME com updates em Stable (Delayed)"
  curl -fsSL -G -H "X-Key: $T_KEY" \
    --data-urlencode "name=$HNAME" \
    --data-urlencode "groups=$T_GROUPS" \
    --data-urlencode "auto_update=delay" \
    "https://$T_HOST/install/agent" | bash
  sleep 5
fi

$CLI fix --set agent_update_channel=stable

INSTALLED_VERSION=$($CLI -v 2>&1 | grep -oE '[0-9]+(\.[0-9]+){2}' | head -n1 || true)
if [ "$INSTALLED_VERSION" != "$EXPECTED_VERSION" ]; then
  log "ERRO" "Versão instalada: ${INSTALLED_VERSION:-desconhecida}; esperada: $EXPECTED_VERSION"
  exit 1
fi
log "OK" "Tenable Agent $INSTALLED_VERSION configurado em Stable (Delayed)"

systemctl enable --now nessusagent >/dev/null 2>&1 || \
  service nessusagent start >/dev/null 2>&1

STATUS=$($CLI agent status 2>&1 || true)
if [[ ! "$STATUS" =~ "Linked to: $T_HOST:$T_PORT" ]]; then
  log "WARN" "Configurando link com Tenable..."
  [[ "$STATUS" =~ "Linked to:" && ! "$STATUS" =~ "Linked to: None" ]] && \
    $CLI agent unlink --force
  $CLI agent link --key="$T_KEY" --host="$T_HOST" --port="$T_PORT" \
    --groups="$T_GROUPS" --name="$HNAME"
  sleep 5
fi

for i in {1..12}; do
  STATUS=$($CLI agent status 2>&1 || true)
  if [[ "$STATUS" =~ "Link status: Connected" ]]; then
    log "OK" "Agent conectado com sucesso!"
    mkdir -p "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"
    log "OK" "Flag de bootstrap registrada em $FLAG_FILE"
    echo "$STATUS"
    exit 0
  fi
  log "INFO" "Aguardando conexão ($i/12)..."
  sleep 10
done

log "ERRO" "Agent não conectou a tempo."
echo "$STATUS"
exit 1
