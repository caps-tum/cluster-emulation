#!/bin/bash -xe

./autogen.sh

project_name="ParaStation MPI"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

${source_dir}/configure --prefix=${PSMPI_ROOT} \
            --with-pmix=${PMIX_ROOT} \
            --with-confset=devel \
            --without-cuda \
            --with-pscom=${PSCOM_ROOT} \
            2>&1 | tee configure.log.$$ 2>&1
make -j4 2>&1 | tee make.log.$$ 2>&1
make install 2>&1 | tee make.install.log.$$
