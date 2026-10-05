#!/usr/bin/env bash
echo "[143 - 159] - SSH - Configuração do sshd_config"

echo -e "\n[143] Verifique se os Ciphers do sshd estão configurados"
grep -Eq '^\s*Ciphers\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[144] Verifique se ClientAliveInterval e ClientAliveCountMax estão configurados"
( grep -Eq '^\s*ClientAliveInterval\s+[0-9]+' /etc/ssh/sshd_config && grep -Eq '^\s*ClientAliveCountMax\s+[0-9]+' /etc/ssh/sshd_config ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[145] Verifique se o DisableForwarding está ativado"
grep -Eq '^\s*DisableForwarding\s+yes' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[146] Verifique se HostbasedAuthentication está desabilitado"
grep -Eq '^\s*HostbasedAuthentication\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[147] Verifique se IgnoreRhosts está ativado"
grep -Eq '^\s*IgnoreRhosts\s+yes' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[148] Verifique se os KexAlgorithms estão configurados"
grep -Eq '^\s*KexAlgorithms\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[149] Verifique se LoginGraceTime está configurado"
grep -Eq '^\s*LoginGraceTime\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[150] Verifique se LogLevel está configurado"
grep -Eq '^\s*LogLevel\s+\w+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[151] Verifique se os MACs estão configurados"
grep -Eq '^\s*MACs\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[152] Verifique se MaxAuthTries está configurado"
grep -Eq '^\s*MaxAuthTries\s+[0-9]+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[153] Verifique se MaxSessions está configurado"
grep -Eq '^\s*MaxSessions\s+[0-9]+' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[154] Verifique se MaxStartups está configurado"
grep -Eq '^\s*MaxStartups\s+.+$' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[155] Verifique se PermitEmptyPasswords está desabilitado"
grep -Eq '^\s*PermitEmptyPasswords\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[156] Verifique se PermitRootLogin está desabilitado"
grep -Eq '^\s*PermitRootLogin\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[157] Verifique se PermitUserEnvironment está desabilitado"
grep -Eq '^\s*PermitUserEnvironment\s+no' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[158] Verifique se UsePAM está ativado"
grep -Eq '^\s*UsePAM\s+yes' /etc/ssh/sshd_config && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[159] Verifique se o parâmetro CRYPTO_POLICY não está sendo usado no sshd_config"
grep -Eq '^\s*Include\s+/etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config && grep -rEq '^\s*CRYPTO_POLICY=' /etc/ssh/sshd_config.d/ && echo "⚠️ REPROVADO" || echo "✅ APROVADO"