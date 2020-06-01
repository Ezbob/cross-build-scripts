#!/bin/bash

die() {
    echo "Error: $1"
    exit 1
}

CWD=$(pwd)

[ ! -f "variables" ] && die "'variables' file missing"

. variables

IMAGE_PREFIX=${PREFIX}/${TARGET_ARCH}
BIN_PREFIX=${PREFIX}/bin

PATH=${BIN_PREFIX}:$PATH

[ -z "${PREFIX}" ] && die "Empty prefix"

[ ! -f ${TOOLS_FILE} ] && die "'tools' file missing" 

# cross environment script
ENV_SCRIPT="cross_environment.source"

echo "Creating environment script ${ENV_SCRIPT}.."

echo 'export PATH='${BIN_PREFIX}':$PATH' >> ${ENV_SCRIPT}
echo 'export CROSS_PREFIX='${PREFIX} >> ${ENV_SCRIPT}
echo 'export CROSS_ARCH='${TARGET_ARCH} >> ${ENV_SCRIPT}

# end of cross environment script

echo "Created environment script ${ENV_SCRIPT}."

if [ -d ${WORK_DIR} ]; then
    rm -rf ${WORK_DIR}
fi

mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

while read line; do 
    url=$(echo $line | tr -s ' ' | cut -d ' ' -f 2)
    package=${url##*/}

    wget $url
    [ "$?" != 0 ] && die "Could not download $package from $url"
    tar -xf $package

done < ${TOOLS_FILE}

rm -f *.tar.*

echo "Setting up GCC dependecies links..."
cd gcc-*
ln -s ../mpfr-* mpfr
ln -s ../gmp-* gmp
ln -s ../mpc-* mpc
ln -s ../isl-* isl
ln -s ../cloog-* cloog
cd ..
echo "done."

echo "Building process next... "
sleep 3

echo "Building Binutils.."

BINUTILS_OPTS=${BINUTILS_OPTS:-"--disable-multilib"}

mkdir -p build-binutils
cd build-binutils
../binutils-*/configure --prefix=$PREFIX --target=${TARGET_ARCH} ${BINUTILS_OPTS}
make -j4 && make install || die "Binutils build failed"
cd ..

echo "built binutils."

echo "Installing Linux headers.."
cd linux-*
make ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=${IMAGE_PREFIX} headers_install
cd ..
echo "Installed Linux headers."

echo "Installing GCC cross compiler.."

GCC_OPTS=${GCC_OPTS:-"--disable-multilib"}

mkdir -p build-gcc
cd build-gcc
../gcc-*/configure --prefix=${PREFIX} --target=${TARGET_ARCH} --enable-languages=c,c++ ${GCC_OPTS}
make -j4 all-gcc && make install-gcc || die "Could not install cross compiler"
cd ..

echo "Installed GCC cross compiler."

echo "Installing standard C headers and startup files.."

STD_LIB_OPTS=${STD_LIB_OPTS:-"--disable-multilib"}

mkdir -p build-glibc
cd build-glibc
../glibc-*/configure --prefix=${IMAGE_PREFIX} --build=$MACHTYPE --host=${TARGET_ARCH} --target=${TARGET_ARCH} --with-headers=${IMAGE_PREFIX}/include ${STD_LIB_OPTS} libc_cv_forced_unwind=yes &&
make install-bootstrap-headers=yes install-headers && make -j4 csu/subdir_lib || die "Could not standard C headers and startup files"
install csu/crt1.o csu/crti.o csu/crtn.o ${IMAGE_PREFIX}/lib
${TARGET_ARCH}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${IMAGE_PREFIX}/lib/libc.so || die "Could not create startup files"
touch ${IMAGE_PREFIX}/include/gnu/stubs.h
cd ..

echo "Installed standard C and statup files."

echo "Installing compiler support library.."

cd build-gcc
make -j4 all-target-libgcc && make install-target-libgcc || die "Could not install compiler support library"
cd ..

echo "Installed compiler support library."

echo "Installing standard C library"
cd build-glibc
make -j4 && make install || die "Could not install standard C library"
cd ..
echo "Installed standard C library"

echo "Installing standard C++ library"

cd build-gcc
make -j4 && make install || die "Could not install standard C++ library"
cd ..

echo "Installed standard C++ library."

cd $CWD

