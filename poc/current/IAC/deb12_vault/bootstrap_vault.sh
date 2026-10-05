#!/bin/bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-https://192.168.56.200:8200}"
export VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

: "${VAULT_TOKEN:?Exporte VAULT_TOKEN com o token administrativo}"

SERVICE_USER="${SERVICE_USER:-renato}"
SERVICE_PASSWORD="${SERVICE_PASSWORD:-C9p5au8naa@2025}"

vault status >/dev/null
vault secrets list -format=json | grep -q '"secret/"' || vault secrets enable -path=secret kv-v2
vault auth list -format=json | grep -q '"approle/"' || vault auth enable approle

for target in ol6 ol10; do
  vault kv put "secret/tenable/$target" \
    username="$SERVICE_USER" \
    password="$SERVICE_PASSWORD"

  policy="tenable-$target"
  policy_file="/tmp/$policy.hcl"

  printf 'path "secret/data/tenable/%s" {\n  capabilities = ["read"]\n}\n' "$target" > "$policy_file"
  vault policy write "$policy" "$policy_file"
  vault write "auth/approle/role/$policy" \
    token_policies="$policy" \
    token_ttl=1h \
    token_max_ttl=4h

  echo "===== $target ====="
  vault read "auth/approle/role/$policy/role-id"
  vault write -f "auth/approle/role/$policy/secret-id"
done
