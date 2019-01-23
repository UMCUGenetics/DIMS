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

find "$OUTDIR/grouping_rest" -iname "${scanmode}_*" | sort | while read rdata;
 do
  input=$(basename $rdata .RData)
  echo "Rscript $SCRIPTS/R/9-runFillMissing.R $rdata $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/9-runFillMissing/${scanmode}_${input}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_${scanmode}_${input}" -m as -M $MAIL -o $OUTDIR/logs/9-runFillMissing -e $OUTDIR/logs/9-runFillMissing $OUTDIR/jobs/9-runFillMissing/${scanmode}_${input}.sh
 done

find "$OUTDIR/grouping_hmdb" -iname "*_${scanmode}.RData" | sort | while read rdata2;
 do
  input=$(basename $rdata2 .RData)
  echo "Rscript $SCRIPTS/R/9-runFillMissing.R $rdata2 $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/9-runFillMissing2_${scanmode}_${input}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_${scanmode}_${input}" -hold_jid "peakFilling_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/9-runFillMissing -e $OUTDIR/logs/9-runFillMissing $OUTDIR/jobs/9-runFillMissing2_${scanmode}_${input}.sh
 done

echo "Rscript $SCRIPTS/R/10-collectSamplesFilled.R $OUTDIR $scanmode $normalization $SCRIPTS/R" > $OUTDIR/jobs/10-collectSamplesFilled/${scanmode}.sh
qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/10-collectSamplesFilled -e $OUTDIR/logs/10-collectSamplesFilled $OUTDIR/jobs/10-collectSamplesFilled/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/queue/6-queueSumAdducts -e $OUTDIR/logs/queue/6-queueSumAdducts $SCRIPTS/6-queueSumAdducts.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
