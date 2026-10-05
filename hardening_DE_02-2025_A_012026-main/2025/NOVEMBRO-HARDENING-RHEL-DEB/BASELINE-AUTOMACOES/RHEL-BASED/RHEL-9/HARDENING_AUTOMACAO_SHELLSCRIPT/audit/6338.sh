#!/usr/bin/env bash
echo "252 Ensure events that modify user/group information are collected"

expected_rules=(
"-w /etc/group -p wa -k identity"
"-w /etc/passwd -p wa -k identity"
"-w /etc/gshadow -p wa -k identity"
"-w /etc/shadow -p wa -k identity"
"-w /etc/security/opasswd -p wa -k identity"
"-w /etc/nsswitch.conf -p wa -k identity"
"-w /etc/pam.conf -p wa -k identity"
"-w /etc/pam.d -p wa -k identity"
)

# Normalize função de comparação
normalize_rule() {
echo "$1" | tr -s ' ' | sed -E 's/ key=| -k/ -k/g' | sed 's/ *$//'
}

# Auditoria do disco
disk_rules_raw=$(awk '/^ *-w/ && (/\/etc\/group|\/etc\/passwd|\/etc\/gshadow|\/etc\/shadow|\/etc\/security\/opasswd|\/etc\/nsswitch.conf|\/etc\/pam.conf|\/etc\/pam.d/) && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules 2>/dev/null)

# Auditoria das regras carregadas
loaded_rules_raw=$(auditctl -l 2>/dev/null | awk '/^ *-w/ && (/\/etc\/group|\/etc\/passwd|\/etc\/gshadow|\/etc\/shadow|\/etc\/security\/opasswd|\/etc\/nsswitch.conf|\/etc\/pam.conf|\/etc\/pam.d/) && / +-p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)')

# Normalize
normalized_disk_rules=()
while read -r line; do
  [[ -n "$line" ]] && normalized_disk_rules+=("$(normalize_rule "$line")")
done <<< "$disk_rules_raw"

normalized_loaded_rules=()
while read -r line; do
  [[ -n "$line" ]] && normalized_loaded_rules+=("$(normalize_rule "$line")")
done <<< "$loaded_rules_raw"

# Função para checar regras
check_rules() {
  local label="$1"
  local -n rule_set=$2
  local missing=()

  for rule in "${expected_rules[@]}"; do
    found=false
    for candidate in "${rule_set[@]}"; do
      if [[ "$candidate" == "$rule" ]]; then
        found=true
        break
      fi
    done
    if ! $found; then
      missing+=("$rule")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
echo "✅ [APROVADO]: Todas as regras de $label estão presentes."
  else
echo "⚠️[REPROVADO]: Regras de $label ausentes ou incompletas:"
    for r in "${missing[@]}"; do
echo "  - $r"
    done
  fi
}

check_rules "auditoria no disco" normalized_disk_rules
check_rules "regras carregadas" normalized_loaded_rules