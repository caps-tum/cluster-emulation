#!/bin/bash -xe

# Slurm code is distributed with pre-generated autotools based buildsystem

# For DEEP-SEA, we have stripped the pre-generated files; therefore, they
# need to be generated before calling configure
# update 22.4.2022: upstream has accepted the pmix v5 patch (sorted until Open PMIx v6)
# autoreconf -fi

project_name="Slurm"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

${source_dir}/configure --prefix=${SLURM_ROOT} --with-pmix=${PMIX_ROOT} --enable-silent-rules \
            2>&1 | tee configure.log.$$ 2>&1
make -j 2>&1 | tee make.log.$$ 2>&1
make -j install 2>&1 | tee make.install.log.$$
