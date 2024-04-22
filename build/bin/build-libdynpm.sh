#!/bin/bash -xe

# The configuration of the plugins is similar to that of Slurm,
# but we include an autogen script, and the
# location of Slurm's source tree must be specified.
./autogen.sh

project_name="libdynpm"
source_dir=$PWD
build_dir=build-"$(basename $source_dir)"

echo "building ${project_name} from ${source_dir} into ${build_dir}"
rm -rf ../${build_dir}
mkdir  ../${build_dir}
cd     ../${build_dir}

# need to install in the same location as slurm with --prefix
#${source_dir}/configure --prefix=${LIBDYNPM_ROOT} --with-pmix=${PMIX_ROOT} --enable-silent-rules --with-libevent=${LIBEVENT_ROOT}\
${source_dir}/configure --prefix=${LIBDYNPM_ROOT} --with-pmix=${PMIX_ROOT} --enable-silent-rules \
            2>&1 | tee configure.log.$$ 2>&1
make -j 2>&1 | tee make.log.$$ 2>&1
make -j install 2>&1 | tee make.install.log.$$

# change ownership of the etc/ dir so that the start script can update it based on the testing setup
chown mpiuser:mpiuser -R ${LIBDYNPM_ROOT}/etc/
