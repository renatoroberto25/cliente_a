#!/usr/bin/env bash
echo "[229 - 242] Auditoria de Regras de Auditoria (auditd)"

RULE_FILES="/etc/audit/rules.d/*.rules /etc/audit/audit.rules"

# 229
echo "[229] Alterações em sudoers devem ser auditadas"
if (egrep -iq 'sudoers' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'sudoers'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 230
echo "[230] Ações como outro usuário devem ser auditadas"
if (egrep -iq 'scope' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'scope'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 231
echo "[231] Eventos que modificam o log do sudo devem ser auditados"
if (egrep -iq 'sudo.log' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'sudo.log'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 232
echo "[232] Alterações em data/hora devem ser auditadas"
if (egrep -iq 'adjtimex|settimeofday|clock_settime|localtime' $RULE_FILES 2>/dev/null || \
    auditctl -l | egrep -iq 'adjtimex|settimeofday|clock_settime|localtime'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 233
echo "[233] Alterações no ambiente de rede devem ser auditadas"
if (egrep -iq 'sethostname|setdomainname|hosts|issue|network' $RULE_FILES 2>/dev/null || \
    auditctl -l | egrep -iq 'sethostname|setdomainname|hosts|issue|network'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 234
echo "[234] Uso de comandos privilegiados deve ser auditado"
if (egrep -iq 'execve' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'execve'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 235
echo "[235] Acessos negados a arquivos devem ser auditados"
if (egrep -iq 'EACCES|EPERM' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'EACCES|EPERM'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 236
echo "[236] Alterações em contas/grupos devem ser auditadas"
if (egrep -iq 'passwd|group|shadow|gshadow|opasswd|pam' $RULE_FILES 2>/dev/null || \
    auditctl -l | egrep -iq 'passwd|group|shadow|gshadow|opasswd|pam'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 237
echo "[237] Alterações em permissões de arquivos devem ser auditadas"
if (egrep -iq 'chmod|chown|setxattr' $RULE_FILES 2>/dev/null || \
    auditctl -l | egrep -iq 'chmod|chown|setxattr'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 238
echo "[238] Montagens de sistemas de arquivos devem ser auditadas"
if (egrep -iq 'mount' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'mount'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 239
echo "[239] Informações de sessão devem ser auditadas"
if (egrep -iq 'utmp|wtmp|btmp' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'utmp|wtmp|btmp'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 240
echo "[240] Eventos de login/logout devem ser auditados"
if (egrep -iq 'lastlog|faillock' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'lastlog|faillock'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 241
echo "[241] Exclusão de arquivos deve ser auditada"
if (egrep -iq 'unlink|rename' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'unlink|rename'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

# 242
echo "[242] Alterações em SELinux (MAC) devem ser auditadas"
if (egrep -iq 'selinux' $RULE_FILES 2>/dev/null || auditctl -l | egrep -iq 'selinux'); then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi