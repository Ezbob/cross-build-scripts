# cross-build-scripts

This repo contains scripts and tools to build a cross-compiler toolchain using
glibc, gnu binutils, and gcc.

## how to use

Update the `variables` file to suit your needs. This file contains some of the
variables that can be used to customize your build.

Update the `tools` file to suit your needs. This file contains a listing of the
URL where the different components can be downloaded, as well as their versions
(this is stated in their names).
The listing format is as follows:

Each lines of the file contains one component entry. A component entry contains
a name of the component followed by one or more spaces, and a url where that
component can be found.

Then run the `build_stuff.sh` script from it's containing folder, to start the
download and building process.

Errors/patches can be applied to the components which are extracted in the 
work directory (usually called `workdir`), and the `build_stuff.sh` script
can be run again, as it should remember what steps were successful.

