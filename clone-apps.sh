#!/usr/bin/env bash

### start: shellharden
if test "$BASH" = "" || "$BASH" -uc "a=();true \"\${a[@]}\"" 2>/dev/null; then
    # Bash 4.4, Zsh
    set -euo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u.
    set -eo pipefail
fi
shopt -s nullglob globstar
### end: shellharden





# figure out script path
readonly DIR=$(dirname $0)
readonly ROOT=$(cd "${DIR}" && pwd)

# contains the $apps, $libs, $core definitions
source "${ROOT}/lib/git.sh"
source "${ROOT}/apps.sh"



if [[ $# -gt 0 ]]; then
    readonly BASE="$1"
else
    readonly BASE="."
fi

coredir="${BASE}/core"
graveyarddir="${BASE}/graveyard"

appdir="${BASE}/apps"
libdir="${BASE}/libs"

if [ ! -d "$appdir" ]; then
    mkdir "$appdir"
fi

if [ ! -d "$libdir" ]; then
    mkdir "$libdir"
fi





for app in "${apps[@]}"
do
    name=$(app_name "$app")
    clone ${app} "${appdir}/${name}"
done

for lib in "${libs[@]}"
do
    name=$(app_name "$lib")
    clone ${lib} "${libdir}/${name}"
done

clone ${core} ${coredir}
clone ${graveyard} ${graveyarddir}

echo "Cloning done."





cleanup() {
    echo "Clean up before exit."
}

trap cleanup EXIT
