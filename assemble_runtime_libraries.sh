#!/bin/bash

# Builds an tar.gz file that can be send and extracted on a target machine

die() {
    echo "Error: $1"
    exit 1
}

make_resources() {
    mkdir -p $TAR_DIR
}

unmake_resources() {
    rm -rf $TAR_DIR
}

gather_libraries() {
    local lib_dir=$1
    cd $lib_dir
    cp -r * $TAR_DIR
    rm -rf $TAR_DIR/*.la
    rm -rf $TAR_DIR/*.a
    rm -rf $TAR_DIR/*.py
    cd - > /dev/null
}

pack_libraries() {
    local out=$1
    cd $TAR_DIR
    tar -czf ${OLD_DIR}/${out} *
    cd - > /dev/null
}


[ ! -f ./variables  ] && die "Expected an 'variable' file" 

OLD_DIR=$(pwd)
OUTPUT=libraries.tgz
TAR_DIR=/tmp/.tarred-$RANDOM

make_resources
trap unmake_resources EXIT

. ./variables


cd $PREFIX

[ ! -d "$TARGET_ARCH" ] && die "Could not find built image '$TARGET_ARCH' in '$PREFIX'"

cd $TARGET_ARCH

echo "Finding libraries directory..."
LIBDIR=""

if [ -d "lib64" ]; then
    LIBDIR="lib64"
elif [ -d "lib"  ]; then
    LIBDIR="lib"
else
    die "No libraries directory detected"
fi

echo "Found libraries directory '$LIBDIR'."

echo "Copying libraries..."
gather_libraries "$LIBDIR"
echo "Copied libraries."

echo "Packing libraries into '$OUTPUT'..."
pack_libraries "$OUTPUT"
echo "Packed libraries into '$OUTPUT'."

cd $OLD_DIR
