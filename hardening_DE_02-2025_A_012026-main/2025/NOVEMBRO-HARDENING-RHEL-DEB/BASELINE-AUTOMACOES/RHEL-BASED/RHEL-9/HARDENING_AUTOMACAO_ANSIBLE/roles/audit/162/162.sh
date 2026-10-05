#!/usr/bin/env bash
echo -e "\n 56 – Verificar se a política de criptografia ampla está definida no arquivo /etc/sysconfig/sshd"
arquivo="/etc/sysconfig/sshd"
if grep -Piq '^\h*CRYPTO_POLICY\h*=' "$arquivo"; then
   echo -e "\n⚠️  [REPROVADO]: Política de criptografia ampla está definida em $arquivo."
else
   echo -e "\n✅ [APROVADO]: Política de criptografia ampla NÃO está definida em $arquivo."
fi
echo -e "\n📄 Linhas ativas em $arquivo:"
grep -v '^\s*#' "$arquivo"
