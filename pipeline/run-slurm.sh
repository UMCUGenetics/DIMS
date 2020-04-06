#!/bin/sh

set -o pipefail
set -e
#set -x

R='\033[0;31m' # Red
G='\033[0;32m' # Green
Y='\033[0;33m' # Yellow
B='\033[0;34m' # Blue
P='\033[0;35m' # Pink
C='\033[0;36m' # Cyan
NC='\033[0m' # No Color

# Defaults
verbose=0
restart=0
indir=""
outdir=""

# Show usage information
function show_help() {
  if [[ ! -z $1 ]]; then
  printf "
  ${R}ERROR:
    $1${NC}"
  fi
  printf "
  ${P}USAGE:
    ${0} -i <input path> -o <output path> [-r] [-v] [-h]

  ${B}REQUIRED ARGS:
    -i - full path input folder, eg /hpc/dbg_mz/raw_data/run1 (required)
    -o - full path output folder, eg. /hpc/dbg-mz/processed/run1 (required)${NC}

  ${C}OPTIONAL ARGS:
    -r - restart the pipeline, removing any existing output for the entered run (default off)
    -v - verbose printing (default off)
    -h - show help${NC}

  ${G}EXAMPLE:
    sh run.sh -i /hpc/dbg_mz/raw_data/run1 -o /hpc/dbg_mz/processed/run1${NC}

  "
  exit 1
}

while getopts "h?vrqi:o:" opt
do
	case "${opt}" in
	h|\?)
		show_help
		exit 0
		;;
	v) verbose=1 ;;
  r) restart=1 ;;
  i) indir=${OPTARG} ;;
  o) outdir=${OPTARG} ;;

	esac
done

shift "$((OPTIND-1))"

if [ -z ${indir} ] ; then show_help "Required arguments were not given.\n" ; fi
if [ -z ${outdir} ] ; then show_help "Required arguments were not given.\n" ; fi
if [ ${verbose} -gt 0 ] ; then set -x ; fi

name=$(basename ${outdir})
scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/scripts

while [[ ${restart} -gt 0 ]]
do
  printf "\nAre you sure you want to restart the pipeline for this run, causing all existing files at ${Y}${outdir}${NC} to get deleted?"
  read -p " " yn
  case $yn in
      [Yy]* ) rm -rf ${outdir}; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
  esac
done

declare -a scriptsR=("1-generateBreaksFwhm.HPC" \
                     "2-DIMS" \
                     "3-averageTechReplicates" \
                     "4-peakFinding" \
                     "5-collectSamples" \
                     "6-peakGrouping" \
                     "7-collectSamplesGroupedHMDB" \
                     "8-peakGrouping.rest" \
                     "9-runFillMissing" \
                     "10-collectSamplesFilled" \
                     "11-runSumAdducts" \
                     "12-collectSamplesAdded" \
                     "13-excelExport" )


# Check existence input dir
if [ ! -d ${indir} ]; then
	show_help "The input directory ${indir} does not exist at
    ${indir}${NC}\n"
else
  # R scripts
  for s in "${scriptsR[@]}"
  do
    script=${scripts}/${s}.R
    if ! [ -f ${script} ]; then
     show_help "${script} does not exist."
    fi
    mkdir -p ${outdir}/logs/$s
    mkdir -p ${outdir}/jobs/$s
  done

  # etc files
  for file in \
		${indir}/settings.config \
	  ${indir}/init.RData
	do
		if ! [ -f ${file} ]; then
			show_help "${file} does not exist.\n"
		fi
	done
fi

mkdir -p ${outdir}/logs/0-conversion
mkdir -p ${outdir}/jobs/0-conversion
mkdir -p ${outdir}/logs/queue
mkdir -p ${outdir}/jobs/queue
mkdir -p ${outdir}/data

