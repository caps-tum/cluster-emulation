#!/bin/bash -xe

./autogen.pl

project_name="Open PMIx"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

#${source_dir}/configure --prefix=${PMIX_ROOT} --enable-debug --disable-debug-symbols --with-libevent=${LIBEVENT_ROOT} \
${source_dir}/configure --prefix=${PMIX_ROOT} --enable-debug --disable-debug-symbols \
            2>&1 | tee configure.log.$$ 2>&1
make -j 2>&1 | tee make.log.$$ 2>&1
make -j install 2>&1 | tee make.install.log.$$
