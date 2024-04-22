#!/bin/bash

if [ -z "$1" ]
then
    echo "Bulding with Dockerfile.slurm ..."
    docker build -t docker-cluster:slurm -f Dockerfile.slurm .
else 
    echo "Bulding with Dockerfile.$1 ..."
    docker build -t docker-cluster:$1 -f Dockerfile.$1 .
fi


