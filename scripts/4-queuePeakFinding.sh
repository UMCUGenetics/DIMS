#!/bin/bash

$INDIR=$1
$OUTDIR=$2
$SCRIPTS=$3
$JOBS=$4
$ERRORS=$5
$MAIL=$6

scanmode=$7
thresh=$8
label=$9
adducts=$10

. $INDIR/settings.config

find "$OUTDIR/average_pklist" -iname $label | while read sample;
 do
     qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/5-runPeakFinding.sh $sample $OUTDIR $SCRIPTS $scanmode $thresh $resol
     #Rscript peakFinding.2.0.R $sample $SCRIPTS $OUTDIR $thresh $resol $scanmode
 done

qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/6-runCollectSamples.sh $OUTDIR $SCRIPTS $scanmode
#Rscript collectSamples.R $OUTDIR $scanmode $SCRIPTS

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGrouping_$scanmode" -hold_jid "collect_$scanmode" $SCRIPTS/7-queuePeakGrouping.sh $INDIR $OUTDIR $SCRIPTS $JOBS $ERRORS $MAIL $scanmode $thresh $label $adducts
