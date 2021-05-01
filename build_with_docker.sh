#!/bin/bash

die() {
    1>&2 echo "Error: $1"
    exit 1
}

PROFILE=$1
: ${BUILDER_IMAGE:=gcc_builder}

if [ -z "${PROFILE}" ]; then
    die "Expected first argument to be name of the toolchain profile"
fi

docker run --rm -it -v $(pwd)/"${PROFILE%/}"/:/opt/crossgcc/build/ "${BUILDER_IMAGE}"
