#!/bin/bash -xe

./autogen.sh

project_name="rsched"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

${source_dir}/configure --prefix=${RSCHED_ROOT} --with-pmix=${PMIX_ROOT} --enable-silent-rules \
            2>&1 | tee configure.log.$$ 2>&1
make -j 2>&1 | tee make.log.$$ 2>&1
make -j install 2>&1 | tee make.install.log.$$

# change ownership of the etc/ to the mpi user
chown mpiuser:mpiuser -R ${LIBDYNPM_ROOT}/etc/
