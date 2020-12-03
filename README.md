# cross-build-scripts

This repo contains scripts and tools to build a cross-compiler toolchain using
glibc, gnu binutils, and gcc.

It's all hacked together using BASH scripts, so to use these script having BASH
installed is a must.

## how to use

The `build_stuff.sh` script downloads and builds the cross-compiler and it's
dependencies. 

This repo provides two toolchains that should compile out-of-the-box, namely
the `arm32-gcc10-soft-float` which builds an 32-bit ARM C and C++
toolchain, and the `aarch64-gcc10` 64-bit ARM C and C++ toolchain.

To build `arm32-gcc10-soft-float` simply goto the `arm32-gcc10-soft-float` 
directory:
```bash
cd arm32-gcc10-soft-float/
```
... And run the `build_stuff.sh` script from there:
```bash
../build_stuff.sh
```
This should start the download and build process.

## configuring the builds

The `build_stuff.sh` script relies on two configuration files, `variables` 
and `tools` to build toolchains.

The `variables` contains variables that can be used to customize your build. 
This includes where the build is installed, what the compiler triple is, and
the configure flags parsed to the autotool `configure` scripts.

The `tools` contains a listing of the URL, indexed by component names, where 
the different components can be downloaded, as well as their versions 
(this is stated in their names).

Other than the previously mentioned configuration files, patch scripts can 
also be automatically applied by creating executable bash scripts those 
names matches the `patch-*.sh` glob in the same directory as the `variables` 
and `tools` files. These patch script are applied just after the toolchain
dependencies are downloaded, and their working directories are set to the 
directory where the dependencies are downloaded.