cp ${indir}/settings.config ${outdir}/logs
cp ${indir}/init.RData ${outdir}/logs
git rev-parse HEAD > ${outdir}/logs/commit
echo `date +%s` >> ${outdir}/logs/commit

dos2unix -n ${indir}/settings.config ${indir}/settings.config_tmp
mv -f ${indir}/settings.config_tmp ${indir}/settings.config
. ${indir}/settings.config
#thresh2remove=$(printf "%.0f" ${thresh}2remove) # to convert to decimal from scientific notation

# Clear the environment from any previously loaded modules
#module purge > /dev/null 2>&1

module load R/3.2.2

# 0-queueConversion.sh
cat << EOF >> ${outdir}/jobs/queue/0-queueConversion.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""
for raw in ${indir}/*.raw ; do
  input=\$(basename \$raw .raw)
  echo "#!/bin/sh
  source /hpc/dbg_mz/tools/mono/etc/profile
  mono /hpc/dbg_mz/tools/ThermoRawFileParser_1.1.11/ThermoRawFileParser.exe -i=\${raw} --output=${outdir}/data -p
  " > ${outdir}/jobs/0-conversion/\${input}.sh
  cur_id=\$(sbatch --parsable --time=00:05:00 --mem=2G --output=${outdir}/logs/0-conversion/\${input}.o --error=${outdir}/logs/0-conversion/\${input}.e ${outdir}/jobs/0-conversion/\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1}
echo \${job_ids}

sbatch --time=00:05:00 --mem=1G --dependency=afterok:\${job_ids} --output=${outdir}/logs/queue/1-queueStart.o --error=${outdir}/logs/queue/1-queueStart.e ${outdir}/jobs/queue/1-queueStart.sh
EOF

# 1-queueStart.sh
cat << EOF >> ${outdir}/jobs/queue/1-queueStart.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""

for mzML in ${outdir}/data/*.mzML ; do
  input=\$(basename \$mzML .mzML)
  if [ ! -v break_id ] ; then
    # 1-generateBreaksFwhm.HPC.R
    echo "#!/bin/sh
    Rscript ${scripts}/1-generateBreaksFwhm.HPC.R \$mzML ${outdir} ${trim} ${resol} ${nrepl} ${scripts}
    " > ${outdir}/jobs/1-generateBreaksFwhm.HPC/breaks.sh
    break_id=\$(sbatch --parsable --time=00:05:00 --mem=2G --output=${outdir}/logs/1-generateBreaksFwhm.HPC/breaks.o --error=${outdir}/logs/1-generateBreaksFwhm.HPC/breaks.e ${outdir}/jobs/1-generateBreaksFwhm.HPC/breaks.sh)
  fi

  # 2-DIMS.R
  echo "#!/bin/sh
  /hpc/local/CentOS7/dbg_mz/R_libs/3.6.2/bin/Rscript ${scripts}/2-DIMS.R \$mzML ${outdir} ${trim} ${dims_thresh} ${resol} ${scripts}
  " > ${outdir}/jobs/2-DIMS/\${input}.sh
  cur_id=\$(sbatch --parsable --time=00:10:00 --mem=4G --dependency=afterok:\${break_id} --output=${outdir}/logs/2-DIMS/\${input}.o --error=${outdir}/logs/2-DIMS/\${input}.e ${outdir}/jobs/2-DIMS/\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1} # remove last :

# 3-averageTechReplicates.R
echo "#!/bin/sh
Rscript ${scripts}/3-averageTechReplicates.R ${indir} ${outdir} ${nrepl} ${thresh2remove} ${dims_thresh} ${scripts}
" > ${outdir}/jobs/3-averageTechReplicates/average.sh
avg_id=\$(sbatch --parsable --time=01:30:00 --mem=5G --dependency=afterok:\${job_ids} --output=${outdir}/logs/3-averageTechReplicates/average.o --error=${outdir}/logs/3-averageTechReplicates/average.e ${outdir}/jobs/3-averageTechReplicates/average.sh)

# start next queue
sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterok:\${avg_id} --output=${outdir}/logs/queue/2-queuePeakFinding_positive.o --error=${outdir}/logs/queue/2-queuePeakFinding_positive.o ${outdir}/jobs/queue/2-queuePeakFinding_positive.sh
sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterok:\${avg_id} --output=${outdir}/logs/queue/2-queuePeakFinding_negative.e --error=${outdir}/logs/queue/2-queuePeakFinding_negative.e ${outdir}/jobs/queue/2-queuePeakFinding_negative.sh
EOF

# 14-cleanup.sh
cat << EOF >> ${outdir}/jobs/14-cleanup.sh
#!/bin/sh
chmod 777 -R ${indir}
chmod 777 -R ${outdir}

echo "$outdir" | mail -s "DIMS run $name - FINISHED" $email
EOF

doScanmode() {
  echo "$1"
  scanmode=$1
  thresh=$2
  label=$3
  adducts=$4


  # 2-queuePeakFinding.sh
cat << EOF >> ${outdir}/jobs/queue/2-queuePeakFinding_${scanmode}.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""
for sample in ${outdir}/average_pklist/*${label}* ; do
  input=\$(basename \$sample .RData)

  # 4-peakFinding.R
  echo "#!/bin/sh
  Rscript ${scripts}/4-peakFinding.R \${sample} ${outdir} ${scanmode} ${thresh} ${resol} ${scripts}
  " > ${outdir}/jobs/4-peakFinding/${scanmode}_\${input}.sh
  cur_id=\$(sbatch --parsable --time=01:00:00 --mem=8G --output=${outdir}/logs/4-peakFinding/${scanmode}_\${input}.o --error=${outdir}/logs/4-peakFinding/${scanmode}_\${input}.e ${outdir}/jobs/4-peakFinding/${scanmode}_\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1}

# 5-collectSamples.R
echo "#!/bin/sh
Rscript ${scripts}/5-collectSamples.R ${outdir} ${scanmode} ${db}
" > ${outdir}/jobs/5-collectSamples/${scanmode}.sh
col_id=\$(sbatch --parsable --time=02:00:00 --mem=8G --dependency=afterany:\${job_ids} --output=${outdir}/logs/5-collectSamples/${scanmode}.o --error=${outdir}/logs/5-collectSamples/${scanmode}.e ${outdir}/jobs/5-collectSamples/${scanmode}.sh)

# start next queue
sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterany:\${col_id} --output=${outdir}/logs/queue/3-queuePeakGrouping_${scanmode}.o --error=${outdir}/logs/queue/3-queuePeakGrouping_${scanmode}.e ${outdir}/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
EOF

  # 3-queuePeakGrouping.sh
cat << EOF >> ${outdir}/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""
for hmdb in ${outdir}/hmdb_part/${scanmode}_* ; do
  input=\$(basename \$hmdb .RData)

  # 6-peakGrouping
  echo "#!/bin/sh
  Rscript ${scripts}/6-peakGrouping.R \$hmdb ${outdir} ${scanmode} ${resol} ${scripts}
  " > ${outdir}/jobs/6-peakGrouping/${scanmode}_\${input}.sh
  cur_id=\$(sbatch --parsable --time=02:00:00 --mem=8G --output=${outdir}/logs/6-peakGrouping/${scanmode}_\${input}.o --error=${outdir}/logs/6-peakGrouping/${scanmode}_\${input}.e ${outdir}/jobs/6-peakGrouping/${scanmode}_\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1}

# 7-collectSamplesGroupedHMDB
echo "#!/bin/sh
Rscript ${scripts}/7-collectSamplesGroupedHMDB.R ${outdir} ${scanmode} ${scripts}
" > ${outdir}/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh
col_id=\$(sbatch --parsable --time=01:00:00 --mem=8G --dependency=afterany:\${job_ids} --output=${outdir}/logs/7-collectSamplesGroupedHMDB/${scanmode}.o --error=${outdir}/logs/7-collectSamplesGroupedHMDB/${scanmode}.e ${outdir}/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh)

# start next queue
sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterany:\${col_id} --output=${outdir}/logs/queue/4-queuePeakGroupingRest_${scanmode}.o --error=${outdir}/logs/queue/4-queuePeakGroupingRest_${scanmode}.e ${outdir}/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
EOF

  # 4-queuePeakGroupingRest.sh
cat << EOF >> ${outdir}/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""
for file in ${outdir}/specpks_all_rest/${scanmode}_* ; do
  input=\$(basename \$file .RData)

  # 8-peakGrouping.rest
  echo "#!/bin/sh
  Rscript ${scripts}/8-peakGrouping.rest.R \$file ${outdir} ${scanmode} ${resol} ${scripts}
  " > ${outdir}/jobs/8-peakGrouping.rest/${scanmode}_\${input}.sh
  cur_id=\$(sbatch --parsable --time=01:00:00 --mem=8G --output=${outdir}/logs/8-peakGrouping.rest/${scanmode}_\${input}.o --error=${outdir}/logs/8-peakGrouping.rest/${scanmode}_\${input}.e ${outdir}/jobs/8-peakGrouping.rest/${scanmode}_\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1}

# start next queue
sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterany:\${job_ids} --output=${outdir}/logs/queue/5-queueFillMissing_${scanmode}.o --error=${outdir}/logs/queue/5-queueFillMissing_${scanmode}.e ${outdir}/jobs/queue/5-queueFillMissing_${scanmode}.sh
EOF

  # 5-queueFillMissing.sh
cat << EOF >> ${outdir}/jobs/queue/5-queueFillMissing_${scanmode}.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""
for file in ${outdir}/grouping_rest/${scanmode}_* ; do
  input=\$(basename \$file .RData)

  # 9-runFillMissing.R part 1
  echo "#!/bin/sh
  Rscript ${scripts}/9-runFillMissing.R \$file ${outdir} ${scanmode} ${thresh} ${resol} ${scripts}
  " > ${outdir}/jobs/9-runFillMissing/rest_${scanmode}_\${input}.sh
  cur_id=\$(sbatch --parsable --time=02:00:00 --mem=8G --output=${outdir}/logs/9-runFillMissing/rest_${scanmode}_\${input}.o --error=${outdir}/logs/9-runFillMissing/rest_${scanmode}_\${input}.e ${outdir}/jobs/9-runFillMissing/rest_${scanmode}_\${input}.sh)
  job_ids+="\${cur_id}:"
done

for file in ${outdir}/grouping_hmdb/*_${scanmode}.RData ; do
  input=\$(basename \$file .RData)

  # 9-runFillMissing.R part 2
  echo "#!/bin/sh
  Rscript ${scripts}/9-runFillMissing.R \$file ${outdir} ${scanmode} ${thresh} ${resol} ${scripts}
  " > ${outdir}/jobs/9-runFillMissing/hmdb_${scanmode}_\${input}.sh
  cut_id=\$(sbatch --parsable --time=02:00:00 --mem=8G --output=${outdir}/logs/9-runFillMissing/hmdb_${scanmode}_\${input}.o --error=${outdir}/logs/9-runFillMissing/hmdb_${scanmode}_\${input}.e ${outdir}/jobs/9-runFillMissing/hmdb_${scanmode}_\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1}

# 10-collectSamplesFilled
echo "#!/bin/sh
Rscript ${scripts}/10-collectSamplesFilled.R ${outdir} ${scanmode} $normalization ${scripts} ${db} ${z_score}
" > ${outdir}/jobs/10-collectSamplesFilled/${scanmode}.sh
col_id=\$(sbatch --parsable --time=01:00:00 --mem=8G --dependency=afterany:\${job_ids} --output=${outdir}/logs/10-collectSamplesFilled/${scanmode}.o --error=${outdir}/logs/10-collectSamplesFilled/${scanmode}.e ${outdir}/jobs/10-collectSamplesFilled/${scanmode}.sh)

# start next queue
sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterany:\${col_id} --output=${outdir}/logs/queue/6-queueSumAdducts_${scanmode}.o --error=${outdir}/logs/queue/6-queueSumAdducts_${scanmode}.e ${outdir}/jobs/queue/6-queueSumAdducts_${scanmode}.sh
EOF

  # 6-queueSumAdducts.sh
cat << EOF >> ${outdir}/jobs/queue/6-queueSumAdducts_${scanmode}.sh
#!/bin/sh
#SBATCH --mail-user=${email}, --mail-type=TIME_LIMIT_80,FAIL

job_ids=""
for hmdb in ${outdir}/hmdb_part_adductSums/${scanmode}_* ; do
  input=\$(basename \$hmdb .RData)

  # 11-runSumAdducts
  echo "#!/bin/sh
  Rscript ${scripts}/11-runSumAdducts.R \$hmdb ${outdir} ${scanmode} $adducts ${scripts} $z_score
  " > ${outdir}/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
  cur_id=\$(sbatch --parsable --time=03:00:00 --mem=8G --output=${outdir}/logs/11-runSumAdducts/${scanmode}_\${input}.o --error=${outdir}/logs/11-runSumAdducts/${scanmode}_\${input}.e ${outdir}/jobs/11-runSumAdducts/${scanmode}_\${input}.sh)
  job_ids+="\${cur_id}:"
done
job_ids=\${job_ids::-1}

# 12-collectSamplesAdded
echo "#!/bin/sh
Rscript ${scripts}/12-collectSamplesAdded.R ${outdir} ${scanmode} ${scripts}
" > ${outdir}/jobs/12-collectSamplesAdded/${scanmode}.sh
col_id=\$(sbatch --parsable --time=00:30:00 --mem=8G --dependency=afterany:\${job_ids} --output=${outdir}/logs/12-collectSamplesAdded/${scanmode}.o --error=${outdir}/logs/12-collectSamplesAdded/${scanmode}.e ${outdir}/jobs/12-collectSamplesAdded/${scanmode}.sh)

if [ -f "${outdir}/logs/done" ]; then   # if one of the scanmodes has already finished
  echo other scanmode already finished - queue next step

  # 13-excelExport
  echo "#!/bin/sh
  /hpc/local/CentOS7/dbg_mz/R_libs/3.6.2/bin/Rscript ${scripts}/13-excelExport.R ${outdir} ${name} ${matrix} ${db2} ${scripts} ${z_score}
  " > ${outdir}/jobs/13-excelExport.sh
  exp_id=\$(sbatch --parsable --time=01:00:00 --mem=8G --dependency=afterany:\${col_id} --output=${outdir}/logs/13-excelExport/exp.o --error=${outdir}/logs/13-excelExport/exp.e ${outdir}/jobs/13-excelExport.sh)
  sbatch --parsable --time=00:05:00 --mem=500M --dependency=afterany:\${exp_id} --output=${outdir}/logs/14-cleanup.o --error=${outdir}/logs/14-cleanup.e ${outdir}/jobs/14-cleanup.sh
else
  echo other scanmode not finished yet
  touch ${outdir}/logs/done
fi
EOF
}

doScanmode "negative" ${thresh_neg} "*_neg.RData" "1"
doScanmode "positive" ${thresh_pos} "*_pos.RData" "1,2"

sbatch --time=00:05:00 --mem=1G --output=${outdir}/logs/queue/0-queueConversion.o --error=${outdir}/logs/queue/0-queueConversion.e --mail-user=${email} --mail-type=TIME_LIMIT_80,FAIL ${outdir}/jobs/queue/0-queueConversion.sh
