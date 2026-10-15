#!/usr/bin/env bash
set -euo pipefail

# Process all unique HDR and focus-stack timestamps in a photo directory.
# The actual processing stays in mertens.sh.

if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [photo-directory]" >&2
    exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
processor="$script_dir/mertens.sh"
photo_dir="${1:-.}"

if [ ! -d "$photo_dir" ]; then
    echo "Photo directory does not exist: $photo_dir" >&2
    exit 1
fi
if [ ! -f "$processor" ]; then
    echo "Missing mertens.sh alongside mertensall.sh: $processor" >&2
    exit 1
fi

cd -- "$photo_dir"
shopt -s nullglob

declare -A seen=()
timestamps=()

for jpg in *.jpg; do
    if [[ $jpg =~ ^([0-9]{6}-[0-9]{6})-.+-AEB-.+[.]jpg$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    elif [[ $jpg != *-contrast.jpg && $jpg != *-AEB-* && $jpg =~ ^([0-9]{6}-[0-9]{6})-[0-9]+-.+[.]jpg$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    else
        continue
    fi

    if [ -z "${seen[$timestamp]:-}" ]; then
        seen[$timestamp]=1
        timestamps+=( "$timestamp" )
    fi
done

if [ "${#timestamps[@]}" -eq 0 ]; then
    echo "No HDR or focus stack sets found in $PWD."
    exit 0
fi

echo "Found ${#timestamps[@]} HDR/focus stack set(s) in $PWD."

failed=0
for timestamp in "${timestamps[@]}"; do
    echo
    echo "=== Processing $timestamp ==="
    if "$processor" "$timestamp"; then
        echo "OK: $timestamp"
    else
        echo "FAILED: $timestamp" >&2
        failed=$((failed + 1))
    fi
done

echo
echo "Finished: $(("${#timestamps[@]}" - failed)) succeeded, $failed failed."
[ "$failed" -eq 0 ]
