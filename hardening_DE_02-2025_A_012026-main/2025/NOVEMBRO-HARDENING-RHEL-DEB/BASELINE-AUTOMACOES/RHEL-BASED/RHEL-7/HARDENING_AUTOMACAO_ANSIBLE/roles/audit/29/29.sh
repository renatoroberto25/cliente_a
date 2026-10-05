#!/usr/bin/env bash
echo -e "\n 27	Ensure GPG keys are configured (Manual)"

echo -e "\n 28	Ensure package manager repositories are configured (Manual)"

echo -e "\n 29 Ensure gpgcheck is globally activated"
grep -Pq '^\s*gpgcheck\s*=\s*1' /etc/yum.conf && \
! grep -RPq '^\s*gpgcheck\s*=\s*0' /etc/yum.repos.d/ && \
echo "✅ APROVADO" || echo "⚠️ REPROVADO"