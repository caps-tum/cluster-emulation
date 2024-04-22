#
# Base Build box for Slurm
#
# Directory structure for volume mounting
# - Build directory to mount in the source from the local file system
#   /opt/hpc/local/build/
# - Install directory to mount in an installation directory to be shared between containers
#   /opt/hpc/install/
#

FROM rockylinux:9

MAINTAINER Isaias A. Compres U. <isaias.compres@tum.de>

# ------------------------------------------------------------
# Install required packages
# ------------------------------------------------------------
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y --enablerepo=epel install htop && \
    dnf -y --enablerepo=crb install \
    openssh-server openssh-clients blas procps-ng \
    gcc gcc-gfortran gcc-c++ gdb strace libevent-devel \
    binutils less wget which sudo hwloc-devel munge munge-devel \
    perl perl-devel perl-Data-Dumper patch glibc-langpack-en \
    autoconf automake libtool flex bison python3 \
    iproute net-tools hwloc make cmake git pandoc bind-utils \
    libnl3 gtk2 atk cairo tcl tcsh tk pciutils lsof ethtool bc file \
    psmisc valgrind openssl-devel libfabric glib2-devel gtk2-devel \
    diffutils popt-devel && \
    dnf clean all

RUN mkdir -p /opt/hpc/local/build
COPY build/bin/system/configs/htoprc /root/.config/htop/htoprc
COPY build/bin/system/configs/htoprc /home/mpiuser/.config/htop/htoprc
RUN git config --global --add safe.directory '*'

# -----------------------------
# Allow forced rebuild from this point
# -----------------------------
COPY .build-timestamp /root/

# ------------------------------------------------------------
# Flush but keep the build directory
# - We will mount in the pmix/prrte/ompi source in there
# ------------------------------------------------------------
RUN rm -rf /opt/hpc/local/build && mkdir -p /opt/hpc/local/build

#
# Setup munge security for Slurm
# Currently the PATH is blank, to use the package manager version of it
#
ENV MUNGE_ROOT=""
RUN dd if=/dev/urandom bs=1 count=1024 > ${MUNGE_ROOT}/etc/munge/munge.key
RUN chown root: ${MUNGE_ROOT}/etc/munge/munge.key
RUN chmod 400 ${MUNGE_ROOT}/etc/munge/munge.key
RUN chown root:root /var/log/munge
RUN chown root:root /run/munge
RUN chown root:root /var/lib/munge
RUN chown root:root /etc/munge

# ------------------------------------------------------------
# Fixup the ssh login
# ------------------------------------------------------------
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key  -N "" && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key  -N "" && \
    echo "        LogLevel ERROR" >> /etc/ssh/ssh_config && \
    echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

# ------------------------------------------------------------
# Adjust default ulimit for core files
# ------------------------------------------------------------
RUN echo '*               hard    core            -1' >> /etc/security/limits.conf && \
    echo '*               soft    core            -1' >> /etc/security/limits.conf && \
    echo 'ulimit -c unlimited' >> /root/.bashrc

# ------------------------------------------------------------
# Create a user account to run MPI applications
# ------------------------------------------------------------
RUN groupadd -r mpiuser -g 1000 && useradd --no-log-init -r -m -b /home -g mpiuser -G wheel -u 1000 mpiuser
RUN echo "source /etc/bashrc" > /home/mpiuser/.bashrc
RUN chown mpiuser:mpiuser -R /home/mpiuser
USER mpiuser
RUN  cd /home/mpiuser && \
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa && chmod og+rX . && \
        cd .ssh && cat id_rsa.pub > authorized_keys && chmod 644 authorized_keys && \
        exit

# ------------------------------------------------------------
# Need to enable root ssh without password
# ------------------------------------------------------------
USER root
RUN  cd /root/ && \
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa && chmod og+rX . && \
        cd .ssh && cat id_rsa.pub > authorized_keys && chmod 644 authorized_keys && \
        exit

