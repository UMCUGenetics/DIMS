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

find "$OUTDIR/hmdb_part" -iname "${scanmode}_*" | while read hmdb;
 do
     qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME'"_${hmdb##*/}.txt" -e $LOGDIR/'$JOB_NAME'"_${hmdb##*/}.txt" $SCRIPTS/8-runPeakGrouping.sh $hmdb $OUTDIR $scanmode $resol $SCRIPTS/R
     #Rscript peakGrouping.2.0.R $hmdb $SCRIPTS $OUTDIR $resol $scanmode
 done

qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/9-runCollectSamplesGroupedHMDB.sh $OUTDIR $scanmode $SCRIPTS/R
#Rscript collectSamplesGroupedHMDB.R $OUTDIR $scanmode

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/10-queuePeakGroupingRest.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
