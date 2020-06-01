#!/bin/bash

VERSION=2.34
PREFIX=/opt/cross9
TARGET=aarch64-linux

../binutils-${VERSION}/configure --prefix=$PREFIX --target=$TARGET --disable-multilib
make -j4 
make install

