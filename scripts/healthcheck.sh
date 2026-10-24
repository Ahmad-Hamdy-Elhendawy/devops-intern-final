
#!/usr/bin/env bash
set -euo pipefail

url="${1:-http://localhost:8080}"

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: curl is not installed.' >&2
    exit 1
fi

if ! status="$(curl --silent --show-error \
    --output /dev/null \
    --write-out '%{http_code}' \
    --connect-timeout 5 \
    --max-time 10 \
    "$url" 2>/dev/null)"; then
    printf 'FAIL: Unable to reach %s\n' "$url" >&2
    exit 1
fi

if [ "$status" = "200" ]; then
    printf 'PASS: %s returned HTTP %s\n' "$url" "$status"
else
    printf 'FAIL: %s returned HTTP %s (expected 200)\n' \
        "$url" "$status" >&2
    exit 1
fi

