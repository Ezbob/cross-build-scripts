#!/bin/bash

die() {
    echo "Error: $1"
    exit 1
}

is_stage_not_built() {
    local stage_name=$1
    grep -q "$stage_name" .buildstages
    local res=$?
    if [ "$res" == "0" ]; then
        return 1
    else
        return 0
    fi
}

commit_stage() {
    local stage_name=$1
    sed -i "/$stage_name/d" .buildstages
    echo "$stage_name" >> .buildstages
}

CWD=$(pwd)

[ ! -f "variables" ] && die "'variables' file missing"

. variables

[ -z "${PREFIX}" ] && die "Empty prefix"

[ ! -f ${TOOLS_FILE} ] && die "'tools' file missing" 

mkdir -p ${PREFIX}

[ ! -d "${PREFIX}" ] && die "Prefix is not a directory"

IMAGE_PREFIX=${PREFIX}/${TARGET_ARCH}
BIN_PREFIX=${PREFIX}/bin

PATH=${BIN_PREFIX}:$PATH

# cross environment script for when you need it afterwards
ENV_SCRIPT="cross_environment.source"

echo "Creating environment script ${ENV_SCRIPT}.."

echo 'export PATH='${BIN_PREFIX}':$PATH' > ${ENV_SCRIPT}
echo 'export CROSS_PREFIX='${PREFIX} >> ${ENV_SCRIPT}
echo 'export CROSS_ARCH='${TARGET_ARCH} >> ${ENV_SCRIPT}

# end of cross environment script

echo "Created environment script ${ENV_SCRIPT}."

mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

touch .downloaded

while read line; do
    name=$(echo $line | tr -s ' ' | cut -d ' ' -f 1) 
    url=$(echo $line | tr -s ' ' | cut -d ' ' -f 2)
    package=${url##*/}

    if grep -q "$name" .downloaded; then
        echo "$name is already downloaded"
        continue
    else
        wget $url
        [ "$?" != 0 ] && die "Could not download $package from $url"
        echo "Unpacking $package..."
        tar -xf $package
        echo "Done."
        echo $name >> .downloaded
        rm -f $package
    fi
done < ${TOOLS_FILE}

touch .buildstages

if is_stage_not_built "gcc-links"; then
    echo "Setting up GCC dependecies links..."
    cd gcc-*
    ln -s ../mpfr-* mpfr
    ln -s ../gmp-* gmp
    ln -s ../mpc-* mpc
    ln -s ../isl-* isl
    ln -s ../cloog-* cloog
    cd ..
    echo "done."
    commit_stage "gcc-links"
fi

echo "Building process next... "
sleep 3

echo "Building Binutils.."

if is_stage_not_built "built-binutils"; then
    mkdir -p build-binutils
    cd build-binutils
    ../binutils-*/configure --prefix=$PREFIX --target=${TARGET_ARCH} ${BINUTILS_OPTS} || die "Could not configure binutils"
    make -j4 && make install || die "Binutils build failed"
    cd ..
    
    commit_stage "built-binutils"
    echo "built binutils."
else
    echo "Already built binutils"
fi

echo "Installing Linux headers.."

if is_stage_not_built "install-linux-headers"; then
    cd linux-*
    make ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=${IMAGE_PREFIX} headers_install || die "Could not install linux headers"
    cd ..
    echo "Installed Linux headers."
    commit_stage "install-linux-headers"
else
    echo "Already installed Linux headers."
fi

echo "Installing GCC cross compiler.."

if is_stage_not_built "cross-compiler"; then
    mkdir -p build-gcc
    cd build-gcc
    ../gcc-*/configure --prefix=${PREFIX} --target=${TARGET_ARCH} --enable-languages=c,c++ ${GCC_OPTS} || die "Could not configure cross compiler"
    make -j4 all-gcc && make install-gcc || die "Could not install cross compiler"
    cd ..
    echo "Installed GCC cross compiler."
    commit_stage "cross-compiler"
else
    echo "Already install GCC cross compiler."
fi

echo "Installing standard C headers and startup files.."

if is_stage_not_built "std-c-headers-and-runtime"; then
    mkdir -p build-glibc
    cd build-glibc
    ../glibc-*/configure --prefix=${IMAGE_PREFIX} --build=$MACHTYPE --host=${TARGET_ARCH} --target=${TARGET_ARCH} --with-headers=${IMAGE_PREFIX}/include ${GLIBC_OPTS} libc_cv_forced_unwind=yes || die "Could not configure glibc"
    make install-bootstrap-headers=yes install-headers && make -j4 csu/subdir_lib || die "Could not standard C headers and startup files"
    install csu/crt1.o csu/crti.o csu/crtn.o ${IMAGE_PREFIX}/lib || die "Could install C Runtime files"
    ${TARGET_ARCH}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${IMAGE_PREFIX}/lib/libc.so || die "Could not create startup files"
    touch ${IMAGE_PREFIX}/include/gnu/stubs.h
    cd ..
    commit_stage "std-c-headers-and-runtime"
    echo "Installed standard C and startup files."
else
    echo "Already installed standard C and startup files."
fi

echo "Installing compiler support library.."

if is_stage_not_built "compiler-support-lib"; then
    cd build-gcc
    make -j4 all-target-libgcc && make install-target-libgcc || die "Could not install compiler support library"
    cd ..
    commit_stage "compiler-support-lib"
    echo "Installed compiler support library."
else
    echo "Already installed compiler support library"
fi

echo "Installing standard C library"

if is_stage_not_built "std-c-lib"; then
    cd build-glibc
    make CFLAGS="${GLIBC_CFLAGS}" -j4 && make install || die "Could not install standard C library"
    cd ..
    echo "Installed standard C library"
    commit_stage "std-c-lib"
else
    echo "Already installed standard C library"
fi

echo "Installing standard C++ library"

if is_stage_not_built "std-c++-lib"; then
    cd build-gcc
    make -j4 && make install || die "Could not install standard C++ library"
    cd ..
    echo "Installed standard C++ library."
    commit_stage "std-c++-lib"
else
    echo "Already installed standard C++ library"
fi

cd $CWD

