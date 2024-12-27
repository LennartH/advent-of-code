#!/usr/bin/env bash

script_dir=$(realpath "${0%/*}")

dir="$1"
if [[ -f "$dir" ]]; then
    dir="${dir%/*}"
elif [[ "$dir" =~ ^(day-)?[0-9]{1,2}$ ]]; then
    if [[ "$dir" =~ ^[0-9]$ ]]; then
        dir="0$dir"
    fi
    if [[ "$dir" =~ ^[0-9]{2}$ ]]; then
        dir="$script_dir/day-$dir"
    fi
    dir=$(echo "$dir"_*/)
fi
if [[ ! -d "$dir" ]]; then
    echo "Run target does not exist: $dir" >&2
    exit 1
fi

(cd "$dir"; time duckdb < solution.sql)
