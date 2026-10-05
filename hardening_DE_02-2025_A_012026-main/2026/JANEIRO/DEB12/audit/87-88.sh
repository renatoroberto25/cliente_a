#!/usr/bin/env bash

echo -e "\n[87] Assinaturas de pacotes habilitadas"
(! grep -REq 'Acquire::Allow(Insecure|DowngradeToInsecure)Repositories\s+"true"' /etc/apt/apt.conf /etc/apt/apt.conf.d/* 2>/dev/null && ! grep -REq '\btrusted\s*=\s*yes\b' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null ) && echo "✅ APROVADO" || echo "⚠️ REPROVADO"

echo -e "\n[88] Patches de segurança aplicados"
( apt list --upgradable 2>/dev/null | grep -vq '^Listing' && echo "⚠️ REPROVADO" || echo "✅ APROVADO" )
