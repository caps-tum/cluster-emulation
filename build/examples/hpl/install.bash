#!/usr/bin/env bash

wget http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
tar xf hpl-2.3.tar.gz 
cd hpl-2.3
./configure --prefix=$PWD/../  --enable-silent-rules

