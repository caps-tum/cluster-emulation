#!/bin/bash -xe

project_name="pscom"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

cmake -DCMAKE_INSTALL_PREFIX:PATH=${PSCOM_ROOT} -S${source_dir} -B. \
       2>&1 | tee configure.log.$$ 2>&1
make -j 4 2>&1 | tee make.log.$$ 2>&1
make install 2>&1 | tee make.install.log.$$
