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

name=$(basename $outdir)
scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/scripts

while [[ ${restart} -gt 0 ]]
do
  printf "\nAre you sure you want to restart the pipeline for this run, causing all existing files at ${Y}$outdir${NC} to get deleted?"
  read -p " " yn
  case $yn in
      [Yy]* ) rm -rf $outdir; break;;
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
if [ ! -d $indir ]; then
	show_help "The input directory $indir does not exist at
    $indir${NC}\n"
else
  # R scripts
  for s in "${scriptsR[@]}"
  do
    script=$scripts/${s}.R
    if ! [ -f ${script} ]; then
     show_help "${script} does not exist."
    fi
    mkdir -p $outdir/logs/$s
    mkdir -p $outdir/jobs/$s
  done

  # etc files
  for file in \
		$indir/settings.config \
	  $indir/init.RData
	do
		if ! [ -f ${file} ]; then
			show_help "${file} does not exist.\n"
		fi
	done
fi

mkdir -p $outdir/logs/0-conversion
mkdir -p $outdir/jobs/0-conversion
mkdir -p $outdir/logs/queue
mkdir -p $outdir/jobs/queue

cp $indir/settings.config $outdir/logs
cp $indir/init.RData $outdir/logs
git rev-parse HEAD > $outdir/logs/commit
echo `date +%s` >> $outdir/logs/commit

dos2unix -n $indir/settings.config $indir/settings.config_tmp
mv -f $indir/settings.config_tmp $indir/settings.config
. $indir/settings.config
#thresh2remove=$(printf "%.0f" $thresh2remove) # to convert to decimal from scientific notation

# Clear the environment from any previously loaded modules
#module purge > /dev/null 2>&1


module load R/3.2.2

# 1-queueStart.sh
cat << EOF >> $outdir/jobs/queue/1-queueStart.sh
#!/bin/sh

it=0
find $outdir/data -iname "*.mzXML" | sort | while read mzXML;
 do
     it=\$((it+1))
     input=\$(basename \$mzXML .mzXML)
     if [ \$it == 1 ] && [ ! -f $outdir/breaks.fwhm.RData ] ; then
       echo "Rscript $scripts/1-generateBreaksFwhm.HPC.R \$mzXML $outdir $trim $resol $nrepl $scripts" > $outdir/jobs/1-generateBreaksFwhm.HPC/breaks.sh
       srun --account==dbg_mz --time=5 --mem=1000 --job-name="breaks" --mail-user=$email --output=$outdir/logs/1-generateBreaksFwhm.HPC --error=$outdir/logs/1-generateBreaksFwhm.HPC $outdir/jobs/1-generateBreaksFwhm.HPC/breaks.sh)
     fi

     exit 1
     echo "Rscript $scripts/2-DIMS.R \$mzXML $outdir $trim $dims_thresh $resol $scripts" > $outdir/jobs/2-DIMS/\${input}.sh
     srun --parsable --account==dbg_mz --time=10 --mem=4000 --job-name="dims_\${input}" -hold_jid "breaks" --mail-type=END --mail-user=$email --output=$outdir/logs/2-DIMS --error=$outdir/logs/2-DIMS $outdir/jobs/2-DIMS/\${input}.sh
 done

exit 2
echo "Rscript $scripts/3-averageTechReplicates.R $indir $outdir $nrepl $thresh2remove $dims_thresh $scripts" > $outdir/jobs/3-averageTechReplicates/average.sh
srun --parsable --account==dbg_mz --time=90 --mem=5000 --job-name="average" -hold_jid "dims_*" --mail-type=END --mail-user=$email --output=$outdir/logs/3-averageTechReplicates --error=$outdir/logs/3-averageTechReplicates $outdir/jobs/3-averageTechReplicates/average.sh

sbatch --parsable --account==dbg_mz --time=10 --mem=500 --job-name="queueFinding_positive" -hold_jid "average" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/2-queuePeakFinding --error=$outdir/logs/queue/2-queuePeakFinding $outdir/jobs/queue/2-queuePeakFinding_positive.sh
sbatch --parsable --account==dbg_mz --time=10 --mem=500 --job-name="queueFinding_negative" -hold_jid "average" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/2-queuePeakFinding --error=$outdir/logs/queue/2-queuePeakFinding $outdir/jobs/queue/2-queuePeakFinding_negative.sh
EOF

