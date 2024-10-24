#!/bin/bash
set -euo pipefail

workflow_path='/hpc/dbg_mz/production/DIMS'

# Set input and output dirs
input=$1
output=$2
email=$3
samplesheet=$4
nr_replicates=$5
resolution=$6
ppm=$7
zscore=$8
matrix=$9
standard_run=${10}
optional_params=( "${@:11}" )

echo "input directory: $input"
echo "output directory: $output"
echo "workflow path: $workflow_path"
echo "matrix: $matrix"
echo "standard run: $standard_run"
mkdir -p $output 
cd $output
mkdir -p log
mkdir -p Bioinformatics

if ! { [ -f 'workflow.running' ] || [ -f 'workflow.done' ] || [ -f 'workflow.failed' ]; }; then
touch workflow.running
sbatch <<EOT
#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --mem 5G
#SBATCH --job-name Nextflow_DIMS
#SBATCH -o log/slurm_nextflow_dims.%j.out
#SBATCH -e log/slurm_nextflow_dims.%j.err
#SBATCH --mail-user $email
#SBATCH --mail-type FAIL
#SBATCH --export=NONE
#SBATCH --gres=tmpspace:5G

git --git-dir=$workflow_path/.git rev-parse HEAD > ${output}/log/commit
echo `date +%s` >> ${output}/logs/commit

NXF_JAVA_HOME='/hpc/dbg_mz/tools/jdk-20.0.2' /hpc/dbg_mz/tools/nextflow run $workflow_path/DIMS.nf \
-c $workflow_path/DIMS.config \
--rawfiles_path $input \
--outdir $output \
--email $email \
--samplesheet $input/$samplesheet \
--nr_replicates $nr_replicates \
--resolution $resolution \
--ppm $ppm \
--zscore $zscore \
--matrix $matrix \
--standard_run $standard_run \
-profile slurm \
-resume -ansi-log false \
${optional_params[@]:-""}

if [ \$? -eq 0 ]; then
    echo "Nextflow done."

    #echo "Remove work directory"
    #rm -r work

    rm workflow.running
    touch workflow.done

    echo "Change permissions"
    chmod 775 -R $output

    exit 0
else
    echo "Nextflow failed"
    rm workflow.running
    touch workflow.failed

    echo "Change permissions"
    chmod 775 -R $output

    exit 1
fi
EOT
else
echo "Workflow job not submitted, please check $output for 'workflow.status' files."
fi
