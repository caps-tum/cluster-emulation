#!/usr/bin/env bash

# bootstrap without starting the munged daemons
# this is useful when restarting Slurm daemons after a recompile

/opt/hpc/install/slurm/bin/scontrol shutdown

HOSTUSER=$(head -n 1 /opt/hpc/install/etc/hostuser)
NODECOUNT=$(wc -l < /opt/hpc/install/etc/unique_hosts)

echo "Host user: ${HOSTUSER}"
echo "Node count: ${NODECOUNT}"

for ((h=2; h <= ${NODECOUNT}; h++))
do
        nodenumber=$(printf "%02d" ${h})
        echo "ssh n${nodenumber} /opt/hpc/build/bin/start-slurmd.sh"
        ssh n${nodenumber} /opt/hpc/build/bin/start-slurmd.sh || true
done

echo "starting the controller..."
/opt/hpc/install/slurm/sbin/slurmctld

echo "Checking with \"sinfo\""
echo ""
/opt/hpc/install/slurm/bin/sinfo
