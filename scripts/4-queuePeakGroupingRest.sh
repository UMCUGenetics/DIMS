#!/bin/bash

INDIR=$1
OUTDIR=$2
SCRIPTS=$3
LOGDIR=$4
MAIL=$5

scanmode=$6
thresh=$7
label=$8
adducts=$9

. $INDIR/settings.config

find "$OUTDIR/specpks_all_rest" -iname "${scanmode}_*" | sort | while read file;
 do
   input=$(basename $file .RData)
   echo "Rscript $SCRIPTS/R/8-peakGrouping.2.0.rest.R $file $OUTDIR $scanmode $resol $SCRIPTS/R" > $OUTDIR/jobs/8-peakGrouping.2.0.rest/${scanmode}_${input}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_${scanmode}_${input}" -m as -M $MAIL -o $OUTDIR/logs/8-peakGrouping.2.0.rest -e $OUTDIR/logs/8-peakGrouping.2.0.rest $OUTDIR/jobs/8-peakGrouping.2.0.rest/${scanmode}_${input}.sh
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "queueFillMissing_$scanmode" -hold_jid "grouping2_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/queue/5-queueFillMissing -e $OUTDIR/logs/queue/5-queueFillMissing $SCRIPTS/5-queueFillMissing.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
