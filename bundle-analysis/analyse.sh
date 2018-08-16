#!/usr/bin/env bash

### init bash
if test "$BASH" = "" || "$BASH" -uc "a=();true \"\${a[@]}\"" 2>/dev/null; then
    # Bash 4.4, Zsh
    set -euo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u.
    set -eo pipefail
fi
shopt -s nullglob globstar
### init bash end

tmpdir="./temp"

if [ ! -d "$tmpdir" ]; then
    echo "Nothing cloned!"
    exit 1
fi

statdir="stats"

if [ -d "$statdir" ]; then
    rm -rf "$statdir"
fi

mkdir "$statdir"

yarn install

pushd "$tmpdir"

for repo in "$(ls $tmpdir)"
do
	pushd "$repo"

	# build the pkg
	yarn install --ignore-engines

    ./node_modules/.bin/webpack --profile --json > "../../${statdir}/${repo}.json"

	popd
done

trap cleanup EXIT
