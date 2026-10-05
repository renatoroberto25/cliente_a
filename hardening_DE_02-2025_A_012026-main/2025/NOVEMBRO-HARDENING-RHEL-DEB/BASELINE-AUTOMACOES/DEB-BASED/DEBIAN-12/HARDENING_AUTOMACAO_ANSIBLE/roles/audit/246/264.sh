#!/usr/bin/env bash
echo "[264–273] Auditoria de Regras do auditd"

echo -e "\n[264] – session initiation"
(auditctl -l 2>/dev/null | grep -Eq '/var/run/utmp|/var/log/wtmp|/var/log/btmp') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[265] – login/logout"
(auditctl -l 2>/dev/null | grep -Eq '/var/log/lastlog|/var/run/faillock') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[266] – file deletion"
(auditctl -l 2>/dev/null | grep -Eq 'unlink|rename') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[267] – MAC policy"
(auditctl -l 2>/dev/null | grep -Eq '/etc/apparmor|/etc/selinux') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

#tenable usar essa lógica:
#echo -e "\n[268] – chcon"
#(auditctl -l 2>/dev/null | grep -q '/usr/bin/chcon') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#echo -e "\n[269] – setfacl"
#(auditctl -l 2>/dev/null | grep -q '/usr/bin/setfacl') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"
#echo -e "\n[270] – chacl" 
#(auditctl -l 2>/dev/null | grep -q '/usr/bin/chacl') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[268] – chcon"
(auditctl -l 2>/dev/null | grep -q '/usr/bin/chcon') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[269] – setfacl"
(auditctl -l 2>/dev/null | grep -q '/usr/bin/setfacl') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[270] – chacl"
(auditctl -l 2>/dev/null | grep -q '/usr/bin/chacl') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[271] – usermod"
(auditctl -l 2>/dev/null | grep -q '/usr/sbin/usermod') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[272] – kernel module load/unload"
(auditctl -l 2>/dev/null | grep -Eq 'init_module|finit_module|delete_module') && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[273] – configuração imutável"
(auditctl -s 2>/dev/null | grep -q "enabled.*2") && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

#apt install auditd audispd-plugins -y