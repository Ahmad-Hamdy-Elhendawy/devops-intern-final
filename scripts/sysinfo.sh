
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' '=== System Information ==='
printf 'Current user: %s\n' "$(id -un)"
printf 'Effective UID: %s\n' "$(id -u)"
printf 'Hostname: %s\n' "$(hostname)"
printf 'Kernel release: %s\n' "$(uname -r)"
printf 'System date: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%:z')"

printf '\n%s\n' '=== Disk Usage ==='
df -h

printf '\n%s\n' '=== Memory Usage ==='
if command -v free >/dev/null 2>&1; then
    free -h
elif [ -r /proc/meminfo ]; then
    awk '/^(MemTotal|MemAvailable|MemFree|SwapTotal|SwapFree):/ {
        print
    }' /proc/meminfo
else
    printf '%s\n' 'Memory usage unavailable: no supported command or /proc/meminfo.'
fi

printf '\n%s\n' '=== Docker Daemon ==='
if ! command -v docker >/dev/null 2>&1; then
    printf '%s\n' 'Docker status: Docker CLI not installed.'
    exit 1
elif docker info >/dev/null 2>&1; then
    printf '%s\n' 'Docker status: running'
else
    printf '%s\n' 'Docker status: unavailable or inaccessible.'
    exit 1
fi

