#!/bin/bash

VERSION=2.31
PREFIX=/opt/cross9/aarch64-linux
TARGET=aarch64-linux

export libc_cv_forced_unwind=yes 

../glibc-${VERSION}/configure --prefix=${PREFIX} --build=${MACHTYPE} --host=${TARGET} --target=${TARGET} --with-headers=${PREFIX}/include --disable-multilib && 

make install-bootstrap-headers=yes install-headers &&

make -j4 csu/subdir_lib &&

install csu/crt1.o csu/crti.o csu/crtn.o ${PREFIX}/lib &&

aarch64-linux-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${PREFIX}/lib/libc.so &&

touch ${PREFIX}/include/gnu/stubs.h

