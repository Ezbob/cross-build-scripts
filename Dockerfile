FROM debian:stretch-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y gcc g++ autoconf automake make bison gawk flex tar xz-utils gzip wget bzip2 texinfo python3

RUN groupadd builder
RUN useradd -G builder -s /bin/bash bob

RUN mkdir -p /opt/crossgcc/build
RUN chown -R bob:builder /opt/crossgcc/

ENV GCC_BUILD_DIR=/opt/crossgcc/build

WORKDIR /opt/crossgcc/build
USER bob

COPY *.sh /opt/crossgcc/lib/

ENTRYPOINT ../lib/clean_all.sh && ../lib/build_stuff.sh && ../lib/pack_toolchain.sh
