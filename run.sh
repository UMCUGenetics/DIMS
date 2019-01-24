#!/bin/bash

# todo :
# getting the same output as before;
# mailing;
# something that checks which steps have already been done when starting pipeline
# figure out .Rprofile to never have to load libraries or point to where they are


start=`date +%s`

set -o pipefail
set -e
set -x

R='\033[0;31m' # Red
G='\033[0;32m' # Green
Y='\033[0;33m' # Yellow
B='\033[0;34m' # Blue
P='\033[0;35m' # Pink
C='\033[0;36m' # Cyan
NC='\033[0m' # No Color

# Defaults
VERBOSE=0
RESTART=0
NAME=""
MAIL=""

# Show usage information
function show_help() {
  if [[ ! -z $1 ]]; then
  printf "
  ${R}ERROR:
    $1${NC}"
  fi
  printf "
  ${P}USAGE:
    ${0} -n <run dir> -m <email> [-r] [-v] [-h]

  ${B}REQUIRED ARGS:
    -n - name of input folder, eg run1 (required)
    -m - email address to send failing jobs to${NC}

  ${C}OPTIONAL ARGS:
    -r - restart the pipeline, removing any existing output for the entered run (default off)
    -v - verbose logging (default off)
    -h - show help${NC}

  ${G}EXAMPLE:
    sh run.sh -n run1 -m boop@umcutrecht.nl${NC}

  "
  exit 1
}

while getopts "h?vrqn:m:" opt
do
	case "${opt}" in
	h|\?)
		show_help
		exit 0
		;;
	v) VERBOSE=1 ;;
  r) RESTART=1 ;;
  n) NAME=${OPTARG} ;;
	m) MAIL=${OPTARG} ;;
	esac
done

shift "$((OPTIND-1))"

if [ -z ${NAME} ] ; then show_help "Required arguments were not given.\n" ; fi
if [ ${VERBOSE} -gt 0 ] ; then set -x ; fi

BASE=/hpc/dbg_mz
#BASE=/Users/nunen/Documents/GitHub/Dx_metabolomics
INDIR=$BASE/raw_data/${NAME}
OUTDIR=$BASE/processed/${NAME}
SCRIPTS=$PWD/scripts
LOGDIR=$PWD/logs/${NAME} #/output
#ERRORS=$PWD/tmp/${NAME}/errors

while [[ ${RESTART} -gt 0 ]]
do
  printf "\nAre you sure you want to restart the pipeline for this run, causing all existing files at ${Y}$OUTDIR${NC} to get deleted?"
  read -p " " yn
  case $yn in
      [Yy]* ) rm -rf $OUTDIR; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
  esac
done
declare -a scriptsSH=("1-queueStart" \
                      "2-queuePeakFinding" \
                      "3-queuePeakGrouping" \
                      "4-queuePeakGroupingRest" \
                      "5-queueFillMissing" \
                      "6-queueSumAdducts" )

declare -a scriptsR=("1-generateBreaksFwhm.HPC" \
                     "2-DIMS" \
                     "3-averageTechReplicates" \
                     "4-peakFinding.2.0" \
                     "5-collectSamples" \
                     "6-peakGrouping.2.0" \
                     "7-collectSamplesGroupedHMDB" \
                     "8-peakGrouping.2.0.rest" \
                     "9-runFillMissing" \
                     "10-collectSamplesFilled" \
                     "11-runSumAdducts" \
                     "12-collectSamplesAdded" )


# Check existence input dir
if [ ! -d $INDIR ]; then
	show_help "The input directory for run $NAME does not exist at
    $INDIR${NC}\n"
else
  # bash queueing scripts
  for s in "${scriptsSH[@]}"
  do
    script=$SCRIPTS/${s}.sh
    if ! [ -f ${script} ]; then
     show_help "${script} does not exist."
    fi
  done

  # R scripts
  for s in "${scriptsR[@]}"
  do
    script=$SCRIPTS/R/${s}.R
    if ! [ -f ${script} ]; then
     show_help "${script} does not exist."
    fi
    mkdir -p $OUTDIR/logs/$s
    mkdir -p $OUTDIR/jobs/$s
  done

  # etc files
  for file in \
		$INDIR/settings.config \
	  $INDIR/init.RData \
	  $PWD/db/HMDB_add_iso_corrNaCl_only_IS.RData \
    $PWD/db/HMDB_add_iso_corrNaCl_with_IS.RData \
    $PWD/db/HMDB_add_iso_corrNaCl.RData \
    $PWD/db/HMDB_with_info_relevance.RData \
    $PWD/db/TheoreticalMZ_NegPos_incNaCl.txt
	do
		if ! [ -f ${file} ]; then
			show_help "${file} does not exist."
		fi
	done
fi


