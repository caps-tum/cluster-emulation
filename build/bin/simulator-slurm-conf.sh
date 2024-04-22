#!/usr/bin/env bash

if [ $# -ne 2 ]
  then
    echo "usage: node-count cores-per-node"
    echo "for KIT-FH2-2016-1.swf:"
    echo "./build/bin/simulator-slurm-conf.sh 1174 20"
    echo "to run the simulator, first drop into the container, then:"
    echo "cd slurm-plugins"
    echo "./simulator -D 2>&1 | tee output"
    exit -1
fi

# adjust these based on how much you want to share with each container node
NODE_COUNT=$1
echo "Nodes: ${NODE_COUNT}"
CORES_PER_NODE=$2
echo "Cores per node: ${CORES_PER_NODE}"
MB_PER_NODE=2048
FormattedNumber=""

# generating a hostfile for simulation
mkdir -p ./install/slurm/etc/
rm -f ./tmp/hostfile.txt
HostNumber=1
echo "generating a hostfile"
while [[ HostNumber -le ${NODE_COUNT} ]]
do
	FormattedNumber=`printf %02d $HostNumber`
	echo "n${FormattedNumber}" | tee -a ./tmp/hostfile.txt
	((HostNumber++))
done
echo "generated the following hostfile.txt for simulation:"
cat ./tmp/hostfile.txt

echo "processing the provided hostfile"
echo "getting unique entries..."
awk '!a[$0]++' ./tmp/hostfile.txt > ./tmp/unique_hosts
awk 'NR>1' ./tmp/unique_hosts > ./tmp/compute_hosts

# generating slurm.conf dynamically
echo "copying initial slurm.conf work file"
cp -a ./build/bin/simulator-input/slurm.conf.in ./tmp/slurm.conf.initial
cp -a ./build/bin/simulator-input/slurm.conf.in ./tmp/slurm.conf.work
echo "setting up NodeName and PartitionName entries in slurm.conf ..."
rm -f ./tmp/hosts
rm -f ./tmp/nodes
rm -f ./tmp/hostuser
rm -f ./tmp/prrte-hostfile.txt
HostNumber=2
while read h; do
	FormattedNumber=`printf %02d $HostNumber`
	echo "NodeName=n${FormattedNumber} NodeAddr=$h CPUs=${CORES_PER_NODE} RealMemory=${MB_PER_NODE} State=UNKNOWN" >> ./tmp/slurm.conf.work
	echo "$h	n${FormattedNumber}" >> ./tmp/hosts
	echo "n${FormattedNumber}" >> ./tmp/nodes
	echo "n${FormattedNumber} slots=${CORES_PER_NODE}" >> ./tmp/prrte-hostfile.txt
	((HostNumber++))
done < ./tmp/compute_hosts
echo "PartitionName=local Nodes=n[02-${FormattedNumber}] Default=YES MaxTime=INFINITE State=UP" >> ./tmp/slurm.conf.work
echo "${USER}" >> ./tmp/hostuser

FirstNodeName="n01"
FirstNode=`head -n 1 ./tmp/unique_hosts`
echo "ControlMachine=${FirstNodeName}" >> ./tmp/slurm.conf.work
echo "ControlAddr=${FirstNode}" >> ./tmp/slurm.conf.work

cp -a ./tmp/slurm.conf.work ./install/slurm/etc/slurm.conf
cp -a ./tmp/unique_hosts ./install/slurm/etc/unique_hosts
cp -a ./tmp/hosts ./install/slurm/etc/hosts
cp -a ./tmp/nodes ./install/slurm/etc/nodes
cp -a ./tmp/nodes ./build/mrnet-hostfile.txt
cp -a ./tmp/prrte-hostfile.txt ./build/prrte-hostfile.txt
cp -a ./tmp/hostuser ./install/slurm/etc/hostuser
cp -a ./build/bin/slurm-input/deepsea.conf ./install/slurm/etc/deepsea.conf
cp -a ./build/bin/slurm-input/cgroup.conf ./install/slurm/etc/cgroup.conf

printf "\nhosts:\n"
cat ./install/slurm/etc/hosts
printf "\nhost user:\n"
cat ./install/slurm/etc/hostuser
printf "\nslurm.conf partition:\n"
tail -3 ./install/slurm/etc/slurm.conf

exit 0
