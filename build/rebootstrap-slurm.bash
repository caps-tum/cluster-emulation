rm -rf /var/log/slurmctld.log
./bin/rebootstrap-slurm.sh 
tail -f /var/log/slurmctld.log
