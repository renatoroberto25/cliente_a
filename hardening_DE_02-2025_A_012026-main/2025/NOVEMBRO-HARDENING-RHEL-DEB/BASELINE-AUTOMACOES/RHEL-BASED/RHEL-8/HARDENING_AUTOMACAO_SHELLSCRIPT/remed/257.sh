#!/usr/bin/env bash
echo "[257-259] Remediação de permissões e propriedade das ferramentas de auditoria"

AUDIT_TOOLS="/sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules"

echo -e "\n[257] Ferramentas de auditoria devem ser 755 ou mais restritivas"
chmod 755 $AUDIT_TOOLS 2>/dev/null
if stat -Lc "%a %n" $AUDIT_TOOLS 2>/dev/null | awk '{if ($1+0 > 755) exit 1}'; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

echo -e "\n[258] Ferramentas de auditoria devem ser de propriedade do usuário root"
chown root $AUDIT_TOOLS 2>/dev/null
if stat -Lc "%U %n" $AUDIT_TOOLS 2>/dev/null | awk '{if ($1!="root") exit 1}'; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi

echo -e "\n[259] Ferramentas de auditoria devem pertencer ao grupo root"
chgrp root $AUDIT_TOOLS 2>/dev/null
if stat -Lc "%G %n" $AUDIT_TOOLS 2>/dev/null | awk '{if ($1!="root") exit 1}'; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi