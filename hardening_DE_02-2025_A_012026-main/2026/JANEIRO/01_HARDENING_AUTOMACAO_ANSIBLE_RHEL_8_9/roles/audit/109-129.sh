#!/usr/bin/env bash

echo -e "\n[109] Permissões seguras em sshd_config e chaves"
( stat -c %a /etc/ssh/sshd_config | grep -Eq '^(600|400)$' \
  && [ "$(stat -c %U:%G /etc/ssh)" = "root:root" ] ) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[110] Controle de acesso via Allow/Deny"
(grep -Eq '^[[:space:]]*(AllowUsers|DenyUsers|AllowGroups|DenyGroups)' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[111] LogLevel adequado"
(grep -Eq '^[[:space:]]*LogLevel[[:space:]]+(INFO|VERBOSE)' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[112] X11Forwarding desabilitado"
(grep -Eq '^[[:space:]]*X11Forwarding[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[113] MaxAuthTries limitado"
(grep -Eq '^[[:space:]]*MaxAuthTries[[:space:]]+[1-4]$' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[114] IgnoreRhosts habilitado"
(grep -Eq '^[[:space:]]*IgnoreRhosts[[:space:]]+yes' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[115] HostbasedAuthentication desabilitado"
(grep -Eq '^[[:space:]]*HostbasedAuthentication[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[116] PermitRootLogin restrito/desabilitado"
(grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+(no|prohibit-password)' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[117] PermitEmptyPasswords desabilitado"
(grep -Eq '^[[:space:]]*PermitEmptyPasswords[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[118] PermitUserEnvironment desabilitado"
(grep -Eq '^[[:space:]]*PermitUserEnvironment[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[119] UsePAM habilitado"
(grep -Eq '^[[:space:]]*UsePAM[[:space:]]+yes' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[120] Idle timeout configurado"
(grep -Eq '^[[:space:]]*ClientAliveInterval[[:space:]]+([1-9][0-9]|[1-2][0-9]{2}|300)$' /etc/ssh/sshd_config \
 && grep -Eq '^[[:space:]]*ClientAliveCountMax[[:space:]]+[1-3]$' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[121] LoginGraceTime curto"
(grep -Eq '^[[:space:]]*LoginGraceTime[[:space:]]+([1-9][0-9]|[1-5][0-9]{2})s?$' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[122] MaxStartups/MaxSessions limitados"
(grep -Eq '^[[:space:]]*MaxStartups[[:space:]]+.+$' /etc/ssh/sshd_config \
 && grep -Eq '^[[:space:]]*MaxSessions[[:space:]]+[1-9]+' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[123] AllowTcpForwarding restrito"
(grep -Eq '^[[:space:]]*AllowTcpForwarding[[:space:]]+no' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[124] Banner legal configurado"
(grep -Eq '^[[:space:]]*Banner[[:space:]]+/.*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[125] Ciphers fortes"
(grep -Eq '^[[:space:]]*Ciphers[[:space:]]+.*(chacha20|aes256).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[126] MACs fortes"
(grep -Eq '^[[:space:]]*MACs[[:space:]]+.*(hmac-sha2|umac).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[127] KexAlgorithms fortes"
(grep -Eq '^[[:space:]]*KexAlgorithms[[:space:]]+.*(curve25519|diffie-hellman-group-exchange-sha256).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[128] Preferência moderna - double check"
(grep -Eq '^[[:space:]]*(Ciphers|KexAlgorithms)[[:space:]]+.*(chacha20|curve25519).*' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[129] ForceCommand/Chroot"
(grep -Eq '^[[:space:]]*(ForceCommand|ChrootDirectory)[[:space:]]+' /etc/ssh/sshd_config) \
&& echo "✅ APROVADO" || echo "⚠️ REPROVADO"
