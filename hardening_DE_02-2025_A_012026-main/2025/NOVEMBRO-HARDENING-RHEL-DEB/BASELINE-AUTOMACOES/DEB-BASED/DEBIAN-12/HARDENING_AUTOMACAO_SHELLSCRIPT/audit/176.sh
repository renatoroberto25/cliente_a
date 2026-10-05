#!/usr/bin/env bash

echo -e "\n[176] Verifique se UsePAM está habilitado no sshd"
sshd -T 2>/dev/null | grep -iq '^usepam yes$' && echo "✅ APROVADO" || echo "⚠️ REPROVADO"