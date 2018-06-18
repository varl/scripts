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

dhis2ver="2.30"
rc="RC2"

version="${dhis2ver}-${rc}-SNAPSHOT"

tmpdir="./temp"

mkdir "$tmpdir"
pushd "$tmpdir"

repos=(
    "git@github.com:dhis2/core-resource-app.git"
    "git@github.com:dhis2/translations-app.git"
    "git@github.com:dhis2/maintenance-app.git"
    "git@github.com:dhis2/app-management-app.git"
    "git@github.com:dhis2/dhis2-usage-analytics.git"
    "git@github.com:dhis2/cache-cleaner-app.git"
    "git@github.com:dhis2/user-profile-app.git"
    "git@github.com:dhis2/settings-app.git"
    "git@github.com:dhis2/menu-management-app.git"
    "git@github.com:dhis2/event-capture-app.git"
    "git@github.com:dhis2/tracker-capture-app.git"
    "git@github.com:dhis2/charts-app.git"
    "git@github.com:dhis2/pivot-tables-app.git"
    "git@github.com:dhis2/maps-app.git"
    "git@github.com:dhis2/event-reports-app.git"
    "git@github.com:dhis2/event-charts-app.git"
    "git@github.com:dhis2/dashboards-app.git"
    "git@github.com:dhis2/interpretation-app.git"
    "git@github.com:dhis2/datastore-app.git"
    "git@github.com:dhis2/scheduler-app.git"
    "git@github.com:dhis2/data-quality-app.git"
    "git@github.com:dhis2/data-administration-app.git"
    "git@github.com:dhis2/user-app.git"
    "git@github.com:dhis2/messaging-app.git"
    "git@github.com:dhis2/import-export-app.git"
    "git@github.com:dhis2/gis-app.git"
    "git@github.com:dhis2/capture-app.git"
)

for repo in "${repos[@]}"
do
	name=$(echo "${repo}" | sed -n "s/^.*dhis2\/\(.*\)\.git$/\1/p")
	git clone ${repo}
	pushd "${name}"

	# build the pkg
	yarn install --ignore-engines
	yarn build

	# modify the pom.xml with the new version
	sed --in-place -e "s/[0-9]\.[0-9][0-9]-SNAPSHOT/${version}/" pom.xml

	# deploy it to nexus
	mvn clean deploy

	## tag it
	git tag "v${version}"
	git push origin v${version}

	popd
done

cleanup() {
    echo "cleanup.."
	popd
    rm -rf "$tmpdir"
}

trap cleanup EXIT
