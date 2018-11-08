#!/usr/bin/env bash

script_dir=$(dirname "$0")

for dir in packages/*/
do
    jq -f "${script_dir}/filter" "${dir}/package.json" > "${dir}/package.json.mod"
    mv "${dir}/package.json.mod" "${dir}/package.json"
done
