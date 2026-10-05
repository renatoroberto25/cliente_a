#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out="$root/docs/inventory.tsv"
aug="HARDENING_CLARO_2026_S2-agosto_2026"
jul="HARDENING_JULHO_2026-main"
old="hardening_DE_02-2025_A_012026-main"

mkdir -p "$root/docs"

declare -A aug_hashes
while IFS= read -r -d '' file; do
    hash=$(sha256sum "$file" | cut -d' ' -f1)
    aug_hashes[$hash]=1
done < <(find "$root/$aug" -type f -print0)

printf 'source\tpath\tcategory\tdecision\tsize_bytes\tsha256\n' > "$out"

for source in "$aug" "$jul" "$old"; do
    while IFS= read -r -d '' file; do
        path=${file#"$root/$source/"}
        hash=$(sha256sum "$file" | cut -d' ' -f1)
        size=$(stat -c %s "$file")
        upper=${path^^}

        if [[ $upper =~ (^|/)(AUDIT|AUDITS|BASELINE|BASELINES)(/|$) ]]; then
            category=audit_baseline
            [[ $source == "$aug" ]] && decision=official || decision=excluded_old_content
        elif [[ $upper == *ANSIBLE* || $upper == *AWX* ]]; then
            category=ansible
            [[ $source == "$aug" ]] && decision=current || decision=candidate
        elif [[ $upper == *IAC* ]]; then
            category=iac
            [[ $source == "$aug" ]] && decision=current || decision=candidate
        elif [[ $upper == *.SH ]]; then
            category=shell
            [[ $source == "$aug" ]] && decision=current || decision=candidate
        elif [[ $upper == *DASHBOARD* || $upper == *ONE-PAGE* ]]; then
            category=dashboard
            [[ $source == "$aug" ]] && decision=current || decision=candidate
        elif [[ $upper == *WINDOWS* || $upper == *.INF ]]; then
            category=windows
            [[ $source == "$aug" ]] && decision=current || decision=candidate
        elif [[ $upper == *.CSV || $upper == *.XLSX || $upper == *.HTML || $upper == *.PNG ]]; then
            category=result_data
            [[ $source == "$aug" ]] && decision=current_support || decision=review_data
        else
            category=documentation_other
            [[ $source == "$aug" ]] && decision=current_support || decision=review_legacy
        fi

        if [[ $source != "$aug" && -n ${aug_hashes[$hash]:-} ]]; then
            decision=duplicate_of_august
        fi

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$source" "$path" "$category" "$decision" "$size" "$hash" >> "$out"
    done < <(find "$root/$source" -type f -print0 | sort -z)
done

printf 'Inventario criado: %s\n' "$out"
