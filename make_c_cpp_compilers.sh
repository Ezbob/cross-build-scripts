#!/bin/bash

VERSION=9.3.0
PREFIX=/opt/cross9
TARGET=aarch64-linux

../gcc-${VERSION}/configure --prefix=${PREFIX} --target=${TARGET} --enable-languages=c,c++ --disable-multilib
make -j4 all-gcc
make install-gcc

