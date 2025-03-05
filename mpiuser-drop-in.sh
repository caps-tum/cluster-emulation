#!/bin/bash

echo "Dropping into n01 as mpiuser at /opt/hpc/build/examples"
docker exec -it -u mpiuser -w  /opt/hpc/build/examples/tests --env COLUMNS=`tput cols` --env LINES=`tput lines` n01 bash
