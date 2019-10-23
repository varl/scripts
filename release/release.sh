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
#set -x
shopt -s nullglob globstar

dry_run=1



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
    "git@github.com:dhis2/dashboards-app.git"
    "git@github.com:dhis2/data-administration-app.git"
    "git@github.com:dhis2/data-visualizer-app.git"
    "git@github.com:dhis2/data-quality-app.git"
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

    local TAG="${REL_VERSION}"
    if [[ -n ${SUFFIX} ]]; then
        TAG="${TAG}-${SUFFIX}"
    fi
    echo "$TAG"
}

function get_next_snapshot {
    # turns 2.31.1 into `2.31.2`
    # unless we have provided a suffix, in which case, the patch
    # version is unchanged.
    local ITER=1
    if [ $SUFFIX ]
    then
      local ITER=0
    fi

    if [ $(core_branch_name) == $REL_VERSION ]
    then
      local BRANCH=$(core_branch_name)
      local NEXT_PATCH=0
      local NEXT_SNAPSHOT="$BRANCH.${NEXT_PATCH}-SNAPSHOT"
    else
      local BRANCH=$(core_branch_name)
      local NEXT_PATCH=$((${REL_VERSION#$BRANCH.} + ITER))
      local NEXT_SNAPSHOT="$BRANCH.${NEXT_PATCH}-SNAPSHOT"
    fi
    echo "$NEXT_SNAPSHOT"
}

function get_new_master {
    # turns 2.31 into `2.32`

    local BRANCH=$(core_branch_name)
    local NEXT_VERSION=$((${BRANCH#2.} + 1))
    local NEXT_SNAPSHOT="2.${NEXT_VERSION}-SNAPSHOT"

    echo "$NEXT_SNAPSHOT"
}

function app_branch_name {
    # turns 2.31 or 2.31.1.12.23.3 into `v31`

    local RHS=${REL_VERSION#*.}
    local LHS=${RHS%%.*}
    echo "v${LHS}"
}

function core_branch_name {
    local LHS=${REL_VERSION%%.*}
    local RHS=${REL_VERSION#*.}
    RHS=${RHS%%.*}
    echo "${LHS}.${RHS}"
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
        checkout "$branch"

        if [ $dry_run -eq 1 ];then
          # during dry run display recent changes
          echo "============= ++ CHANGES IN LAST WEEK ${name}:"
          git log --no-merges --oneline --since='1 week ago'
          echo "============= -- CHANGES IN LAST WEEK ${name}:"
        fi

        create_tag "$tag"

        if [ $dry_run -eq 0 ];then
          push "$branch"
          push "$tag"
        fi
        popd
    done
}

function release_core {
    local name=$(app_name "$core_repo")
    local path="${TEMP}/${name}"
    local branch="$(core_branch_name)"
    local tag=$(app_tag_name)
    local pkg_path="./dhis-2/dhis-web/dhis-web-apps"
    local app_branch=$(app_branch_name)
    local snapshot_branch="<version>${branch}-SNAPSHOT</version>"
    local snapshot_version="<version>${REL_VERSION}-SNAPSHOT</version>"
    local tag_version="<version>${tag}</version>"
    if [ ${SUFFIX} == "" ]
    then
      local next_snapshot_version=$snapshot_version
    else
      local next_snapshot_version="<version>$(get_next_snapshot)</version>"
    fi
    echo "NEXT SNAPSHOT VERSION: $next_snapshot_version"

    pushd "$path"

    # creates release branch for The Core
    created_branch=$(create_branch "$branch")
    echo $created_branch
    checkout "$branch"

    if [ $dry_run -eq 1 ];then
      # during dry run display recent changes
      echo "============= ++ CHANGES IN LAST WEEK ${name}:"
      git log --no-merges --oneline --since='1 week ago'
      echo "============= -- CHANGES IN LAST WEEK ${name}:"
    fi

    # updates all app version refs to tag
	jq --exit-status "(. |= (
		.|map(
            . |=
                if .|contains(\"#\") then
                    .|sub(\"#.*$\"; \"#${tag}\")
                else
                    .+\"#${tag}\"
                end
		)
	))" "${pkg_path}/apps-to-bundle.json" > "${pkg_path}/apps-to-bundle.json.mod"
    mv "${pkg_path}/apps-to-bundle.json.mod" "${pkg_path}/apps-to-bundle.json"

    # commits and tags
    git add "${pkg_path}/apps-to-bundle.json"
    git commit -m "chore: lock app versions to tag ${tag}"


    # update the mvn versions
    local find=$(unregex "$snapshot_version")
    local find_branch=$(unregex "$snapshot_branch")
    local replace=$(unregex "$tag_version")
    for pom in `find . -name "pom*.xml"`
    do
      sed -i "s;${find};${replace};" $pom
      sed -i "s;${find_branch};${replace};" $pom
      git add $pom
    done
    git commit -m "chore: update maven versions to ${tag}"

    create_tag "$tag"

    # updates all app version refs to release branch
	jq --exit-status "(.|= (
		.|map(
            . |=
                if .|contains(\"#\") then
                    .|sub(\"#.*$\"; \"#${app_branch}\")
                else
                    .+\"#${app_branch}\"
                end
		)
	))" "${pkg_path}/apps-to-bundle.json" > "${pkg_path}/apps-to-bundle.json.mod"
    mv "${pkg_path}/apps-to-bundle.json.mod" "${pkg_path}/apps-to-bundle.json"

    # commits to release branch
    git add "${pkg_path}/apps-to-bundle.json"
    git commit -m "chore: set apps to track branch ${app_branch}"
    # update the mvn versions to next snapshot
    local find=$(unregex "$tag_version")
    local replace=$(unregex "$next_snapshot_version")
    for pom in `find . -name "pom*.xml"`
    do
      sed -i "s;${find};${replace};" $pom
      git add $pom
    done
    git commit -m "chore: update maven versions to $(get_next_snapshot)"

    if [ $dry_run -eq 0 ];then
      push "$tag"
      push "$branch"
    fi

    # update the master in the case we have branched a new release
    if [ "$created_branch" != "" ]
    then
      echo "updating the mvn version on master"
      local new_master="$(get_new_master)"
      local next_version="<version>$new_master</version>"
      echo "$next_version"
      checkout "master"

      # update the mvn versions
      local find=$(unregex "$snapshot_version")
      local find_branch=$(unregex "$snapshot_branch")
      local replace=$(unregex "$next_version")
      for pom in `find . -name "pom*.xml"`
      do
        sed -i "s;${find};${replace};" $pom
        sed -i "s;${find_branch};${replace};" $pom
        git add $pom
      done
      git commit -m "chore: update maven versions to ${new_master}"

      if [ $dry_run -eq 0 ];then
        push "master"
      fi
    fi

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


function recent_changes {
    local all_repos=()
    all_repos+=("${core_repo}" "${app_repos[@]}")

    for repo in "${all_repos[@]}"
    do
        local name=$(app_name "$repo")
        pushd "${TEMP}/${name}"
        echo "============= ++ CHANGES IN LAST WEEK ${name}:"
        git log --no-merges --oneline --since='1 week ago'
        echo "============= -- CHANGES IN LAST WEEK ${name}:"
        popd
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
