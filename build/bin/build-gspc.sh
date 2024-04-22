#!/bin/bash -xe

#WorkingDir
WDIR=$(pwd)
#hwloc path
export PKG_CONFIG_PATH="${HWLOC_INSTALL_PATH}/lib/pkgconfig:"${PKG_CONFIG_PATH}

# Build GPI Space dependency Boost if not already built
boost_version=1.63.0
export BOOST_ROOT=${GSPC_ROOT}/boost

if [[ ! -d "./boost_gspc" ]] 
then
  mkdir -p "./boost_gspc"
  cd boost_gspc
  wget "https://downloads.sourceforge.net/project/boost/boost/${boost_version}/boost_${boost_version//./_}.tar.gz" \
    -O boost_${boost_version//./_}.tar.gz
  tar -xf "boost_${boost_version//./_}.tar.gz"
  cd "boost_${boost_version//./_}"

  ./bootstrap.sh --prefix="${BOOST_ROOT}"
  ./b2                               \
    cflags="-fPIC -fno-gnu-unique"   \
    cxxflags="-fPIC -fno-gnu-unique" \
    link=static                      \
    variant=release                  \
    install                          \
    -j $(nproc)
fi
cd ${WDIR}

# Build GPI Space dependency GPI2 if not already built
GPI2132_ROOT=${GSPC_ROOT}/GPI2
gpi2_version=1.3.2

if [ ! -d "./gpi2_gspc" ]; then
  mkdir -p "./gpi2_gspc"
  cd "./gpi2_gspc"
  wget "https://github.com/cc-hpc-itwm/GPI-2/archive/v${gpi2_version}.tar.gz" \
    -O "GPI-2-${gpi2_version}.tar.gz"
  tar xf "GPI-2-${gpi2_version}.tar.gz"
  cd "GPI-2-${gpi2_version}"

  ./install.sh -p "${GPI2132_ROOT}" \
      --with-fortran=false         \
      --with-ethernet
fi
export PKG_CONFIG_PATH="${GPI2132_ROOT}/lib64/pkgconfig:"${PKG_CONFIG_PATH}
cd ${WDIR}

# Build GPI Space dependency libssh2 if not already built
LIBSSH2_ROOT=${GSPC_ROOT}/libssh2
libssh2_version=1.9.0

if [ ! -d "./libssh2_gspc" ]; then
  mkdir -p "./libssh2_gspc"
  cd "./libssh2_gspc"
  wget "https://github.com/libssh2/libssh2/releases/download/libssh2-${libssh2_version}/libssh2-${libssh2_version}.tar.gz" \
  -O "libssh2-${libssh2_version}.tar.gz"
  tar xf "libssh2-${libssh2_version}.tar.gz"
  mkdir "libssh2-${libssh2_version}/build"
  cd "libssh2-${libssh2_version}/build"

  cmake -D CRYPTO_BACKEND=OpenSSL               \
      -D CMAKE_BUILD_TYPE=Release               \
      -D CMAKE_INSTALL_PREFIX="${LIBSSH2_ROOT}" \
      -D ENABLE_ZLIB_COMPRESSION=ON             \
      -D BUILD_SHARED_LIBS=ON                   \
      -D BUILD_TESTING=OFF                      \
      ..
  cmake --build . --target install -- -j$(nproc)
fi
export PKG_CONFIG_PATH="${LIBSSH2_ROOT}/lib64/pkgconfig:"${PKG_CONFIG_PATH}
cd ${WDIR}

# Build GPI Space
gpispace_version=main

if [ ! -d "gpispace-${gpispace_version}" ]; then
  wget "https://github.com/cc-hpc-itwm/gpispace/archive/${gpispace_version}.tar.gz" \
    -O "gpispace-${gpispace_version}.tar.gz"
  tar xf "gpispace-${gpispace_version}.tar.gz"
fi

cmake -D CMAKE_INSTALL_PREFIX="${GSPC_ROOT}"  \
      -D GSPC_WITH_MONITOR_APP="OFF"          \
      -B "gpispace-${gpispace_version}/build" \
      -S "gpispace-${gpispace_version}"
cmake --build "gpispace-${gpispace_version}/build" \
      --target install                             \
      -j $(nproc)
