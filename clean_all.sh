#!/bin/bash

die() {
    echo "Error: $1"
    exit 1
}

[ ! -f variables ] && die "'variables' file does not exist"

. variables

if [ -d ${WORK_DIR} ]; then
    echo "Cleaning working directory '${WORK_DIR}'"
    rm -rf ${WORK_DIR}
fi

if [ -d ${PREFIX} ]; then
    echo "Cleaing toolchain directory '${PREFIX}'"
    rm -rf ${PREFIX}
fi

if [ -f  cross_environment.source ]; then
    echo "Cleaning environment source script 'cross_environment.source'"
    rm cross_environment.source
fi

