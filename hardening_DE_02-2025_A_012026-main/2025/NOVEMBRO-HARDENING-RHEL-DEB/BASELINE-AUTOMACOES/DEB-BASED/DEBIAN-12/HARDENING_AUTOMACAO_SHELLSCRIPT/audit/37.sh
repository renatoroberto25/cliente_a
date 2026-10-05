#!/usr/bin/env bash
echo -e "\n[37] Ensure GPG keys are configured"

if find /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d -type f -name '*.gpg' 2>/dev/null | grep -q .; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi
