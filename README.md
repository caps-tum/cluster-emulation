# DEEP-SEA Docker Cluster

## Derived Work

This development and testing environment is derived work from:

https://github.com/jjhursey/pmix-swarm-toy-box

Especial thanks to Josh Hursey for kindly allowing us to reuse his work.

## Installing Docker

Follow the Docker installation instructions for your Linux distribution.  For example, Ubuntu:
https://docs.docker.com/engine/install/ubuntu/

It is recommended to use your own regular user, and not root.  Make sure to add your user to the docker group, as stated in the installation instructions:

```
usermod -aG docker $USER
```

Initialize the swarm cluster:

```
docker swarm init
```

## Build the Docker image

```
./docker-build.sh
```

Example:
```
shell$ ./docker-build.sh
Bulding with Dockerfile.slurm ...
Sending build context to Docker daemon  12.04MB
Step 1/38 : FROM rockylinux:8
 ---> 1e1148e4cc2c
Step 2/38 : MAINTAINER Isaias A. Compres U. <isaias.compres@tum.de>
...
Successfully built 84d26427c5bf
Successfully tagged ompi-toy-box:latest
```

The Slurm specific Dockerfile.slurm is selected by default.  It can be selected explicitly as follows:

```
shell$ ./docker-build.sh slurm
Bulding with Dockerfile.slurm ...
...
```

For a customized build, simply make a copy of one of the Dockerfile and give it a custom extension.  For example, you can start from the Dockerfile.slurm, by making a copy and renaming it:

```
cp -a Dockerfile.slurm Dockerfile.foo
```

You can then update the file, and produce a custom build:

```
shell$ ./docker-build.sh foo
Bulding with Dockerfile.foo ...
...
```

## Setup your development environment outside the container

We try to keep the container image as small as possible.
For this, the source code and build files are kept in the host system, and mounted in the container.
We will use volume mounts for this purpose.
We are using the local disk as a shared file system between the host and the containers.

The key to making this work is that you can edit the source code outside of the container, but all builds must occur inside the container.
This is because the relative paths to dependent libraries and install directories are relative to the paths inside the container's file system not the host file system.

Note that this will work when using Docker Swarm on a single machine. More work is needed if you are running across multiple physical machines.

### Checkout your software in the 'build/' directory

For ease of use, we will checkout the software into a `$TOPDIR/build` subdirectory.
`$TOPDIR` is where this `README.md` file is located.
We will mount this directory in `/opt/hpc/build` inside the container.
The sub-directory names for the git checkouts can be whatever you want.
You can have any number of checked-out repositories of the same software project, but only one will be installed at a time.

Move to the 'build' directory:

```
cd $TOPDIR/build
```

Check out the code under this directory.  For example, you can checkout the DEEP-SEA fork of Open PMIx as follows:

```
git clone git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/openpmix.git
```

You can issue the following commands to clone the DEEP-SEA forks that are currently available:

#### MPICH
```
git clone git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/mpich.git
```
#### Open MPI
```
git clone git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/ompi.git
```
#### Open PMIx
```
git clone git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/openpmix.git
```
#### PRRTE
```
git clone git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/prrte.git
```
#### Slurm
```
git clone git@gitlab.jsc.fz-juelich.de:deep-sea/wp3/software/slurm.git
```

### A common 'install/' directory is defined in the build scripts

This directory serves as the shared install file system for the builds.
We mount this directory in `/opt/hpc/install` inside the container.
The container's environment is setup taking these paths into account.

This directory will be created automatically either by the first build of any of the software projects, or by the 'slurm.conf' generation script.

## Startup the cluster

A script to start a specified number of containers is provided.
This script will:
 * Create a private overlay network between the pods (`docker network create --driver overlay --attachable`)
 * Start N containers each named `nXY` where XY is the node number starting from `01`. Up to `99` containers can be started.

For example, to start 3 containers (1 login and controller, 2 work nodes), issue:

```
./start.sh -n 3
Establish network: pmix-net
Starting: n01
Starting: n02
Starting: n03
processing the provided hostfile
getting unique entries...
copying initial slurm.conf work file
setting up NodeName and PartitionName entries in slurm.conf ...

hosts:
10.0.13.4	n02
10.0.13.5	n03

host user:
<host-user>

slurm.conf partition:
PartitionName=local Nodes=n[02-03] Default=YES MaxTime=INFINITE State=UP
ControlMachine=n01
ControlAddr=10.0.13.2
```

After the cluster is created, a Slurm configuration file is generated automatically.

## Drop into the first node

There is a convenience script that drops us into a terminal on the first host of the swarm:

```
./drop-in.sh
```

This script drops you in as 'root'.
This is useful for building.

To drop in as a regular user, for example, to run applications, it is recommended to drop in as the 'mpiuser' instead:

