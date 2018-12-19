#!/bin/bash

R='\033[0;31m' # Red
G='\033[0;32m' # Green
NC='\033[0m' # No Color

arg=$1

# Check if any argument was given
if [ -z "$arg" ]; then
  printf "${R}No argument supplied.${NC}\n"
	arg="-h"
fi


# Make vars for all the directories that will be used
scripts=$PWD/scripts
jobs=$PWD/jobs

base=/hpc/dbg_mz
indir=$base/raw_data/$1
outdir=$base/processed/$1


# Check existence input dir
if [ ! -d "$indir" ]; then
	printf "${R}The input directory for run $1 does not exist. ($indir)${NC}\n"
	arg='-h'
else
	# All the pipeline files and possible input files are listed here.
	for pipelineFile in \
		$indir/settings.config \
	  $indir/init.RData \
	  #$PWD"/db" \

	# Their presences are checked.
	do
		if ! [ -f ${pipelineFile} ]; then
			printf "${R}${pipelineFile} does not exist.${NC}\n"
			arg="-h"
		fi
	done
fi

# Show usage information
if [ "$arg" == "--h" ] || [ "$arg" == "--help" ] || [ "$arg" == "-h" ] || [ "$arg" == "-help" ]
	then
		echo ""
		echo "Run this script to start the DIMS pipeline with the following command:"
		echo ""
		printf "${G}sh run.sh <run name>${NC}\n"
		echo "eg. 'sh run.sh run1'"
		echo ""
		echo "Parameters can be configured with the setting.config file in the raw data folder."
		echo ""
		echo "Pipeline not started"
		exit
fi

# load parameters
. $indir/settings.config

# make jobs dir if it doesnt exist
mkdir -p $jobs

it=0
find $indir -iname "*.mzXML" | while read mzXML;
 do
     echo "Processing file $mzXML"
     it=$((it+1))

     if [[ $it == 1 ]] || [[ $it == 2 ]]; then
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -o $jobs -e $jobs -m as $scripts/runGenerateBreaks.sh $mzXML $outdir $indir $trim $resol $scripts $nrepl
     fi

     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims" -o $jobs -e $jobs -m as -hold_jid "breaks" $scripts/runDIMS.sh $mzXML $scripts $outdir $trim $dimsThresh $resol
 done

qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -o $jobs -e $jobs -m as -hold_jid "dims" $scripts/runAverageTechReps.sh $scripts $outdir $indir $nrepl $thresh2remove $dimsThresh

scanmode="negative"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_$scanmode" -o $jobs -e $jobs -m as -hold_jid "average" $scripts/queuePeakFinding.sh $scripts $outdir $indir $thresh_neg $resol $scanmode $normalization $jobs
scanmode="positive"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_$scanmode" -o $jobs -e $jobs -m as -hold_jid "average" $scripts/queuePeakFinding.sh $scripts $outdir $indir $thresh_pos $resol $scanmode $normalization $jobs

#qsub -l h_rt=00:05:00 -l h_vmem=1G -N "mail_negative" -hold_jid "collect3_negative" ./scripts/mail.sh "negative"
