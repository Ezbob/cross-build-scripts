# cross-build-scripts

This repo contains scripts and tools to build a cross-compiler toolchain using
glibc, gnu binutils, and gcc.

It's all hacked together using BASH scripts, so to use these script having a BASH
interpreter installed is a must.

## How to use

The `build_stuff.sh` script downloads and builds the cross-compiler and it's
dependencies. 

This repo provides various toolchains that should compile out-of-the-box. One of
these toolchains namely the `arm32-gcc10-soft-float` which builds an 32-bit ARM C 
and C++ toolchain, and the `aarch64-gcc10` 64-bit ARM C and C++ toolchain.

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

## Configuring the builds

The `build_stuff.sh` script relies on two configuration files, `variables` 
and `tools` to build toolchains.

The `variables` contains variables that can be used to customize your build. 
This includes where the build is installed, what the compiler triple is, and
the configure flags parsed to the autotool `configure` scripts.

The `tools` contains a listing of the URL, indexed by component names, where 
the different components can be downloaded, as well as their versions 
(this is stated in their names).

Other than the previously mentioned configuration files, patch scripts can also be 
automatically applied by creating executable bash scripts those names matches the 
`patch-*.sh` glob in the same directory as the `variables` and `tools` files. These 
patch scripts are applied just after the toolchain dependencies are downloaded, and 
their working directories are set to the directory where the dependencies are downloaded.


## Using Docker

Scripts and a dockerfile has been provided to create docker images and containers
which can build the toolchains. The main advantages of building in a docker container
is that dependencies are explicitly specified by the Dockerfile, and the dependency
versions can be specified by choosing the right OS version in the FROM clause of the
dockerfile.

Building the docker image can be done by running the script `create_docker_image.sh`:
```bash
./create_docker_image.sh
```

Once the image is built, the `build_with_docker.sh` can be used to build a toolchain by
specifying one of the toolchain folder as the argument to the script.

For an example building the `arm32-gcc10-soft-float` toolchain can be done like this:
```bash
./build_with_docker arm32-gcc10-soft-float
```

The docker container will then clean the existing toolchain files in the 
`arm32-gcc-soft-float` directory, start the build process, and finally pack the
completed toolchain. The packed toolchain will be available in the `arm32-gcc-soft-float`
directory.

Note: The user id and group of the built toolchain files will be set to the internal user
defined by the dockerfile.
