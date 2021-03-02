#!/bin/bash

# Exit function that prints a message before exiting
die() {
    echo "Error: $1"
    exit 1
}

# Change shell title
print_title() {
    local title=$1
    echo -e '\033]2;'$title'\007'
}

CWD=$(pwd)

[ ! -f "variables" ] && die "'variables' file missing"

. variables

TOOLS_FILE=$(realpath ${TOOLS_FILE})
CACHE_DIR=$(realpath ${CACHE_DIR})

mkdir -p "${CACHE_DIR}"
cd "${CACHE_DIR}"

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
        wget $url || die "Could not download $package from $url"
        echo "$name $package" >> .downloaded
    fi
done < ${TOOLS_FILE}

cd $CWD
