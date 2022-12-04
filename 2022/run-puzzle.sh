#!/usr/bin/env bash

cd "${0%/*}" || exit 1

found_file=""
for f in ./src/day*.ts; do
  name="${f##*/}"
  if [[ "$name" =~ ^$1.*$ ]]; then
    echo "Running $name"
    npx ts-node "$f"
    found_file="true"
    break
  fi
done

cd - &> /dev/null || exit 1
if [[ -z $found_file ]]; then
  echo "No file found beginning with '$1'"
  exit 1
fi

