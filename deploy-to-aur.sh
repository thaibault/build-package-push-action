#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# see https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
# Updates checksums of the "PKGBUILD" in the current working directory,
# generates a corresponding ".SRCINFO" and pushes both together with all local
# source files to arch's user repository. Has to be run as root in an arch
# linux environment (e.g. the "archlinux:base-devel" image). The updated
# "PKGBUILD" is written back to the current working directory.
# shellcheck disable=SC1090,SC1091,SC2016,SC2155
set -o errexit -o nounset -o pipefail

declare -r CONFIGURATION_PATH="$(dirname "$(readlink --canonicalize "$0")")"
# Provides "AUR_COMMIT_EMAIL", "AUR_COMMIT_MESSAGE", "AUR_COMMIT_NAME" and
# "DEBUG".
source "${CONFIGURATION_PATH}/environment.sh"
declare -r SSH_KEY_FILE_PATH="${CONFIGURATION_PATH}/aur-ssh-key"
declare -r WORKSPACE_PATH="$(pwd)"
declare -r BUILD_USER_NAME=builder

[ "$DEBUG" = true ] && \
    set -o xtrace

# NOTE: Partial upgrades are not supported (e.g. "openssh" may need a newer
# "openssl" than the image provides).
pacman \
    --needed \
    --noconfirm \
    --refresh \
    --sync \
    --sysupgrade \
    git openssh pacman-contrib
# NOTE: "makepkg" refuses to run as root.
id "$BUILD_USER_NAME" &>/dev/null || \
    useradd --create-home "$BUILD_USER_NAME"

declare -r BUILD_PATH="$(mktemp --directory)"
tar \
    --create \
    --exclude ./.git \
    --exclude ./node_modules \
    . | \
        tar --extract --directory "$BUILD_PATH"
# NOTE: "makepkg" expects local sources by their file name next to the
# "PKGBUILD" (e.g. "service/a.service" is expected as "a.service").
while IFS= read -r source; do
    file_path="${source#*::}"
    if [[ "$file_path" != *://* && "$file_path" == */* ]]; then
        cp "${BUILD_PATH}/${file_path}" "${BUILD_PATH}/${file_path##*/}"
    fi
done < <(
    cd "$BUILD_PATH" && \
    bash -c 'source ./PKGBUILD && printf "%s\n" "${source[@]}"'
)
chown --recursive "${BUILD_USER_NAME}:" "$BUILD_PATH"

run_as_builder() {
    runuser --user "$BUILD_USER_NAME" -- bash -c "cd '${BUILD_PATH}' && $1"
}
# NOTE: A newly published remote source (e.g. a npm package) may need some
# time to become available.
for try in 1 2 3 4 5; do
    run_as_builder updpkgsums && \
        break
    (( try == 5 )) && \
        exit 1
    echo "Updating checksums failed (try ${try}). Retry in 30 seconds." \
        &>/dev/stderr
    sleep 30
done
run_as_builder 'makepkg --printsrcinfo > .SRCINFO'

cp "${BUILD_PATH}/PKGBUILD" "${WORKSPACE_PATH}/PKGBUILD"

declare -r PACKAGE_BASE="$(
    sed --quiet 's/^pkgbase = //p' "${BUILD_PATH}/.SRCINFO"
)"
# Local source, install and changelog files to deploy (paths are relative to
# the build path).
declare -a FILE_NAMES=(PKGBUILD .SRCINFO)
while IFS= read -r file_path; do
    file_path="${file_path#*::}"
    [[ "$file_path" != *://* ]] && \
        FILE_NAMES+=("${file_path##*/}")
done < <(
    sed \
        --quiet \
        --regexp-extended \
        's/^\t(source(_[^ ]+)?|install|changelog) = //p' \
        "${BUILD_PATH}/.SRCINFO" | \
            sort --unique
)

mkdir --parents ~/.ssh
chmod 700 ~/.ssh
install --mode 600 "$SSH_KEY_FILE_PATH" ~/.ssh/aur
ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts 2>/dev/null
cat >> ~/.ssh/config <<EOF
Host aur.archlinux.org
    IdentityFile ~/.ssh/aur
    User aur
EOF

declare -r REPOSITORY_PATH="$(mktemp --directory)"
# NOTE: Cloning a not yet existing package creates it on first push.
git clone \
    "ssh://aur@aur.archlinux.org/${PACKAGE_BASE}.git" \
    "$REPOSITORY_PATH"
for file_name in "${FILE_NAMES[@]}"; do
    cp "${BUILD_PATH}/${file_name}" "${REPOSITORY_PATH}/${file_name}"
done

cd "$REPOSITORY_PATH"
git config user.name "$AUR_COMMIT_NAME"
git config user.email "$AUR_COMMIT_EMAIL"
git add -- "${FILE_NAMES[@]}"
if git diff --cached --quiet; then
    echo "Package \"${PACKAGE_BASE}\" is already up to date."
else
    git commit --message "$AUR_COMMIT_MESSAGE"
    git push origin HEAD:master
fi

# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