```
./mpiuser-drop-in.sh
```

## Compile your code inside the first node

Edit your code on the host file system as normal.
The changes to the files are immediately reflected inside all of the swarm containers.
When you are ready to compile drop into the container, change to the source directory, and build as normal.

Build scripts for the DEEP-SEA forks are provided in `$TOPDIR/build/bin`.
As already stated, these are mounted under `/opt/hpc/build/bin`.
These need to be copied once to the 'build' directory, so that they can be called inside the container environment.

For example, Open PMIx can be built as follows:

```
[root@n1 ~]$ cd /opt/hpc/build/openpmix
[root@n1 openpmix]$ ../bin/build-openpmix.sh
...
```

## Shutdown the cluster

The start.sh script creates a shutdown file that can be used to cleanup when you are done.
This should be called from the host environment:

```
./tmp/shutdown-*.sh
```

## Setting up and bootstrapping Slurm

Similarly to the other tools discussed above, in the host, place the source code of Slurm under the 'build' directory:
Make sure that the Docker cluster has been started with the 'start.sh' script as documented above.

Drop in to the first node, as root, and build Slurm:

```
host$ ./drop-in.sh
[root@n01 build]#
```

Move to the source code directory, usually named 'slurm', and use the provided script to build it.
Please note that Slurm depends on 'Mumge', 'hwloc' and 'Open PMIx'.
'Munge' and 'hwloc' are built into the image with the provided 'Dockerfile.slurm' file.
However, we recommend that you build the 'Open PMIx' library in the 'build' directory with the provided 'bin/build-openpmix.sh' script.
Please refer to the instructions above.

```
[root@n01 build]# cd /opt/hpc/build/slurm
[root@n01 build]# ../bin/build-slurm.sh
```

Once Slurm is built and installed, you need to bootstrap the 'munged' and 'slurmd' daemons in all nodes.
The 'slurmctld' daemon needs to be started in the first node only.
For this task, a bootstrap script is provided.
The bootstrap script needs to be run as the *root* user, once from the first node:

```
root@user-node01$ /opt/hpc/build/bootstrap-slurm.sh
starting munged in host 10.0.15.2
starting munged in host 10.0.15.4
starting munged in host 10.0.15.5
starting slurmd in host 10.0.15.4
starting slurmd in host 10.0.15.5
starting the controller...

```

At this point, it is recommended to become the *mpiuser* to run or queue jobs in the cluster.
For applications that use more that one node, you need to place your binaries and inputs under the 'build' directory, so that all processes have access to them from the same path.

If the cluster is restarted, the Slurm configuration needs to be regenerated, and the daemons need to be bootstrapped again.
Docker will assign different IPs to the hosts every time they are launched.


# Project Specific Instructions

## Compile and install GPI2

To build and install GPI-2, we first download and extract the sources.  A convenience script is provided for this purpose.  From the 'build' directory in the *host* environment, issue:

```
../bin/setup-gpi2-sources.sh
```

Proceed to drop into the container environment to build it:

```
cd /opt/hpc/build/GPI-2-<version>
../bin/build-gpi2.sh
```

## Compile and install GPI-Space

To build GPI-Space, its dependencies also need to be built. From the GPI-Space build directory use the build script.
```
[mpiuser@owais-node01 ~]$ cd /opt/hpc/build
[mpiuser@owais-node01 build]$ mkdir -p GSPC
[mpiuser@owais-node01 build]$ cd GSPC
[mpiuser@owais-node01 GSPC]$ sudo -E ../bin/build-gspc.sh
```

## DEEP-SEA project setup

The DEEP-SEA project's prototype is composed of the following software components:
- Slurm
- Malleable scheduler plugin
- Open PMIx version 4.2.8
- Dynamic Process Management library (dynpm)
- ParaStation communication library (pscom)
- ParaStation MPI library (psmpi)
- PMIx reference runtime environment (PRRTE)

We have provided deployment scripts for this software stack.  Once the Docker image is ready with the _docker-build.sh_ script (see instructions above), then two additional steps are necessary.

First, from the host machine, and from the top _docker-cluster_ directory, run the following script:

```
host$ ./build/deepsea-host-setup-malleability-repos.bash
```

This will clone the source code for each of the software projects listed above.  This operation requires access to the DEEP-SEA WP3 and WP5 repositories, hosted at the Julich Supercomputing Centre.  After completion, the cluster emulation environment can be started with the _start.sh_ script.

Once the environment has started, use the _drop-in.sh_ script to enter into the first node as root, and run:

```
[root@n01 build]# ./deepsea-container-build-malleability-repos.bash

```

This script will build all of the software packages in the required order, based on their dependencies.  Once build, Slurm can be bootstrapped as documented above, and once ready, batch jobs can be submitted to it.
