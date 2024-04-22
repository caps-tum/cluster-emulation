#!/usr/bin/env bash

wget http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.9.tar.gz
tar xf osu-micro-benchmarks-5.9.tar.gz 
cd osu-micro-benchmarks-5.9
./configure --prefix=$PWD/../ CC=mpicc --enable-silent-rules
make -j
cd ..
#mv libexec/osu-micro-benchmarks/mpi/* .
#rm -rf libexec/
