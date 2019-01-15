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
JOBS=$PWD/tmp/${NAME}/'$JOB_NAME.txt' #/output
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



# Delete and create temp logging directories
rm -rf $JOBS
mkdir -p $JOBS
#rm -rf $ERRORS
#mkdir -p $ERRORS



it=0
find $INDIR -iname "*.mzXML" | sort | while read mzXML;
 do
     echo "Processing file $mzXML"
     it=$((it+1))

     if [ $it == 1 ] && [ ! -f $OUTDIR/breaks.fwhm.RData ] ; then # || [[ $it == 2 ]]
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -m as -M $MAIL -o $JOBS -e $JOBS $SCRIPTS/1-runGenerateBreaks.sh $mzXML $OUTDIR $trim $resol $nrepl $SCRIPTS
       #Rscript generateBreaksFwhm.HPC.R $mzXML $OUTDIR $INDIR $trim $resol $nrepl
     fi
     exit 0
     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims" -hold_jid "breaks" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/2-runDIMS.sh $mzXML $OUTDIR $trim $dimsThresh $resol $SCRIPTS
     #Rscript DIMS.R $mzXML $OUTDIR $trim $dimsThresh $resol $SCRIPTS
 done

exit 0

qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -hold_jid "dims" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/3-runAverageTechReps.sh $INDIR $OUTDIR $nrepl $thresh2remove $dimsThresh
#Rscript averageTechReplicates.R $OUTDIR $INDIR $nrepl $thresh2remove $dimsThresh


qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_negative" -hold_jid "dims" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/4-queuePeakFinding.sh $INDIR $OUTDIR $SCRIPTS $JOBS $ERRORS $MAIL "negative" $thresh_neg "*_neg.RData" "1"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_positive" -hold_jid "dims" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/4-queuePeakFinding.sh $INDIR $OUTDIR $SCRIPTS $JOBS $ERRORS $MAIL "positive" $thresh_pos "*_pos.RData" "1,2"
