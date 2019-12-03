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





BRANCHES="$@"

main () {
    local branch="$1"
    hub sync

    declare -a prs
    readarray -t prs < <(hub pr list --base="$branch" --format='%I|%t%n' --state all)

    fixed=0
    for PR in "${prs[@]}"; do
        local pr_id="$(echo $PR | cut -d "|" -f 1)"
        local pr_title="$(echo $PR | cut -d "|" -f 2)"

        if [ "chore(deps): upgrade d2-i18n(-generate) deps (${branch})" == "$pr_title" ]; then
            echo "There has already been a PR for this: ${pr_id}"
            echo "Title: ${pr_title}"
            fixed=1
            break
        fi
    done

    if [ $fixed == 0 ]; then
        if git show-branch "remotes/origin/${branch}" >/dev/null 2>&1; then
            hub checkout "$branch"

            if rg --quiet "d2-i18n(-generate)?" package.json; then
                hub checkout -B "deps/d2-i18n-upgrades-${branch}"
                yarn install --ignore-engines
                yarn upgrade --ignore-engines @dhis2/d2-i18n@^1.0.6 @dhis2/d2-i18n-generate@^1.1.1
                git add yarn.lock
                git add package.json
                yarn install --ignore-engines
                hub commit --message "chore(deps): upgrade d2-i18n(-generate) deps (${branch})"
                hub pull-request --no-edit --base "$branch" --push
            else
                echo "Could not find d2-i18n/d2-i18n-generate"
            fi
        else
            echo "Remote branch ${branch} does not exist"
        fi
    fi
}

array=( $BRANCHES )

for BRANCH in "${array[@]}"; do
    git reset HEAD --hard
    git checkout master

    export CI=1

    echo "Running on: ${BRANCH}"

    main "$BRANCH"
done
