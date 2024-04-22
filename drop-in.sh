#!/bin/bash

if [ -z "$1" ]
then
    echo "Dropping into n01..."
    docker exec -it -u root -w  /opt/hpc/build/ --env COLUMNS=`tput cols` --env LINES=`tput lines` n01 bash
else 
    nodenumber=`printf %02d $1`
    echo "Dropping into n${nodenumber}..."
    docker exec -it -u root -w  /opt/hpc/build/ --env COLUMNS=`tput cols` --env LINES=`tput lines` n${nodenumber} bash
fi
