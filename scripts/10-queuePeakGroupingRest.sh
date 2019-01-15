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

find "$OUTDIR/specpks_all_rest" -iname "${scanmode}_*" | while read file;
 do
     qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME'"_${file##*/}.txt" -e $LOGDIR/'$JOB_NAME'"_${file##*/}.txt" $SCRIPTS/11-runPeakGroupingRest.sh $file $OUTDIR $scanmode $resol $SCRIPTS/R
     #Rscript peakGrouping.2.0.rest.R $file $SCRIPTS $OUTDIR $resol $scanmode
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "queueFillMissing_$scanmode" -hold_jid "grouping2_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/12-queueFillMissing.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
