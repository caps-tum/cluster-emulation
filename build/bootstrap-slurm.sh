#!/usr/bin/env bash

HOSTUSER=$(head -n 1 /opt/hpc/install/etc/hostuser)
NODECOUNT=$(wc -l < /opt/hpc/install/etc/unique_hosts)

echo "Host user: ${HOSTUSER}"
echo "Node count: ${NODECOUNT}"

for ((h=1; h <= ${NODECOUNT}; h++))
do
        nodenumber=$(printf "%02d" ${h})
        echo "ssh n${nodenumber} /opt/hpc/build/bin/start-munge.sh"
        ssh n${nodenumber} /opt/hpc/build/bin/start-munge.sh || true
done

# make sure the munged daemons have started before we begin starting the slurmds
sleep 2

for ((h=2; h <= ${NODECOUNT}; h++))
do
        nodenumber=$(printf "%02d" ${h})
        echo "ssh n${nodenumber} /opt/hpc/build/bin/start-slurmd.sh"
        ssh n${nodenumber} /opt/hpc/build/bin/start-slurmd.sh || true
done

# make sure the slurmd daemons have started before we begin starting slurmctld
sleep 2

echo "starting the controller..."
/opt/hpc/install/slurm/sbin/slurmctld
sleep 5

echo "Checking with \"sinfo\""
echo ""
/opt/hpc/install/slurm/bin/sinfo

tail -f /var/log/slurmctld.log
