FROM debian:stretch-slim

RUN export DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y gcc g++ autoconf automake make bison gawk flex tar xz-utils gzip wget bzip2 texinfo python3

RUN groupadd builder
RUN useradd -G builder -s /bin/bash bob

RUN mkdir -p /opt/crossgcc/
RUN chown -R bob:builder /opt/crossgcc

ENV GCC_BUILD_DIR=/opt/crossgcc

WORKDIR /opt/crossgcc
USER bob

COPY *.sh /opt/crossgcc/

ENTRYPOINT ./build_stuff.sh && ./pack_toolchain.sh
