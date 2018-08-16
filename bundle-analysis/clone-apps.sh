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

if [ -d "$tmpdir" ]; then
   rm -rf "$tmpdir"
fi

mkdir "$tmpdir"
pushd "$tmpdir"

repos=(
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
    "git@github.com:dhis2/ui.git"
)

for repo in "${repos[@]}"
do
	git clone ${repo}
done

echo "Cloning done."

cleanup() {
    echo "Clean up before exit."
}

trap cleanup EXIT
