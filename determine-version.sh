#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC1090,SC2034,SC2155
declare -r MANIFEST_FILE_PATH='../clientnode/package.json'
declare -r VERSION_PATTERN='^([^.]+)\.([^.]+)\.([^.]+)(.(.+))?$'

declare -r CURRENT_VERSION="$(node --eval "console.log(require('${MANIFEST_FILE_PATH}').version)")"

declare -r MAJOR="$(echo "$CURRENT_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\1/")"
declare -r MINOR="$(echo "$CURRENT_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\2/")"
declare -r PATCH="$(echo "$CURRENT_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\3/")"
declare -r CANDIDATE="$(echo "$CURRENT_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\5/")"

declare UPDATE_TYPE=patch

while true; do
    case "$1" in
        -n|--refresh-node-modules)
            ssh "$BPV_PRODUCTION_SSH_TARGET" \
                -t "rm --force --recursive '${BPV_REMOTE_PRODUCTION_LOCATION}node_modules' '${BPV_REMOTE_PRODUCTION_LOCATION}plugins/admin/node_modules' '${BPV_REMOTE_PRODUCTION_LOCATION}plugins/public/node_modules'"
            shift
            ;;
        major|minor|patch)
            UPDATE_TYPE="$1"
            shift
            ;;
        '')
            shift || \
                true
            break
            ;;
        *)
            logging.error "Given argument: \"${1}\" is not available."
            return 1
    esac
done

echo FULL: "$CURRENT_VERSION"
echo MAJOR: "$MAJOR"
echo MINOR: "$MINOR"
echo PATCH: "$PATCH"
echo CANDIATE: "$CANDIDATE"

# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
