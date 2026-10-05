#!/usr/bin/env bash
echo "219 Ensure journald log file rotation is configured"
required_keys=(SystemMaxUse SystemKeepFree RuntimeMaxUse RuntimeKeepFree MaxFileSec)
missing_keys=()

echo "Auditing journald effective configuration..."

for key in "${required_keys[@]}"; do
    if ! systemd-analyze cat-config systemd/journald.conf | grep -Eiq "^\s*$key\s*="; then
        missing_keys+=("$key")
    fi
done

if [ ${#missing_keys[@]} -eq 0 ]; then
echo "✅ [APROVADO]: Todas as configurações de rotação de log necessárias estão efetivamente definidas"
    systemd-analyze cat-config systemd/journald.conf | grep -E '(SystemMaxUse|SystemKeepFree|RuntimeMaxUse|RuntimeKeepFree|MaxFileSec)'
else
echo "⚠️[REPROVADO]: As seguintes configurações não estão efetivamente definidas:"
    for key in "${missing_keys[@]}"; do
echo "  - $key"
    done
echo -e "\n  >> Recomendação: defina-os via /etc/systemd/journald.conf ou drop-in em /etc/systemd/journald.conf.d/"
    for key in "${missing_keys[@]}"; do
echo "  $key=VALUE"
    done
fi