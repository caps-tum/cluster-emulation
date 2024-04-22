#!/bin/bash

#
# Default values
#
IMAGE_NAME=docker-cluster:slurm
OVERLAY_NETWORK=pmix-net
NNODES=5
INSTALL_DIR=
BUILD_DIR=

MPI_HOSTFILE=$PWD/tmp/hostfile.txt
HOSTFILE=$PWD/tmp/hosts
AUTHORIZEDKEYS=$PWD/tmp/authorized_keys
SHUTDOWN_FILE=$PWD/tmp/shutdown-`hostname -s`.sh


# Argument parsing
while [[ $# -gt 0 ]] ; do
    case $1 in
        "-h" | "--help")
            printf "Usage: %s [option]
    -p | --prefix PREFIX       Prefix string for hostnames (Default: %s)
    -n | --num NUM             Number of nodes to start on this host (Default: %s)
    -i | --image NAME          Name of the container image (Required)
    -h | --help                Print this help message\n" \
        `basename $0` $NNODES
            exit 0
            ;;
        "-n" | "--num")
            shift
            NNODES=$1
            ;;
        "-i" | "--image" | "-img")
            shift
            IMAGE_NAME=docker-cluster:$1
            ;;
        *)
            printf "Unkonwn option: %s\n" $1
            exit 1
            ;;
    esac
    shift
done

if [ "x$IMAGE_NAME" == "x" ] ; then
    echo "Error: --image must be specified"
    exit 1
fi

# Spin up all of the containers
ALL_CONTAINERS=()
startup_container()
{
    C_ID=$(($1 + 0))
    C_HOSTNAME=`printf "%s%02d" "n" $C_ID`

    echo "Starting: $C_HOSTNAME"

    # --privileged
    #   - Needed for debugger support on Mac to set ptrace_scope
    # Since this setting is "sticky" we can set it before starting the cluster
    # so we do not need to run the cluster in privileged mode.
    CMD=(docker run --privileged ${IMAGE_NAME} sh -c "echo 0 > /proc/sys/kernel/yama/ptrace_scope")
    "${CMD[@]}"
    RTN=$?
    if [ 0 != $RTN ] ; then
        echo "Error: Failed to adjust ptrace_scope"
        exit 1
    fi

    CMD="docker run --rm \
        --cap-add=SYS_NICE --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
        -v install:/opt/hpc/install \
        -v build:/opt/hpc/build \
        -h $C_HOSTNAME --name $C_HOSTNAME \
        --detach $IMAGE_NAME"

    C_FULL_ID=`$CMD`
    RTN=$?
    if [ 0 != $RTN ] ; then
        echo "Error: Failed to create $C_HOSTNAME"
        echo $C_FULL_ID
        exit 1
    fi

    C_SHORT_ID=`echo $C_FULL_ID | cut -c -12`
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $C_SHORT_ID >> $MPI_HOSTFILE
    ALL_CONTAINERS+=($C_SHORT_ID)
}

docker volume create --driver local --name build --opt type=none --opt device=$PWD/build --opt o=uid=root,gid=root --opt o=bind > /dev/null 2>&1
docker volume create --driver local --name install --opt type=none --opt device=$PWD/install --opt o=uid=root,gid=root --opt o=bind > /dev/null 2>&1

mkdir -p tmp
mkdir -p install/etc/
rm -rf $MPI_HOSTFILE
rm -rf $HOSTFILE
rm -rf $AUTHORIZEDKEYS
rm -rf ./install/etc/hosts
rm -rf ./install/etc/authorized_keys
touch $MPI_HOSTFILE
touch $HOSTFILE
touch $AUTHORIZEDKEYS

cat ~/.ssh/*.pub > $AUTHORIZEDKEYS
chmod 644 $AUTHORIZEDKEYS

# Create each virtual node
for i in $(seq 1 $NNODES); do
    startup_container $i
done

# Create a shutdown file to help when we cleanup
rm -f $SHUTDOWN_FILE

touch $SHUTDOWN_FILE
chmod +x $SHUTDOWN_FILE
for cid in "${ALL_CONTAINERS[@]}" ; do
    echo "docker stop $cid" >> $SHUTDOWN_FILE
done

cp -a $HOSTFILE ./install/etc/hosts
cp -a $AUTHORIZEDKEYS ./install/etc/authorized_keys

# generate configurations
./build/bin/generate-configurations.sh
docker exec -it -u root n01 /opt/hpc/build/bin/set-authorized-keys.sh

HostNumber=1
FormattedNumber=""
while read h; do
    FormattedNumber=`printf %02d $HostNumber`
    docker exec -u root n${FormattedNumber} /opt/hpc/build/bin/set-hosts.sh
    docker exec -u root n${FormattedNumber} groupadd -g `id -g` mpigroup > /dev/null 2>&1
    docker exec -u root n${FormattedNumber} usermod mpiuser -u `id -u`   > /dev/null 2>&1
    docker exec -u root n${FormattedNumber} usermod mpiuser -g `id -g`   > /dev/null 2>&1
    ((HostNumber++))
done < ./tmp/all_nodes

# uncomment below if you want slurm to be started automatically
# this requires that you have previously built slurm inside the container
#docker exec -u 0 -it n01 /opt/hpc/build/bin/bootstrap-slurm.sh
