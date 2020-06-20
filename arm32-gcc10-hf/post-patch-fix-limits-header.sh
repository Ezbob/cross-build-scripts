#!/bin/bash
# This script reapplies an GCC header fix to the limits.h header so that the fixed header 
# recurse down to the real libc limits.h.
#
# This script is needed because the code, in the GCC code base, that applies this patch
# checks for a already-installed libc installed limits.h header, but due to the order of 
# installation we needed an (cut-down) installation of GCC before we can build libc.

die() {
    echo "Error: $1"
    exit 1
}

[ ! -f variables ] && die "'variables': No such file"

. variables

[ -z "${TARGET_ARCH}" ] && die "TARGET_ARCH not defined."

echo "Applying limits.h header patch..."

LIBGCC_FILE=$(${TARGET_ARCH}-gcc -print-libgcc-file-name)
LIBGCC_PATH=$(dirname ${LIBGCC_FILE})

LIMITX_HEADER=${LIBGCC_PATH}/plugin/include/limitx.h
LIMITY_HEADER=${LIBGCC_PATH}/plugin/include/limity.h
GLIMIT_HEADER=${LIBGCC_PATH}/plugin/include/glimits.h

FIXED_LIMITS_HEADER=${LIBGCC_PATH}/include-fixed/limits.h

cat ${LIMITX_HEADER} ${GLIMIT_HEADER} ${LIMITY_HEADER} > ${FIXED_LIMITS_HEADER}

echo "Done."
