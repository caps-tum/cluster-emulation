#!/bin/bash -xe

./autogen.sh

project_name="MPICH"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

${source_dir}/configure --prefix=${MPICH_ROOT} --with-pm=no --with-pmi=pmix --with-pmix=${PMIX_ROOT} --with-slurm=${SLURM_ROOT} --with-device=ch4:ofi \
            2>&1 | tee configure.log.$$ 2>&1
make -j 8 $1 2>&1 | tee make.log.$$ 2>&1
make -j install 2>&1 | tee make.install.log.$$
