#!/usr/bin/env bash

build_dir=${PWD}

if [ "${build_dir}" = "/opt/hpc/build" ]; then
        echo "Building malleability repositories for the docker-cluster environment in the CONTAINER..."
else
        echo "Not in the /opt/hpc/build of the docker-cluster container environment. Quitting..." 1>%2
        exit 0
fi

echo "============================================================================================================================================"
echo "Building malleability repos..."
echo "============================================================================================================================================"

# List of repositories to build; can be customized here
# Note that these are ordered based on their interdepencies
declare -a repos=( "openpmix" "libdynpm" "prrte" "slurm" "slurm-plugins" "pscom" "psmpi")

for repo in "${repos[@]}"
do
        cd ${build_dir}

        if [ -d "$repo" ]; then
                echo "Building $repo..."
                cd $repo
				echo "Running ./bin/build-$repo.sh on ${build_dir}/$repo/"
				../bin/build-$repo.sh
        else
                echo "$repo does not exist. Quitting..."
				exit 0
        fi
        echo "============================================================================================================================================"
done

