#!/usr/bin/env bash

echo "Remediação 288 - Revisão de arquivos SUID e SGID"

find / -xdev -perm -4000 -type f -exec echo "[SUID] {}" \; 2>/dev/null
find / -xdev -perm -2000 -type f -exec echo "[SGID] {}" \; 2>/dev/null

echo "[!] Nenhuma ação automática aplicada. Esta remediação exige revisão manual."