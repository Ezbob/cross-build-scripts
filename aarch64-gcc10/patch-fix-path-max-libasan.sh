#!/bin/bash

line=66
file=$(pwd)/gcc-*/libsanitizer/asan/asan_linux.cpp 
    # file works because we only have one gcc extracted folder

sed -i -f - $file <<EOF 
${line} i\\
#ifndef PATH_MAX\\
#define PATH_MAX 4096\\
#endif\\
EOF
