#!/bin/bash

# todo :
# getting the same output as before;
# mailing;
# something that checks which steps have already been done when starting pipeline
# figure out .Rprofile to never have to load libraries or point to where they are


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

#BASE=/hpc/dbg_mz
BASE=/Users/nunen/Documents/GitHub/Dx_metabolomics
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

cp $INDIR/settings.config $OUTDIR/logs
cp $INDIR/init.RData $OUTDIR/logs
git rev-parse HEAD > $OUTDIR/logs/commit

# start
qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueStart" -m as -M $MAIL -o $OUTDIR/logs/queue/1-queueStart -e $OUTDIR/logs/queue/1-queueStart $SCRIPTS/1-queueStart.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL
