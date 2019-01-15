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

find "$OUTDIR/average_pklist" -iname $label | while read sample;
 do
     qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME'"_${sample}.txt" -e $LOGDIR/'$JOB_NAME'"_${sample}.txt" $SCRIPTS/5-runPeakFinding.sh $sample $OUTDIR $scanmode $thresh $resol $SCRIPTS/R
     #Rscript peakFinding.2.0.R $sample $SCRIPTS $OUTDIR $thresh $resol $scanmode
 done

qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/6-runCollectSamples.sh $OUTDIR $scanmode $SCRIPTS/R
#Rscript collectSamples.R $OUTDIR $scanmode $SCRIPTS

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGrouping_$scanmode" -hold_jid "collect_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/7-queuePeakGrouping.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