mkdir -p $OUTDIR/logs/queue
mkdir -p $OUTDIR/jobs/queue

cp $INDIR/settings.config $OUTDIR/logs
cp $INDIR/init.RData $OUTDIR/logs
git rev-parse HEAD > $OUTDIR/logs/commit


. $INDIR/settings.config

# 1-queueStart.sh

it=0
find $INDIR -iname "*.mzXML" | sort | while read mzXML;
 do
     it=$((it+1))
     input=$(basename $mzXML .mzXML)
     if [ $it == 1 ] && [ ! -f $OUTDIR/breaks.fwhm.RData ] ; then # || [[ $it == 2 ]]
       echo "Rscript $SCRIPTS/R/1-generateBreaksFwhm.HPC.R $mzXML $OUTDIR $trim $resol $nrepl $SCRIPTS/R" > $OUTDIR/jobs/1-generateBreaksFwhm.HPC/breaks.sh
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -m as -M $MAIL -o $OUTDIR/logs/1-generateBreaksFwhm.HPC -e $OUTDIR/logs/1-generateBreaksFwhm.HPC $OUTDIR/jobs/1-generateBreaksFwhm.HPC/breaks.sh
     fi

     echo "Rscript $SCRIPTS/R/2-DIMS.R $mzXML $OUTDIR $trim $dimsThresh $resol $SCRIPTS/R" > $OUTDIR/jobs/2-DIMS/${input}.sh
     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims_${input}" -hold_jid "breaks" -m as -M $MAIL -o $OUTDIR/logs/2-DIMS -e $OUTDIR/logs/2-DIMS $OUTDIR/jobs/2-DIMS/${input}.sh
 done

echo "Rscript $SCRIPTS/R/3-averageTechReplicates.R $INDIR $OUTDIR $nrepl $thresh2remove $dimsThresh $SCRIPTS/R" > $OUTDIR/jobs/3-averageTechReplicates/average.sh
qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -hold_jid "dims_*" -m as -M $MAIL -o $OUTDIR/logs/3-averageTechReplicates -e $OUTDIR/logs/3-averageTechReplicates $OUTDIR/jobs/3-averageTechReplicates/average.sh

#exit 0


