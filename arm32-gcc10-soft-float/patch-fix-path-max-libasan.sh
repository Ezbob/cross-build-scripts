#!/bin/bash

die() {
    echo "Error: $1"
    exit 1 
}

[ ! -f variables  ] && die "'variables': No such file"

. variables

line=66
file=${WORK_DIR}/gcc-*/libsanitizer/asan/asan_linux.cpp 
    # file works because we only have one gcc extracted folder

sed -i -f - $file <<EOF 
${line} i\\
#ifndef PATH_MAX\\
#define PATH_MAX 4096\\
#endif\\
EOF
