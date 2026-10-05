#!/usr/bin/env bash

echo -e "\n[52] MAC (SELinux/AppArmor) ativo"
(getenforce 2>/dev/null | grep -Eq 'Enforcing|Permissive' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[53] Política MAC definida"
(sestatus 2>/dev/null | grep -q 'Loaded policy name' && echo "✅ APROVADO" || echo "⚠️ REPROVADO")

echo -e "\n[54] Serviços unconfined minimizados"
(ps -eZ | grep -q 'unconfined_service_t' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[55] Sem serviços sem restrições MAC"
(ps -eZ | grep -q 'unconfined_t' && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[56] Prelink removido"
(rpm -q prelink &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")

echo -e "\n[57] xinetd removido"
(rpm -q xinetd &>/dev/null && echo "⚠️ REPROVADO" || echo "✅ APROVADO")
