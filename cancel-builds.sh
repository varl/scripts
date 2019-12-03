#!/usr/bin/env bash

#
## bash environment
#

if test "$BASH" = "" || "$BASH" -uc "a=();true \"\${a[@]}\"" 2>/dev/null; then
    # Bash 4.4, Zsh
    set -euo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u.
    set -eo pipefail
fi
shopt -s nullglob globstar





declare -a array
readarray -t array < <(travis history --no-interactive --all --com | grep created | cut -d ' ' -f 1 | cut -d '#' -f 2)
for i in "${array[@]}"; do
    echo "Cancel $i"
    travis cancel "$i" --no-interactive --com
done
