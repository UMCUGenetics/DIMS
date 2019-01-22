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

find "$OUTDIR/average_pklist" -iname $label | sort | while read sample;
 do
   input=$(basename $sample .RData)
   echo "Rscript $SCRIPTS/R/4-peakFinding.2.0.R $sample $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/4-peakFinding.2.0/${scanmode}_${input}.sh
   qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_${scanmode}_${input}" -m as -M $MAIL -o $OUTDIR/logs/4-peakFinding.2.0 -e $OUTDIR/logs/4-peakFinding.2.0 $OUTDIR/jobs/4-peakFinding.2.0/${scanmode}_${input}.sh
 done

echo "Rscript $SCRIPTS/R/5-collectSamples.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/5-collectSamples_${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/5-collectSamples -e $OUTDIR/logs/5-collectSamples $OUTDIR/jobs/5-collectSamples_${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGrouping_$scanmode" -hold_jid "collect_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/queue/3-queuePeakGrouping -e $OUTDIR/logs/queue/3-queuePeakGrouping $SCRIPTS/3-queuePeakGrouping.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
