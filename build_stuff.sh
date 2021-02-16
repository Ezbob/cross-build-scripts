#!/bin/bash
# Central build script for downloading and compiling a GCC cross-compiler 
# for various platforms. Mainly tested with ARM and AARCH64 systems.

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

print_title() {
    local title=$1
    echo -e '\033]2;'$title'\007'
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
SYSROOT_DIR=
SYSROOT_PREFIX=${IMAGE_PREFIX}/${SYSROOT_DIR}

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

# This stage downloads the dependencies found in the 'tools' file
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

echo "Running build stages..."
touch .buildstages

# This stage applies any patch scripts that are present in the current
# working directory
echo "Applying post-download patches.."
if is_stage_not_built "applying-patches"; then
    print_title "Post-download patches"
    cd $CWD
    for patch_file in patch-*.sh; do
        if [ -x $patch_file ]; then
            ./$patch_file || die "Could not apply post-download patch '${patch_file}'"
        fi
    done
    cd ${WORK_DIR}
    commit_stage "applying-patches"
else
    echo "Patches already applied"
fi

# this stage sets up the links to the GCC dependencies that was downloaded
# in a previous step
if is_stage_not_built "gcc-links"; then
    print_title "GCC dependencies links"
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

echo "Building Binutils.."

# This stage builds GNU Binutils which are the programs for manipulating the 
# binary object files created by the compiler (linker ld, assembler as, and more..)
if is_stage_not_built "built-binutils"; then
    print_title "Building binutils"
    mkdir -p build-binutils
    cd build-binutils
    ../binutils-*/configure --prefix= --with-sysroot=$SYSROOT_PREFIX --target=${TARGET_ARCH} ${BINUTILS_OPTS} || die "Could not configure binutils"
    make configure-host || die "configure host"
    make LDFLAGS="-all-static" -j4 || die "building binutils"
    make install-strip DESTDIR=${PREFIX} || die "Binutils build failed"
    cd ..
    
    commit_stage "built-binutils"
    echo "built binutils."
else
    echo "Already built binutils"
fi


echo "Installing Linux headers.."

# The compiler needs to know how to handle system calls to the Linux kernel so
# it needs the headers of some version of the Linux kernel to do this. This stage
# installs the relevant headers in the install prefix.
if is_stage_not_built "install-linux-headers"; then
    print_title "Linux headers"
    make -C linux-* ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=${SYSROOT_PREFIX}/usr headers_install || die "Could not install linux headers"
    echo "Installed Linux headers."
    commit_stage "install-linux-headers"
else
    echo "Already installed Linux headers."
fi

echo "Installing GCC cross compiler.."

# This stage compiles the actual cross compiler, so it can be used to compile
# the standard libraries (C and C++) in a later stage.
if is_stage_not_built "cross-compiler"; then
    print_title "GCC stage 1"
    mkdir -p build-gcc
    cd build-gcc
    ../gcc-*/configure --prefix= --with-sysroot=/${TARGET_ARCH}/${SYSROOT_DIR} --with-build-sysroot=${SYSROOT_PREFIX} --target=${TARGET_ARCH} ${GCC_OPTS} || die "Could not configure cross compiler"
    make -j4 all-gcc && make install-gcc DESTDIR=${PREFIX} || die "Could not install cross compiler"
    cd ..
    echo "Installed GCC cross compiler."
    commit_stage "cross-compiler"
else
    echo "Already install GCC cross compiler."
fi

echo "Installing standard C headers and startup files.."

# This stage configures the glibc sources, creates and install glibc headers,
# and builds and install the crt files which are C RunTime files (basically, the
# C code that initialize a main-function in a C program)
if is_stage_not_built "std-c-headers-and-runtime"; then
    print_title "libc headers and C runtime"
    mkdir -p build-glibc
    cd build-glibc
    ../glibc-*/configure --prefix=/usr --with-sysroot=/${TARGET_ARCH}/${SYSROOT_DIR} --build=$MACHTYPE --host=${TARGET_ARCH} --target=${TARGET_ARCH} ${GLIBC_OPTS} libc_cv_forced_unwind=yes || die "Could not configure glibc"
    make install-bootstrap-headers=yes install-headers DESTDIR=${SYSROOT_PREFIX} || die "Could not standard C headers and startup files"
    mkdir -p ${SYSROOT_PREFIX}/usr/lib
    make -j4 csu/subdir_lib && install csu/crt1.o csu/crti.o csu/crtn.o ${SYSROOT_PREFIX}/usr/lib || die "Could not install C Runtime files"
    ${TARGET_ARCH}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${SYSROOT_PREFIX}/usr/lib/libc.so || die "Could not create startup files"
    touch ${SYSROOT_PREFIX}/usr/include/gnu/stubs.h
    cd ..
    commit_stage "std-c-headers-and-runtime"
    echo "Installed standard C and startup files."
else
    echo "Already installed standard C and startup files."
fi

echo "Installing compiler support library.."

# This stage builds support libraries for the cross-compiler. These libraries 
# contain C++ exeception handler code amoungst other this. 
if is_stage_not_built "compiler-support-lib"; then
    print_title "Libgcc"
    make -C build-gcc -j4 all-target-libgcc || die "Could not compile libgcc" 
    make -C build-gcc install-target-libgcc DESTDIR=${PREFIX} || die "Could not install libgcc"
    commit_stage "compiler-support-lib"
    echo "Installed compiler support library."
else
    echo "Already installed compiler support library"
fi

echo "Installing standard C library"

# Finally we build the glibc fully
if is_stage_not_built "std-c-lib"; then
    print_title "Glibc"
    make -C build-glibc CFLAGS="-O2 ${GLIBC_CFLAGS}" -j4 || die "Could not build glibc" 
    make -C build-glibc install DESTDIR=${SYSROOT_PREFIX} || die "Could not install standard C library"
    echo "Installed standard C library"
    commit_stage "std-c-lib"
else
    echo "Already installed standard C library"
fi

echo "Installing standard C++ library"

# This stage builds the C++ library
if is_stage_not_built "std-c++-lib"; then
    print_title "GCC stage 2 (final)"
    make -C build-gcc -j4 || die "Could not build GCC stage 2"
    make -C build-gcc install DESTDIR=${PREFIX} || die "Could not install standard C++ library"
    echo "Installed standard C++ library."
    commit_stage "std-c++-lib"
else
    echo "Already installed standard C++ library"
fi

# This stage applies any patch scripts that are present in the current
# working directory
echo "Applying post-build patches.."
if is_stage_not_built "applying-post-patches"; then
    print_title "Post-build patches"
    cd $CWD
    for patch_file in post-patch-*.sh; do
        if [ -x $patch_file ]; then
            ./$patch_file || die "Could not apply post-build patch '${patch_file}'"
        fi
    done
    cd $WORK_DIR
    commit_stage "applying-post-patches"
else
    echo "Post-build patches already applied"
fi

cd $CWD

