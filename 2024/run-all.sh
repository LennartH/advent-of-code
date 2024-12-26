#!/usr/bin/env bash

script_dir=$(realpath "${0%/*}")
outfile="$script_dir/runtimes.md"

> "$outfile"
first="true"
for dir in "$script_dir"/*/; do
    {
        if [[ $first != "true" ]]; then
            echo ""
            echo "--------------------------------------------------------------------------------"
            echo ""
        fi

        dir="${dir%*/}"
        echo "#### ${dir##*/}"
        echo ""
    } | tee -a "$outfile"

    echo '```' >> "$outfile"
    (cd "$dir"; time duckdb < solution.sql) 2>&1 | tee -a "$outfile"
    echo '```' >> "$outfile"
    first="false"
done