# 01-queueConversionCheck.sh
cat << EOF >> $outdir/jobs/queue/01-queueConversionCheck.sh
#!/bin/sh

continue=true
if [ "\$1" -lt 1 ]; then
  echo "first check"
  find $indir -iname "*.raw" | sort | while read raw;
  do
    file=\$(basename \$raw .raw)
    if [ ! -f $outdir/data/\${file}.mzXML ]; then
      echo "\${file} doesn't exist"
      continue=false
      sbatch --parsable --account==dbg_mz --time=3 --mem=4000 --job-name="conversion_\${file}" --mail-type=ENDb --mail-user=$email --output=$outdir/logs/0-conversion --error=$outdir/logs/0-conversion $outdir/jobs/0-conversion/\${file}.sh
  	fi
  done

  # check if any of the error files contain 'error in thread'
  for filepath in \$(egrep "(exception)|(0x8007000)" $outdir/logs/0-conversion -r | awk -F ":" '{print \$1}' | uniq)
  do
  	file=\$(basename "\${filepath%.*}" | cut -d '_' -f 1 --complement)
  	if [ -f $outdir/jobs/0-conversion/\${file}.sh ]; then
      echo "error \${file}"
      continue=false
      find $outdir/logs/0-conversion -type f -name "*\${file}*" -delete # otherwise there'll be an endless loop
      sbatch --parsable --account==dbg_mz --time=3 --mem=4000 --job-name="conversion_\${file}" --mail-type=ENDb --mail-user=$email --output=$outdir/logs/0-conversion --error=$outdir/logs/0-conversion $outdir/jobs/0-conversion/\${file}.sh
  	fi
  done

  #check if any of the output files are empty
  for file in \$(ls $outdir/logs/0-conversion -lR | grep "\.o" | awk '{if (\$5 == 0) print \$9}' | cut -d '_' -f 1 --complement | cut -d '.' -f 1)
  do
    if [ -f $outdir/jobs/0-conversion/\${file}.sh ]; then
      echo "output empty \${file}"
      continue=false
      find $outdir/logs/0-conversion -type f -name "*\${file}*" -delete # otherwise there'll be an endless loop
      \$(sbatch --parsable --account==dbg_mz --time=3 --mem=4000 --job-name="conversion_\${file}" --mail-type=ENDb --mail-user=$email --output=$outdir/logs/0-conversion --error=$outdir/logs/0-conversion $outdir/jobs/0-conversion/\${file}.sh)
    fi
  done
else
  echo "Potential RAW -> mzXML conversion issue with run $name" | mail -s "DIMS issue $name" "$email"
fi

if [ "\$continue" = true ]; then
  echo continue
  sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="queueStart" -hold_jid "conversion_*" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/1-queueStart --error=$outdir/logs/queue/1-queueStart $outdir/jobs/queue/1-queueStart.sh
else
  echo redo conversion check
  sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="queueConversionCheck" -hold_jid "conversion_*" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/ --error=$outdir/logs/queue/ $outdir/jobs/queue/01-queueConversionCheck.sh 1
fi

EOF

# 0-queueConversion.sh
find $indir -iname "*.raw" | sort | while read raw;
  do
    input=$(basename $raw .raw)
    echo "singularity exec -B ~/wineprefix64:/wineprefix64,/hpc/dbg_mz $proteowizard.sif wine msconvert $raw --output=$outdir/data --mzXML" > $outdir/jobs/0-conversion/${input}.sh
    srun --account==dbg_mz --time=3 --mem=4000 --job-name="conversion_${input}" --mail-type=FAIL --mail-user=$email --output=$outdir/logs/0-conversion --error=$outdir/logs/0-conversion $outdir/jobs/0-conversion/${input}.sh
  done

exit 3

sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="queueConversionCheck" -hold_jid "conversion_*" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/01-queueConversionCheck --error=$outdir/logs/queue/01-queueConversionCheck $outdir/jobs/queue/01-queueConversionCheck.sh 0



