#!/bin/bash

die() {
    echo "Error: $1"
    exit 1
}

CWD=$(pwd)
DESTDIR=${DESTDIR:-${CWD}}

[ ! -f "variables" ] && die "'variables' file missing"

. variables

[ ! -d "${PREFIX}" ] && die "No such directory: '${PREFIX}'"

[ -z "${TARGET_ARCH}" ] && die "TARGET_ARCH empty"

export XZ_OPT=${XZ_OPT:-"-T4"}

echo "Packing toolchain..."
tar -J -c -f ${TARGET_ARCH}.tar.xz -C ${PREFIX}/ . || die "Could not pack toolchain to ${TARGET_ARCH}"
echo "done."

if [ "$DESTDIR" != "$CWD" ]; then
    echo "Moving package to ${DESTDIR}..."
    mkdir -p ${DESTDIR} && mv ${TARGET_ARCH}.tar.xz ${DESTDIR}/ 
fi
