#!/bin/bash

function usage() {
    echo >&2 "usage: ${0##*/} INDEX REPOS-FILES"
    exit 1
}

[[ $# -ge 2 ]] || usage
index="$1"
shift

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")/.."

set -o errexit
set -o pipefail
set -o xtrace

# Get the list-repos function
source "${ROOTDIR}/scripts/rpm-functions.sh"

# Temporary directory to cache working files
workdir="$(mktemp -d)"
#shellcheck disable=SC2064
trap "rm -fr '$workdir'" EXIT

# Parse the zypper log and generate an rpm-index
#shellcheck disable=SC2046
sed -e '/^Not downloading package /!d' \
    -e "s/^Not downloading package '//" \
    -e 's/[[:space:]]\+.*$//' \
| sort -u \
| docker run --rm -i  artifactory.algol60.net/csm-docker/stable/csm-docker-sle:15.3 rpm-index -v \
    $(cat "$@" | remove-comments-and-empty-lines | awk '{print "-d", $1, $NF}') \
| tee "${workdir}/index.yaml"

mv "${workdir}/index.yaml" "$index"
