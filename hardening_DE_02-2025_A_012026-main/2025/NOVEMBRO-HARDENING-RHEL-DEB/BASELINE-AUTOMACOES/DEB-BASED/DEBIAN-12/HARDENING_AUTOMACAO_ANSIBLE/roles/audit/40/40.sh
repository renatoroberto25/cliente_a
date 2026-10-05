#!/usr/bin/env bash
echo -e "\n[40] Ensure AppArmor is installed"
(dpkg-query -s apparmor &>/dev/null) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[41] Ensure AppArmor is enabled in the bootloader configuration"
if grep -q "apparmor=1" /proc/cmdline && grep -q "security=apparmor" /proc/cmdline; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi


echo -e "\n[42] Ensure all AppArmor Profiles are in enforce or complain mode"
if apparmor_status 2>/dev/null | grep -q "profiles are loaded"; then
    if apparmor_status | grep -Eq "profiles are in enforce mode|profiles are in complain mode"; then
        echo "✅ APROVADO"
    else
        echo "⚠️ REPROVADO"
    fi
else
    echo "⚠️ REPROVADO"
fi

echo -e "\n[43] Ensure all AppArmor Profiles are enforcing"
if apparmor_status 2>/dev/null | grep -q "0 profiles are in complain mode"; then
    echo "✅ APROVADO"
else
    echo "⚠️ REPROVADO"
fi