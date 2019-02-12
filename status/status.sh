#!/usr/bin/env bash





#
## bash setup
#

if test "$BASH" = "" || "$BASH" -uc "a=();true \"\${a[@]}\"" 2>/dev/null; then
    # Bash 4.4, Zsh
    set -euo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u.
    set -eo pipefail
fi
set -x
shopt -s nullglob globstar





#
## helpers
#

source ../lib/git.sh
source ../apps.sh





#
## parameters
#

readonly REL_VERSION=$1






function query_apps {
    local branch=REL_VERSION

    for app in "${app_repos[@]}"
    do
        local path="${TEMP}/${name}"
        local name=$(app_name "$app")

        pushd "$path"
        git checkout "$branch"

        popd
    done
}

function clone_all {
    local all_repos=()
    all_repos+=("${core_repo}" "${app_repos[@]}")

    for repo in "${all_repos[@]}"
    do
        local name=$(app_name "$repo")
        clone "$repo" "${TEMP}/${name}"
    done
}

function main {
    local TEMP="./temp"

    clone_all
    query_apps

    echo "Done."
}

cleanup() {
    echo "cleanup.."
}




#
## start it up
#

trap cleanup EXIT
main
