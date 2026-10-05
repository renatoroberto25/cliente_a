#!/usr/bin/env bash

echo " [146 a 148] Corrigir política de criptografia do SSH via crypto-policies"

policy_dir="/etc/crypto-policies/policies/modules"
policy_file="$policy_dir/NO-SSH-WEAK.pmod"
data=$(date +%Y%m%d%H%M%S)

[ ! -d "$policy_dir" ] && echo "⚠️ Diretório $policy_dir não encontrado. Abortando." && exit 1
[ -f "$policy_file" ] && cp -p "$policy_file" "$policy_file.bak.$data"
touch "$policy_file"

add_rule() {
  local rule="$1"
  grep -Fqx "$rule" "$policy_file" || echo "$rule" >> "$policy_file"
}

# Comentários (inseridos apenas uma vez)
grep -q '# This is a subpolicy to disable weak ciphers' "$policy_file" || {
  echo "# This is a subpolicy to disable weak ciphers" >> "$policy_file"
  echo "# for the SSH protocol (libssh and OpenSSH)" >> "$policy_file"
}

add_rule "cipher@SSH = -3DES-CBC -AES-128-CBC -AES-192-CBC -AES-256-CBC -CHACHA20-POLY1305"
add_rule "hash = -SHA1"
add_rule "sign = -*-SHA1"
add_rule "sha1_in_certs = 0"

grep -q '# This is a subpolicy to disable weak MACs' "$policy_file" || {
  echo "# This is a subpolicy to disable weak MACs" >> "$policy_file"
  echo "# for the SSH protocol (libssh and OpenSSH)" >> "$policy_file"
}

add_rule "mac@SSH = -HMAC-MD5* -UMAC-64* -UMAC-128*"

update-crypto-policies --set DEFAULT:NO-SSH-WEAK &>/dev/null
applied=$(update-crypto-policies --show)

if [[ "$applied" == *"DEFAULT:NO-SSH-WEAK"* ]]; then
  echo "✅ [APROVADO] Política aplicada: $applied"
else
  echo "⚠️ [REPROVADO] Política não aplicada corretamente: $applied"
fi

echo -e "\n✅ Remediação finalizada"
exit 0