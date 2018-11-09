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

source ./lib/helpers.sh





#
## parameters
#

readonly REL_VERSION=$1
readonly SUFFIX=${2:-}






#
## repos
#

readonly core_repo="git@github.com:dhis2/dhis2-core.git"
readonly app_repos=(
    "git@github.com:dhis2/app-management-app.git"
    "git@github.com:dhis2/cache-cleaner-app.git"
    "git@github.com:dhis2/capture-app.git"
    "git@github.com:dhis2/charts-app.git"
    "git@github.com:dhis2/core-resource-app.git"
    "git@github.com:dhis2/d2-i18n-monitor.git"
    "git@github.com:dhis2/dashboards-app.git"
    "git@github.com:dhis2/data-administration-app.git"
    "git@github.com:dhis2/data-quality-app.git"
    "git@github.com:dhis2/data-visualizer-app.git"
    "git@github.com:dhis2/datastore-app.git"
    "git@github.com:dhis2/dhis2-usage-analytics.git"
    "git@github.com:dhis2/event-capture-app.git"
    "git@github.com:dhis2/event-charts-app.git"
    "git@github.com:dhis2/event-reports-app.git"
    "git@github.com:dhis2/gis-app.git"
    "git@github.com:dhis2/import-export-app.git"
    "git@github.com:dhis2/interpretation-app.git"
    "git@github.com:dhis2/maintenance-app.git"
    "git@github.com:dhis2/maps-app.git"
    "git@github.com:dhis2/menu-management-app.git"
    "git@github.com:dhis2/messaging-app.git"
    "git@github.com:dhis2/pivot-tables-app.git"
    "git@github.com:dhis2/scheduler-app.git"
    "git@github.com:dhis2/settings-app.git"
    "git@github.com:dhis2/tracker-capture-app.git"
    "git@github.com:dhis2/translations-app.git"
    "git@github.com:dhis2/user-app.git"
    "git@github.com:dhis2/user-profile-app.git"
)





#
## functions
#

function app_tag_name {
    # turns 2.31 and rc1 into `2.31-rc1`

    local TAG="${REL_VERSION}-${SUFFIX}"
    echo "$TAG"
}

function app_branch_name {
    # turns 2.31 or 2.31.1.12.23.3 into `v31`

    local RHS=${REL_VERSION#*.}
    local LHS=${RHS%%.*}
    echo "v${LHS}"
}

function release_apps {
    # creates release branch and tag
    # pushes to remote

    local branch=$(app_branch_name)
    local tag=$(app_tag_name)

    for app in "${app_repos[@]}"
    do
        local name=$(app_name "$app")
        local path="${TEMP}/${name}"

        pushd "$path"
        create_branch "$branch"
        git checkout "$branch"
        create_tag "$tag"

        push "$branch"
        push "$tag"
        popd
    done
}

function release_core {
    local name=$(app_name "$core_repo")
    local path="${TEMP}/${name}"
    local branch="$REL_VERSION"
    local tag=$(app_tag_name)
    local pkg_path="./dhis-2/dhis-web/dhis-web-apps"
    local app_branch=$(app_branch_name)

    pushd "$path"

    # creates release branch for The Core
    create_branch "$branch"
    git checkout "$branch"

    # updates all app version refs to tag
	jq --exit-status "(.dependencies |= (
		.|with_entries(
			if .key|endswith(\"-app\") then
				.value |=
					if .|contains(\"#\") then
						.|sub(\"#.*$\"; \"#${tag}\")
					else
						.+\"#${tag}\"
					end
			else
				.
			end
		)
	))" "${pkg_path}/package.json" > "${pkg_path}/package.json.mod"
    mv "${pkg_path}/package.json.mod" "${pkg_path}/package.json"

    # commits and tags
    git add "${pkg_path}/package.json"
    git commit -m "chore: lock app versions to tag ${tag}"
    create_tag "$tag"

    # updates all app version refs to release branch
	jq --exit-status "(.dependencies |= (
		.|with_entries(
			if .key|endswith(\"-app\") then
				.value |=
					if .|contains(\"#\") then
						.|sub(\"#.*$\"; \"#${app_branch}\")
					else
						.+\"#${app_branch}\"
					end
			else
				.
			end
		)
	))" "${pkg_path}/package.json" > "${pkg_path}/package.json.mod"
    mv "${pkg_path}/package.json.mod" "${pkg_path}/package.json"

    # commits to release branch
    git add "${pkg_path}/package.json"
    git commit -m "chore: set apps to track branch ${app_branch}"

    push "$tag"
    push "$branch"

    popd
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
    release_apps
    release_core

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
