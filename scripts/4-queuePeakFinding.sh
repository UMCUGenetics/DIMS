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

it=0
find "$OUTDIR/average_pklist" -iname $label | while read sample;
 do
   it=$((it+1))
     echo "Rscript $SCRIPTS/R/4-peakFinding.2.0.R $sample $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/peakFinding_${i}.sh
     qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/specpks/ -e $OUTDIR/logs/specpks $OUTDIR/jobs/peakFinding_${i}.sh
 done

echo "Rscript $SCRIPTS/R/5-collectSamples.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/collectSamples.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_$scanmode" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $OUTDIR/jobs/collectSamples.sh

exit 0
qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGrouping_$scanmode" -hold_jid "collect_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/7-queuePeakGrouping.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
