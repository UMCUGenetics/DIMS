#!/bin/bash

# todo :
# getting the same output as before;
# mailing;
# something that checks which steps have already been done when starting pipeline


start=`date +%s`

set -o pipefail
set -e

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
QSUB=0
NAME=""
EMAIL=""

# Show usage information
function show_help() {
  if [[ ! -z $1 ]]; then
  printf "
  ${R}ERROR:
    $1${NC}"
  fi
  printf "
  ${P}USAGE:
    ${0} -n <run dir> [-m <email>] [-r] [-q] [-v] [-h]

  ${B}REQUIRED ARGS:
    -n - name of input folder, eg run1 (required)${NC}

  ${C}OPTIONAL ARGS:
    -m - email address to send errors to (default logs to stdout)
    -r - restart the pipeline, removing any existing output for the entered run (default off)
    -q - qsub the commands (only possible on HPC server) (default off)
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
  q) QSUB=1 ;;
  n) NAME=${OPTARG} ;;
	m) EMAIL=${OPTARG} ;;
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
JOBS=$PWD/tmp/${NAME}/output
ERRORS=$PWD/tmp/${NAME}/output

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

# Check existence input dir
if [ ! -d $INDIR ]; then
	show_help "The input directory for run $NAME does not exist at
    $INDIR${NC}\n"
else
	# All the pipeline files and possible input files are listed here.
	for pipelineFile in \
		$INDIR/settings.config \
	  $INDIR/init.RData \
	  #$PWD"/db" \

	# Their presence are checked.
	do
		if ! [ -f ${pipelineFile} ]; then
			show_help "${pipelineFile} does not exist."
		fi
	done
fi

# Load parameters
. $INDIR/settings.config



# Create logging directories
rm -rf $JOBS
mkdir -p $JOBS
rm -rf $ERRORS
mkdir -p $ERRORS

# Enter the script directory
cd $SCRIPTS



it=0
find $INDIR -iname "*.mzXML" | while read mzXML;
 do
     echo "Processing file $mzXML"
     it=$((it+1))

     if [ $it == 1 && [ ! -f $OUTDIR/breaks.fwhm.RData] ; then # || [[ $it == 2 ]]
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -o $JOBS -e $ERRORS runGenerateBreaks.sh $mzXML $OUTDIR $trim $resol $scripts $nrepl
       #Rscript generateBreaksFwhm.HPC.R $mzXML $OUTDIR $INDIR $trim $resol $nrepl
     fi

     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims" -hold_jid "breaks" -o $JOBS -e $ERRORS runDIMS.sh $mzXML $SCRIPTS $OUTDIR $trim $dimsThresh $resol
     #Rscript DIMS.R $mzXML $OUTDIR $trim $dimsThresh $resol $SCRIPTS
 done

qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -hold_jid "dims" -o $JOBS -e $ERRORS runAverageTechReps.sh $SCRIPTS $OUTDIR $nrepl
#Rscript averageTechReplicates.R $OUTDIR $INDIR $nrepl $thresh2remove $dimsThresh


function doScanmodes() {
  scanmode=$1
  label=$2
  thresh=$3
  adducts=$4


  #queuePeakFinding.sh
  find "$OUTDIR/average_pklist" -iname $label | while read sample;
   do
       qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_$scanmode" -hold_jid "average" -o $JOBS -e $ERRORS runPeakFinding.sh $sample $SCRIPTS $OUTDIR $thresh $resol $scanmode
       #Rscript peakFinding.2.0.R $sample $SCRIPTS $OUTDIR $thresh $resol $scanmode
   done

  qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_$scanmode" -o $JOBS -e $ERRORS runCollectSamples.sh $OUTDIR $scanmode $SCRIPTS
  #Rscript collectSamples.R $OUTDIR $scanmode $SCRIPTS


  #queuePeakGrouping.sh
  label2="${scanmode}_*"

  find "$OUTDIR/hmdb_part" -iname $label2 | while read hmdb;
   do
       qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_$scanmode" -hold_jid "collect_$scanmode" -o $JOBS -e $ERRORS runPeakGrouping.sh $hmdb $SCRIPTS $OUTDIR $resol $scanmode
       #Rscript peakGrouping.2.0.R $hmdb $SCRIPTS $OUTDIR $resol $scanmode
   done

  qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_$scanmode" -o $JOBS -e $ERRORS runCollectSamplesGroupedHMDB.sh $OUTDIR $scanmode
  #Rscript collectSamplesGroupedHMDB.R $OUTDIR $scanmode


  #queuePeakGroupingRest.sh
  find "$OUTDIR/specpks_all_rest" -iname $label2 | while read file;
   do
       qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_$scanmode" -hold_jid "collect1_$scanmode" -o $JOBS -e $ERRORS runPeakGroupingRest.sh $file $SCRIPTS $OUTDIR $resol $scanmode
       #Rscript peakGrouping.2.0.rest.R $file $SCRIPTS $OUTDIR $resol $scanmode
   done


  #queueFillMissing.sh
  label3="*_${scanmode}.RData"

   find "$OUTDIR/grouping_rest" -iname $label2 | while read rdata;
    do
     qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_$scanmode" -hold_jid "grouping2_$scanmode" -o $JOBS -e $ERRORS runFillMissing.sh $rdata $scanmode $resol $OUTDIR $thresh $SCRIPTS
     #Rscript runFillMissing.R $rdata $scanmode $resol $OUTDIR $thresh $SCRIPTS
   done

   find "$OUTDIR/grouping_hmdb" -iname $label3 | while read rdata2;
    do
     qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_$scanmode" -hold_jid "peakFilling_$scanmode" -o $JOBS -e $ERRORS  runFillMissing.sh $rdata2 $scanmode $resol $OUTDIR $thresh $SCRIPTS
     #Rscript runFillMissing.R $rdata2 $scanmode $resol $OUTDIR $thresh $SCRIPTS
   done

   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_$scanmode" -o $JOBS -e $ERRORS runCollectSamplesFilled.sh $OUTDIR $scanmode $SCRIPTS $normalization
   #Rscript collectSamplesFilled.R $OUTDIR $scanmode $SCRIPTS $normalization


   #queueSumAdducts.sh
   find "$OUTDIR/hmdb_part_adductSums" -iname $label2 | while read hmdb;
    do
     qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_$scanmode" -hold_jid "collect2_$scanmode" -o $JOBS -e $ERRORS runSumAdducts.sh $hmdb $scanmode $OUTDIR $adducts $SCRIPTS
     #Rscript runSumAdducts.R $hmdb $scanmode $OUTDIR $adducts $SCRIPTS
   done

   qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_$scanmode" -o $JOBS -e $ERRORS runCollectSamplesAdded.sh $OUTDIR $scanmode
   #Rscript collectSamplesAdded.R $OUTDIR $scanmode
}

doScanmodes "negative" "*_neg.RData" $thresh_neg "1" &
doScanmodes "positive" "*_pos.RData" $thresh_pos "1,2" &
wait ${!}

end=`date +%s`
runtime=$((end-start))
echo "Finished after $runtime seconds."
