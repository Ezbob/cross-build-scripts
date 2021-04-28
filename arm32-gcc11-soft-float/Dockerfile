FROM gcc_builder_base:latest

VOLUME /output
COPY tools ${GCC_BUILD_DIR}/ 
COPY variables ${GCC_BUILD_DIR}/
COPY post-patch-*.sh ${GCC_BUILD_DIR}/
COPY patch-*.sh ${GCC_BUILD_DIR}/

CMD ./build_stuff.sh && DESTDIR=/output ./pack_toolchain.sh