# ------------------------------------------------------------
# Give the user passwordless sudo powers
# ------------------------------------------------------------
USER root
RUN echo "mpiuser    ALL = NOPASSWD: ALL" >> /etc/sudoers
RUN rm -f /run/nologin

# ------------------------------------------------------------
# Adjust the default environment
# ------------------------------------------------------------
USER root

# Need to do this so that the 'mpiuser' can have them too, not just root
RUN echo "export PMIX_ROOT=/opt/hpc/install/pmix" >> /etc/bashrc && \
    echo "export PRRTE_ROOT=/opt/hpc/install/prrte" >> /etc/bashrc  && \
    echo "export OMPI_ROOT=/opt/hpc/install/ompi" >> /etc/bashrc  && \
    echo "export MPICH_ROOT=/opt/hpc/install/mpich" >> /etc/bashrc  && \
    echo "export PSCOM_ROOT=/opt/hpc/install/pscom" >> /etc/bashrc  && \
    echo "export PSMPI_ROOT=/opt/hpc/install/psmpi" >> /etc/bashrc  && \
    echo "export SLURM_ROOT=/opt/hpc/install/slurm" >> /etc/bashrc  && \
    echo "export GPI2_ROOT=/opt/hpc/install/GPI2" >> /etc/bashrc  && \
    echo "export GSPC_ROOT=/opt/hpc/install/GSPC" >> /etc/bashrc  && \
    echo "export GSPC_HOME=/opt/hpc/install/GSPC" >> /etc/bashrc  && \
    echo "export MRNET_ROOT=/opt/hpc/install/mrnet" >> /etc/bashrc  && \
    echo "export LIBDYNPM_ROOT=/opt/hpc/install/libdynpm" >> /etc/bashrc  && \
    echo "export LIBEVENT_ROOT=/opt/hpc/install/libevent" >> /etc/bashrc  && \
    echo "export PATH=\$OMPI_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$MPICH_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$PSCOM_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$PSMPI_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$SLURM_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$SLURM_ROOT/sbin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$MUNGE_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$MUNGE_ROOT/sbin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$PRRTE_ROOT/bin:\$MPI_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$GPI2_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$GSPC_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$MRNET_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export PATH=\$LIBDYNPM_ROOT/bin:\$PATH" >> /etc/bashrc  && \
    echo "export LD_LIBRARY_PATH=\$LIBEVENT_ROOT/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$PSCOM_ROOT/lib64:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$MPI_ROOT/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$PMIX_ROOT/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$PRRTE_ROOT/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$GPI2_ROOT/lib64:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$GSPC_ROOT/lib64:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$MRNET_ROOT/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=\$LIBDYNPM_ROOT/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export PRRTE_MCA_prrte_default_hostfile=/opt/hpc/install/etc/prrte-hostfile.txt" >> /etc/bashrc && \
    echo "export MUNGE_ROOT=/opt/hpc/local/munge" >> /etc/bashrc && \
    echo "export OMPI_MCA_btl_tcp_if_include=eth0" >> /etc/bashrc && \
    echo "export PKG_CONFIG_PATH=/opt/hpc/install/pmix/lib/pkgconfig/" >> /etc/bashrc && \
    echo "ulimit -c unlimited" >> /etc/bashrc && \
    echo "alias ll='ls -alF'" >> /etc/bashrc && \
    echo "alias la='ls -A'" >> /etc/bashrc && \
    echo "alias l='ls -CF'" >> /etc/bashrc && \
    echo "alias pd=pushd" >> /etc/bashrc

#RUN locale-gen en_US.UTF-8

# ------------------------------------------------------------
# Kick off the ssh daemon
# ------------------------------------------------------------
EXPOSE 22
# Make sure these ports match Slurm defaults or slurm.conf
EXPOSE 7002
EXPOSE 7003
CMD ["/usr/sbin/sshd", "-D"]

