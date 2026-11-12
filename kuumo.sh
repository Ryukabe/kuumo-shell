#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if pgrep -f quickshell > /dev/null; then
    pkill -f quickshell
else
    qs -p "$DIR"
fi