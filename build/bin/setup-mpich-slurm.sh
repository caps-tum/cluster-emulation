#!/usr/bin/env bash

parent_dir=${PWD##*/}

if [ "${parent_dir}" = "build" ]; then
	echo "Setting up mpich+openpmix+slurm combination for the docker-cluster environment..."
else
	echo "Not in the build/ directory of the docker-cluster environment. Quitting..."
	exit 0
fi

declare -a repos=("openpmix" "slurm" "mpich")

echo "================================================================================"
for repo in "${repos[@]}"
do
	if [ -d "${repo}" ]; then
		echo "building ${repo}..."
		cd ${repo}
		../bin/build-${repo}.sh
		cd ..
	else 
		echo "${repo} does not exist; abborting..."
		exit -1
	fi
	echo "================================================================================"
done
