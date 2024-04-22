for run in {1..1}; do sbatch slurm-16p-long-medium.batch; sbatch slurm-24p-short-large.batch; sbatch slurm-32p-short-large.batch; done
for run in {1..2}; do sbatch slurm-8p-fill.batch; done

sbatch slurm-16p-long-medium.batch 
sbatch slurm-24p-short-large.batch 
sbatch slurm-16p-long-medium.batch 
for run in {1..2}; do sbatch slurm-8p-fill.batch; done
