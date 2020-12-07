#!/bin/bash

die() {
    echo "Error: $1"
    exit 1
}

CWD=$(pwd)

[ ! -f "variables" ] && die "'variables' file missing"

. variables

[ ! -d "${PREFIX}" ] && die "No such directory: '${PREFIX}'"

[ -z "${TARGET_ARCH}" ] && die "TARGET_ARCH empty"

echo "Packing toolchain..."
tar -I 'xz -T4' -c -f ${TARGET_ARCH}.tar.xz -C ${PREFIX}/ . || die "Could not pack toolchain to ${TARGET_ARCH}"
echo "done."
