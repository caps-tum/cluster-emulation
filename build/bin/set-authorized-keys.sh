#!/usr/bin/env bash

cat /opt/hpc/install/etc/authorized_keys >> /root/.ssh/authorized_keys
cat /opt/hpc/install/etc/authorized_keys >> /home/mpiuser/.ssh/authorized_keys
