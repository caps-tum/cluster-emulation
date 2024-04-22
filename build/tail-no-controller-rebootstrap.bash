rm -rf /var/log/slurmctld.log
./bin/rebootstrap-no-controller.sh
slurmctld -D