doScanmode() {
  echo "$1"
  scanmode=$1
  thresh=$2
  label=$3
  adducts=$4


  # 2-queuePeakFinding.sh
cat << EOF >> $outdir/jobs/queue/2-queuePeakFinding_${scanmode}.sh
#!/bin/sh

find "$outdir/average_pklist" -iname $label | sort | while read sample;
 do
   input=\$(basename \$sample .RData)
   echo "Rscript $scripts/4-peakFinding.R \$sample $outdir $scanmode $thresh $resol $scripts" > $outdir/jobs/4-peakFinding/${scanmode}_\${input}.sh
   sbatch --parsable --account==dbg_mz --time=60 --mem=8000 --job-name="peakFinding_${scanmode}_\${input}" --mail-type=END --mail-user=$email --output=$outdir/logs/4-peakFinding --error=$outdir/logs/4-peakFinding $outdir/jobs/4-peakFinding/${scanmode}_\${input}.sh
 done

echo "Rscript $scripts/5-collectSamples.R $outdir $scanmode $db" > $outdir/jobs/5-collectSamples/${scanmode}.sh
sbatch --parsable --account==dbg_mz --time=120 --mem=8000 --job-name="collect_$scanmode" -hold_jid "peakFinding_${scanmode}_*" --mail-type=END --mail-user=$email --output=$outdir/logs/5-collectSamples --error=$outdir/logs/5-collectSamples $outdir/jobs/5-collectSamples/${scanmode}.sh

sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="queueGrouping_$scanmode" -hold_jid "collect_$scanmode" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/3-queuePeakGrouping --error=$outdir/logs/queue/3-queuePeakGrouping $outdir/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
EOF

exit 0

  # 3-queuePeakGrouping.sh
cat << EOF >> $outdir/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
#!/bin/sh

find "$outdir/hmdb_part" -iname "${scanmode}_*" | sort | while read hmdb;
 do
   input=\$(basename \$hmdb .RData)
   echo "Rscript $scripts/6-peakGrouping.R \$hmdb $outdir $scanmode $resol $scripts" > $outdir/jobs/6-peakGrouping/${scanmode}_\${input}.sh
   sbatch --parsable --account==dbg_mz --time=120 --mem=8000 --job-name="grouping_${scanmode}_\${input}" --mail-type=END --mail-user=$email --output=$outdir/logs/6-peakGrouping --error=$outdir/logs/6-peakGrouping $outdir/jobs/6-peakGrouping/${scanmode}_\${input}.sh
 done

echo "Rscript $scripts/7-collectSamplesGroupedHMDB.R $outdir $scanmode $scripts" > $outdir/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh
sbatch --parsable --account==dbg_mz --time=60 --mem=8000 --job-name="collect1_$scanmode" -hold_jid "grouping_${scanmode}_*" --mail-type=END --mail-user=$email --output=$outdir/logs/7-collectSamplesGroupedHMDB --error=$outdir/logs/7-collectSamplesGroupedHMDB $outdir/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh

sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/4-queuePeakGroupingRest --error=$outdir/logs/queue/4-queuePeakGroupingRest $outdir/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
EOF

  # 4-queuePeakGroupingRest.sh
cat << EOF >> $outdir/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
#!/bin/sh

find "$outdir/specpks_all_rest" -iname "${scanmode}_*" | sort | while read file;
 do
   input=\$(basename \$file .RData)
   echo "Rscript $scripts/8-peakGrouping.rest.R \$file $outdir $scanmode $resol $scripts" > $outdir/jobs/8-peakGrouping.rest/${scanmode}_\${input}.sh
   sbatch --parsable --account==dbg_mz --time=60 --mem=8000 --job-name="grouping2_${scanmode}_\${input}" --mail-type=END --mail-user=$email --output=$outdir/logs/8-peakGrouping.rest --error=$outdir/logs/8-peakGrouping.rest $outdir/jobs/8-peakGrouping.rest/${scanmode}_\${input}.sh
 done

sbatch --parsable --account==dbg_mz --time=20 --mem=8000 --job-name="queueFillMissing_$scanmode" -hold_jid "grouping2_${scanmode}_*" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/5-queueFillMissing --error=$outdir/logs/queue/5-queueFillMissing $outdir/jobs/queue/5-queueFillMissing_${scanmode}.sh
EOF

  # 5-queueFillMissing.sh
cat << EOF >> $outdir/jobs/queue/5-queueFillMissing_${scanmode}.sh
#!/bin/sh

find "$outdir/grouping_rest" -iname "${scanmode}_*" | sort | while read rdata;
 do
  input=\$(basename \$rdata .RData)
  echo "Rscript $scripts/9-runFillMissing.R \$rdata $outdir $scanmode $thresh $resol $scripts" > $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
  sbatch --parsable --account==dbg_mz --time=120 --mem=8000 --job-name="peakFilling_${scanmode}_\${input}" --mail-type=END --mail-user=$email --output=$outdir/logs/9-runFillMissing --error=$outdir/logs/9-runFillMissing $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
 done

find "$outdir/grouping_hmdb" -iname "*_${scanmode}.RData" | sort | while read rdata2;
 do
  input=\$(basename \$rdata2 .RData)
  echo "Rscript $scripts/9-runFillMissing.R \$rdata2 $outdir $scanmode $thresh $resol $scripts" > $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
  sbatch --parsable --account==dbg_mz --time=120 --mem=8000 --job-name="peakFilling2_${scanmode}_\${input}" -hold_jid "peakFilling_${scanmode}_*" --mail-type=END --mail-user=$email --output=$outdir/logs/9-runFillMissing --error=$outdir/logs/9-runFillMissing $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
 done

echo "Rscript $scripts/10-collectSamplesFilled.R $outdir $scanmode $normalization $scripts $db $z_score" > $outdir/jobs/10-collectSamplesFilled/${scanmode}.sh
sbatch --parsable --account==dbg_mz --time=60 --mem=8000 --job-name="collect2_$scanmode" -hold_jid "peakFilling2_${scanmode}_*" --mail-type=END --mail-user=$email --output=$outdir/logs/10-collectSamplesFilled --error=$outdir/logs/10-collectSamplesFilled $outdir/jobs/10-collectSamplesFilled/${scanmode}.sh

sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" --mail-type=END --mail-user=$email --output=$outdir/logs/queue/6-queueSumAdducts --error=$outdir/logs/queue/6-queueSumAdducts $outdir/jobs/queue/6-queueSumAdducts_${scanmode}.sh
EOF

# 14-cleanup.sh
cat << EOF >> $outdir/jobs/14-cleanup.sh
#!/bin/sh
chmod 777 -R $indir
chmod 777 -R $outdir
EOF

  # 6-queueSumAdducts.sh
cat << EOF >> $outdir/jobs/queue/6-queueSumAdducts_${scanmode}.sh
#!/bin/sh

find "$outdir/hmdb_part_adductSums" -iname "${scanmode}_*" | sort | while read hmdb;
 do
    input=\$(basename \$hmdb .RData)
    echo "Rscript $scripts/11-runSumAdducts.R \$hmdb $outdir $scanmode $adducts $scripts $z_score" > $outdir/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
    sbatch --parsable --account==dbg_mz --time=180 --mem=8000 --job-name="sumAdducts_${scanmode}_\${input}" --mail-type=END --mail-user=$email --output=$outdir/logs/11-runSumAdducts --error=$outdir/logs/11-runSumAdducts $outdir/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
done

echo "Rscript $scripts/12-collectSamplesAdded.R $outdir $scanmode $scripts" > $outdir/jobs/12-collectSamplesAdded/${scanmode}.sh
sbatch --parsable --account==dbg_mz --time=30 --mem=8000 --job-name="collect3_$scanmode" -hold_jid "sumAdducts_${scanmode}_*" --mail-type=END --mail-user=$email --output=$outdir/logs/12-collectSamplesAdded --error=$outdir/logs/12-collectSamplesAdded $outdir/jobs/12-collectSamplesAdded/${scanmode}.sh

if [ -f "$outdir/logs/done" ]; then   # if one of the scanmodes is already queued
  echo other scanmode already queued - queue next step
  echo "module load R/3.5.1 && Rscript $scripts/13-excelExport.R $outdir $name $matrix $db2 $scripts $z_score" > $outdir/jobs/13-excelExport.sh
  sbatch --parsable --account==dbg_mz --time=60 --mem=8000 --job-name="excelExport" -hold_jid "collect3_*" --mail-type=ENDe --mail-user=$email --output=$outdir/logs/13-excelExport --error=$outdir/logs/13-excelExport $outdir/jobs/13-excelExport.sh
  sbatch --parsable --account==dbg_mz --time=10 --mem=1000 --job-name="cleanup" -hold_jid "excelExport" --mail-type=END --mail-user=$email --output=$outdir/logs/14-cleanup --error=$outdir/logs/14-cleanup $outdir/jobs/14-cleanup.sh
else
  echo other scanmode not queued yet
  touch $outdir/logs/done
fi
EOF
}

doScanmode "negative" $thresh_neg "*_neg.RData" "1"
doScanmode "positive" $thresh_pos "*_pos.RData" "1,2"
