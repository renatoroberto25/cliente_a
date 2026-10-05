#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_dir="$root/HARDENING_CLARO_2026_S2-agosto_2026"

declare -A paths=(
    [AUDIT]=audits
    [BASELINES]=baselines
    [AUTOMACAO]=automation/current
    [UTILS]=tools/current
    [DOCS]=reference-docs/current
    [POC_6_10_AUTENTICADO]=poc/current
    [RESULTADOS]=results/current
)

for source_name in "${!paths[@]}"; do
    target="$root/${paths[$source_name]}"
    mkdir -p "$target"
    cp -a "$source_dir/$source_name/." "$target/"
done

cp -a "$source_dir/STATUS_TO_DO.md" "$root/STATUS_TO_DO.md"

printf 'Base oficial de agosto importada.\n'
