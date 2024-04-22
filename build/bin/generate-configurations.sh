#!/usr/bin/env bash

# adjust these based on how much you want to share with each container node
CORES_PER_NODE=8
MB_PER_NODE=2048

# make sure install directories are available
mkdir -p ./install/slurm/etc/
mkdir -p ./install/libdynpm/etc/
# processing host-file
echo "processing the provided hostfile "
echo "getting unique entries..."
awk '!a[$0]++' ./tmp/hostfile.txt > ./tmp/unique_hosts
awk 'NR>1' ./tmp/unique_hosts > ./tmp/compute_hosts

# generating slurm.conf dynamically
echo "copying initial slurm.conf work file"
cp -a ./build/bin/slurm-input/slurm.conf.in ./tmp/slurm.conf.initial
cp -a ./build/bin/slurm-input/slurm.conf.in ./tmp/slurm.conf.work
echo "setting up NodeName and PartitionName entries in slurm.conf ..."
rm -f ./tmp/hosts
rm -f ./tmp/nodes
rm -f ./tmp/all_nodes
rm -f ./tmp/hostuser
rm -f ./tmp/prrte-hostfile.txt

HostNumber=1
FormattedNumber=""
while read h; do
	FormattedNumber=`printf %02d $HostNumber`
	echo "$h	n${FormattedNumber}" >> ./tmp/hosts
	echo "n${FormattedNumber}" >> ./tmp/all_nodes
	((HostNumber++))
done < ./tmp/unique_hosts

HostNumber=2
FormattedNumber=""
while read h; do
	FormattedNumber=`printf %02d $HostNumber`
	echo "NodeName=n${FormattedNumber} NodeAddr=$h CPUs=${CORES_PER_NODE} RealMemory=${MB_PER_NODE} State=UNKNOWN" >> ./tmp/slurm.conf.work
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
cp -a ./build/bin/slurm-input/cgroup.conf ./install/slurm/etc/cgroup.conf
cp -a ./build/bin/slurm-input/dynpm.conf ./install/libdynpm/etc/dynpm.conf

mkdir -p ./install/etc/
cp -a ./tmp/unique_hosts ./install/etc/unique_hosts
cp -a ./tmp/hosts ./install/etc/hosts
cp -a ./tmp/nodes ./install/etc/nodes
cp -a ./tmp/nodes ./install/etc/mrnet-hostfile.txt
cp -a ./tmp/prrte-hostfile.txt ./install/etc/prrte-hostfile.txt
cp -a ./tmp/hostuser ./install/etc/hostuser

printf "\nhosts:\n"
cat ./install/etc/hosts
printf "\nhost user:\n"
cat ./install/etc/hostuser
printf "\nslurm.conf partition:\n"
tail -3 ./install/slurm/etc/slurm.conf

exit 0
