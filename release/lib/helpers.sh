#!/usr/bin/env bash

function app_name {
    local repo=$1
    local name=$(echo "${repo}" | sed -n "s/^.*dhis2\/\(.*\)\.git$/\1/p")

    echo "$name"
}

function checkout {
    local branch=$1
    git checkout "$branch"
    git fetch origin "$branch"
    git merge
}

function clone {
    local repo=$1
    local path=$2

    if [[ ! -d "$path" ]]; then
        git clone "${repo}" "${path}"
    else
        pushd "$path"
        git reset HEAD --hard
        git checkout master

        # remove local tags and get remote
        local pruned_tags=$(git tag -l | xargs git tag -d)

        # remove local branches
        local pruned_branches=$(git branch | grep -v "master" | xargs git branch -D)

        # update master
        git fetch origin
        git merge
        popd
    fi
}

function create_branch {
    local branch=$1
    local out=$(git rev-parse --verify "origin/${branch}" 2>&1)

    if [[ "$out" == fatal* ]]; then
        echo "creating branch: ${branch}"
        git branch "$branch"
    else
        echo "existing branch: ${branch}"
    fi
}

function create_tag {
    local tag=$1
    local out=$(git rev-parse --verify "$tag" 2>&1)

    if [[ "$out" == fatal* ]]; then
        echo "creating tag: ${tag}"
        git tag "$tag"
    else
        echo "existing tag: ${tag}"
    fi
}

function push {
    local refspec=$1

    git push origin "$refspec"
}
