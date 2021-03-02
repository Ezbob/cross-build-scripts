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

[ ! -f "${TOOLS_FILE}" ] && die "TOOLS_FILE is not a file"

[ -z "${CACHE_DIR}" ] && die "CACHE_DIR variable is not defined"

mkdir -p "${CACHE_DIR}" || die "Could not create cache directory"
cd "${CACHE_DIR}"

echo "Downloading dependencies from TOOLS_FILE..."
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
        wget -q --show-progress $url || die "Could not download $package from $url"
        echo "$name $package" >> .downloaded
    fi
done < ${TOOLS_FILE}

echo "Done."

cd $CWD
