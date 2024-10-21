#!/bin/bash
set -eo pipefail

workflow_path='/hpc/dbg_mz/development/DIMS_HMDB_V5'

R='\033[0;31m' # Red
G='\033[0;32m' # Green
Y='\033[0;33m' # Yellow
B='\033[0;34m' # Blue
P='\033[0;35m' # Pink
C='\033[0;36m' # Cyan
NC='\033[0m' # No Color

# Set input and output dirs
input=""
output=""
email=""
samplesheet=""
nr_replicates=""
resolution=""
ppm=""
zscore=""
matrix=""
standard_run=""
optional_params=( "${@:21}" )

# Show usage information
function show_help() {
  if [[ ! -z $1 ]]; then
  printf "
  ${R}ERROR:
    $1${NC}"
  fi
  printf "
  ${P}USAGE:
    ${0} -i <input path> -o <output path> -e <email> -s <samplesheet> -n <nr_replicates> -r <resolution> -p <ppm> -z <zscore> -m <matrix> -t <standard_run> [-v] [-h]

  ${B}REQUIRED ARGS:
    -i - full path input folder, eg /hpc/dbg_mz/raw_data/run1 (required)
    -o - full path output folder, eg. /hpc/dbg_mz/processed/run1 (required)
    -e - emailadress, eg. user@umcutrecht.nl (required)
    -s - samplesheet, eg. sampleNames.txt (required)
    -n - number of replicates, eg. 2 (required)
    -r - resolution, eg. 140000 (required)
    -p - ppm, eg. 5 (required)
    -z - zscore, 1 for Z-score and 0 for no Z-score (required)
    -m - matrix, eg. Plasma (required)
    -t - standard run, yes or no (required)${NC}

  ${C}OPTIONAL ARGS:
    -v - verbose printing (default off)
    -h - show help${NC}

  ${G}EXAMPLE:
    sh run.sh -i /hpc/dbg_mz/raw_data/run1 -o /hpc/dbg_mz/processed/run1$ -e user@umcutrecht.nl -s sampleNames.txt -n 2 -r 140000 -p 5 -z 1 -m Plasma -t yes${NC}

  "
  exit 1
}

while getopts "h?v:i:o:e:s:n:r:p:z:m:t:" opt
do
  case "${opt}" in
  h|\?)
    show_help
    exit 0
    ;;
  v) verbose=1 ;;
  i) input=${OPTARG} ;;
  o) output=${OPTARG} ;;
  e) email=${OPTARG} ;;
  s) samplesheet=${OPTARG} ;;
  n) nr_replicates=${OPTARG} ;;
  r) resolution=${OPTARG} ;;
  p) ppm=${OPTARG} ;;
  z) zscore=${OPTARG} ;;
  m) matrix=${OPTARG} ;;
  t) standard_run=${OPTARG} ;;

  esac
done

shift "$((OPTIND-1))"

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

output_log="${output}/log"
file="${output_log}/nextflow_trace.txt"
# Check if nextflow_trace.txt exists
if [ -e "${file}" ]; then
    current_suffix=0
    # Get a list of all trace files WITH a suffix
    trace_file_list=$(ls "${output_log}"/nextflow_trace*.txt 2> /dev/null)
    # Check if any trace files with a suffix exist
    if [ "$?" -eq 0 ]; then
        # Check for each trace file with a suffix if the suffix is the highest and save that one as the current suffix
        for trace_file in ${trace_file_list}; do
            basename_trace_file=$(basename "${trace_file}")
            if echo "${basename_trace_file}" | grep -qE '[0-9]+'; then
                suffix=$(echo "${basename_trace_file}" | grep -oE '[0-9]+')
            else
                suffix=0
            fi

            if [ "${suffix}" -gt "${current_suffix}" ]; then
                current_suffix=${suffix}
            fi
        done
    fi
    # Increment the suffix
    new_suffix=$((current_suffix + 1))
    # Create the new file name with the incremented suffix
    new_file="${file%.*}_$new_suffix.${file##*.}"
    # Rename the file
    mv "${file}" "${new_file}"
fi

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
echo `date +%s` >> ${output}/log/commit

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

    echo "Copy log directory"
    cp log/* Bioinformatics/log/

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
