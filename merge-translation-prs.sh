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





#
## script environment
#

BASE="$1"





#
## funcs
#

main () {
    declare -a array
    readarray -t array < <(hub pr list --base="$BASE" --format='%I|%t%n')

    for PR in "${array[@]}"; do
        local pr_id="$(echo $PR | cut -d "|" -f 1)"
        local pr_title="$(echo $PR | cut -d "|" -f 2)"
        local scope="$(echo $pr_title | cut -d ":" -f 1)"
        local body="/tmp/${pr_id}-body.json"

        if [ "chore(translations)" == "$scope" ]; then
            url=$(hub pr show "$pr_id" --url)
            echo "Merging: ${url}"
            cat << EOF > "$body"
{
  "commit_title": "${pr_title}",
  "commit_message": "Automatically merged to resolve the avalance",
  "merge_method": "squash"
}
EOF
            res=$(hub api --method PUT "repos/{owner}/{repo}/pulls/${pr_id}/merge" --input "$body")
            rm "$body"
        fi
    done
}

main
