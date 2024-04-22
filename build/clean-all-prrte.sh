#!/usr/bin/env bash

HOSTUSER=$(head -n 1 /opt/hpc/install/etc/hostuser)
NODECOUNT=$(wc -l < /opt/hpc/install/etc/unique_hosts)

echo "Host user: ${HOSTUSER}"
echo "Node count: ${NODECOUNT}"

for ((h=1; h <= ${NODECOUNT}; h++))
do
        nodenumber=$(printf "%02d" ${h})
        echo "ssh n${nodenumber} /opt/hpc/build/bin/clean-prrte.sh"
        ssh n${nodenumber} /opt/hpc/build/bin/clean-prrte.sh || true
done


