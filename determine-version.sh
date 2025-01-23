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
declare -r MANIFEST_FILE_PATH='./package.json'
declare -r VERSION_PATTERN='^([^.]+)\.([^.]+)\.([^.]+)(.+)?$'

declare FORMAT='${MAJOR}.${MINOR}.${PATCH}${CANDIDATE}'
declare UPDATE_TYPE=patch

while true; do
    case "$1" in
        -f|--format)
            shift
            FORMAT="$1"
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
            echo "Given argument: \"${1}\" is not available." &>/dev/stderr
            exit 1
    esac
done

if [ ! -s "${MANIFEST_FILE_PATH}" ]; then
    echo \
        "Given file \"${MANIFEST_FILE_PATH}\" does not exist or is empty." \
        &>/dev/stderr
    exit 1
fi

declare -r GIVEN_VERSION="$(
    node --eval "console.log(require('${MANIFEST_FILE_PATH}').version)"
)"

declare MAJOR="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\1/"
)"
declare MINOR="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\2/"
)"
declare PATCH="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\3/"
)"
declare CANDIDATE="$(
    echo "$GIVEN_VERSION" | sed --regexp-extended "s/${VERSION_PATTERN}/\4/"
)"

echo GIVEN_VERSION: "$GIVEN_VERSION"

echo MAJOR: "$MAJOR"
echo MINOR: "$MINOR"
echo PATCH: "$PATCH"
echo CANDIDATE: "$CANDIDATE"

echo TYPE: "$UPDATE_TYPE"

if [ "$UPDATE_TYPE" = major ]; then
    (( MAJOR += 1))
elif [ "$UPDATE_TYPE" = minor ]; then
    (( MINOR += 1))
elif [ "$UPDATE_TYPE" = patch ]; then
    (( PATCH += 1))
fi

declare -r NEW_VERSION="$(eval "echo \"${FORMAT}\"")"

echo "$NEW_VERSION"

# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