doScanmode() {
  scanmode=$1
  thresh=$2
  label=$3
  adducts=$4


  # 2-queuePeakFinding.sh
cat << EOF >> $OUTDIR/jobs/queue/2-queuePeakFinding_${scanmode}.sh
#!/bin/bash

find "$OUTDIR/average_pklist" -iname $label | sort | while read sample;
 do
   input=\$(basename \$sample .RData)
   echo "Rscript $SCRIPTS/R/4-peakFinding.2.0.R \$sample $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/4-peakFinding.2.0/${scanmode}_\${input}.sh
   qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_${scanmode}_\${input}" -m as -M $MAIL -o $OUTDIR/logs/4-peakFinding.2.0 -e $OUTDIR/logs/4-peakFinding.2.0 $OUTDIR/jobs/4-peakFinding.2.0/${scanmode}_\${input}.sh
 done

echo "Rscript $SCRIPTS/R/5-collectSamples.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/5-collectSamples/${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/5-collectSamples -e $OUTDIR/logs/5-collectSamples $OUTDIR/jobs/5-collectSamples/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGrouping_$scanmode" -hold_jid "collect_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/queue/3-queuePeakGrouping -e $OUTDIR/logs/queue/3-queuePeakGrouping $OUTDIR/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
EOF


  # 3-queuePeakGrouping.sh
cat << EOF >> $OUTDIR/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
#!/bin/bash

find "$OUTDIR/hmdb_part" -iname "${scanmode}_*" | sort | while read hmdb;
 do
   input=\$(basename \$hmdb .RData)
   echo "Rscript $SCRIPTS/R/6-peakGrouping.2.0.R \$hmdb $OUTDIR $scanmode $resol $SCRIPTS/R" > $OUTDIR/jobs/6-peakGrouping.2.0/${scanmode}_\${input}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_${scanmode}_\${input}" -m as -M $MAIL -o $OUTDIR/logs/6-peakGrouping.2.0 -e $OUTDIR/logs/6-peakGrouping.2.0 $OUTDIR/jobs/6-peakGrouping.2.0/${scanmode}_\${input}.sh
 done

echo "Rscript $SCRIPTS/R/7-collectSamplesGroupedHMDB.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/7-collectSamplesGroupedHMDB -e $OUTDIR/logs/7-collectSamplesGroupedHMDB $OUTDIR/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/queue/4-queuePeakGroupingRest -e $OUTDIR/logs/queue/4-queuePeakGroupingRest $OUTDIR/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
EOF

  # 4-queuePeakGroupingRest.sh
cat << EOF >> $OUTDIR/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
#!/bin/bash

find "$OUTDIR/specpks_all_rest" -iname "${scanmode}_*" | sort | while read file;
 do
   input=\$(basename \$file .RData)
   echo "Rscript $SCRIPTS/R/8-peakGrouping.2.0.rest.R \$file $OUTDIR $scanmode $resol $SCRIPTS/R" > $OUTDIR/jobs/8-peakGrouping.2.0.rest/${scanmode}_\${input}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_${scanmode}_\${input}" -m as -M $MAIL -o $OUTDIR/logs/8-peakGrouping.2.0.rest -e $OUTDIR/logs/8-peakGrouping.2.0.rest $OUTDIR/jobs/8-peakGrouping.2.0.rest/${scanmode}_\${input}.sh
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "queueFillMissing_$scanmode" -hold_jid "grouping2_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/queue/5-queueFillMissing -e $OUTDIR/logs/queue/5-queueFillMissing $OUTDIR/jobs/queue/5-queueFillMissing_${scanmode}.sh
EOF

  # 5-queueFillMissing.sh
cat << EOF >> $OUTDIR/jobs/queue/5-queueFillMissing_${scanmode}.sh
#!/bin/bash

find "$OUTDIR/grouping_rest" -iname "${scanmode}_*" | sort | while read rdata;
 do
  input=\$(basename \$rdata .RData)
  echo "Rscript $SCRIPTS/R/9-runFillMissing.R \$rdata $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/9-runFillMissing/${scanmode}_\${input}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_${scanmode}_\${input}" -m as -M $MAIL -o $OUTDIR/logs/9-runFillMissing -e $OUTDIR/logs/9-runFillMissing $OUTDIR/jobs/9-runFillMissing/${scanmode}_\${input}.sh
 done

find "$OUTDIR/grouping_hmdb" -iname "*_${scanmode}.RData" | sort | while read rdata2;
 do
  input=\$(basename \$rdata2 .RData)
  echo "Rscript $SCRIPTS/R/9-runFillMissing.R \$rdata2 $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/9-runFillMissing/${scanmode}_\${input}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_${scanmode}_\${input}" -hold_jid "peakFilling_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/9-runFillMissing -e $OUTDIR/logs/9-runFillMissing $OUTDIR/jobs/9-runFillMissing/${scanmode}_\${input}.sh
 done

echo "Rscript $SCRIPTS/R/10-collectSamplesFilled.R $OUTDIR $scanmode $normalization $SCRIPTS/R" > $OUTDIR/jobs/10-collectSamplesFilled/${scanmode}.sh
qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/10-collectSamplesFilled -e $OUTDIR/logs/10-collectSamplesFilled $OUTDIR/jobs/10-collectSamplesFilled/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/queue/6-queueSumAdducts -e $OUTDIR/logs/queue/6-queueSumAdducts $OUTDIR/jobs/queue/6-queueSumAdducts_${scanmode}.sh
EOF

  # 6-queueSumAdducts.sh
cat << EOF >> $OUTDIR/jobs/queue/6-queueSumAdducts_${scanmode}.sh
#!/bin/bash

find "$OUTDIR/hmdb_part_adductSums" -iname "${scanmode}_*" | sort | while read hmdb;
 do
    input=\$(basename \$hmdb .RData)
    echo "Rscript $SCRIPTS/R/11-runSumAdducts.R \$hmdb $OUTDIR $scanmode $adducts $SCRIPTS/R" > $OUTDIR/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
    qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_${scanmode}_\${input}" -m as -M $MAIL -o $OUTDIR/logs/11-runSumAdducts -e $OUTDIR/logs/11-runSumAdducts $OUTDIR/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
done

echo "Rscript $SCRIPTS/R/12-collectSamplesAdded.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/12-collectSamplesAdded/${scanmode}.sh
qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_${scanmode}_*" -m ase -M $MAIL -o $OUTDIR/logs/12-collectSamplesAdded -e $OUTDIR/logs/12-collectSamplesAdded $OUTDIR/jobs/12-collectSamplesAdded/${scanmode}.sh
EOF


  qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_${scanmode}" -hold_jid "average" -m as -M $MAIL -o $OUTDIR/logs/queue/2-queuePeakFinding -e $OUTDIR/logs/queue/2-queuePeakFinding $OUTDIR/jobs/queue/2-queuePeakFinding_${scanmode}.sh
}

doScanmode "negative" $thresh_neg "*_neg.RData" "1"
doScanmode "positive" $thresh_pos "*_pos.RData" "1,2"


# start
#qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueStart" -m as -M $MAIL -o $OUTDIR/logs/queue/1-queueStart -e $OUTDIR/logs/queue/1-queueStart $OUTDIR/jobs/1-queueStart.sh
