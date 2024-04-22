#!/usr/bin/env bash

parent_dir=${PWD##*/}

if [ "${parent_dir}" = "docker-cluster" ]; then
        echo "Setting up malleability repositories for the docker-cluster environment in the HOST..."
else
        echo "Not in the top directory of the docker-cluster environment. Are you running it from one of the containers? Quitting..." 1>%2
        exit 0
fi

cd build/
build_dir=${PWD}
pwd

echo "============================================================================================================================================"
echo "Cloning projects from the GitLab at JSC and upstream..."
echo "============================================================================================================================================"

# 3 entry tuples per repository: "local-folder URI branch"
declare -a repos=(
                  "openpmix https://github.com/openpmix/openpmix.git v4.2.8"
                  "libdynpm git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/libdynpm.git master"
                  "prrte git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/prrte.git dominik_partec"
                  "slurm git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/slurm.git master"
                  "slurm-plugins git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/slurm-plugins.git master"
                  "pscom git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/pscom.git deep-sea"
                  "psmpi git@gitlab.jsc.fz-juelich.de:deep-sea/wp5/software/psmpi.git deep-sea"
                  )

for repo in "${repos[@]}"
do
        cd ${build_dir}
		set -- ${repo}

        if [ -d "$1" ]; then
                echo "$1 exists and may contain changes; skipping..."
        else
                echo "Cloning $2 into ${PWD}/$1 ..."
                echo "git clone -b $3 $2 $1"
                git clone -b $3 $2 $1
                cd $1
                git submodule update --init --recursive
        fi
        echo "============================================================================================================================================"
done
