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
find "$OUTDIR/grouping_rest" -iname "${scanmode}_*" | sort | while read rdata;
 do
  it=$((it+1))
  echo "Rscript $SCRIPTS/R/9-runFillMissing.R $rdata $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/fillMissing_${scanmode}_${it}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_${scanmode}_${it}" -m as -M $MAIL -o $OUTDIR/logs/samplePeaksFilled/${scanmode}_${it}.o -e $OUTDIR/logs/samplePeaksFilled/${scanmode}_${it}.e $OUTDIR/jobs/fillMissing_${scanmode}_${it}.sh
 done

it=0
find "$OUTDIR/grouping_hmdb" -iname "*_${scanmode}.RData" | sort | while read rdata2;
 do
  it=$((it+1))
  echo "Rscript $SCRIPTS/R/9-runFillMissing.R $rdata2 $OUTDIR $scanmode $thresh $resol $SCRIPTS/R" > $OUTDIR/jobs/fillMissing2_${scanmode}_${it}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_${scanmode}_${it}" -hold_jid "peakFilling_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/samplePeaksFilled2/${scanmode}_${it}.o -e $OUTDIR/logs/samplePeaksFilled2/${scanmode}_${it}.e $OUTDIR/jobs/fillMissing3_${scanmode}_${it}.sh
 done

echo "Rscript $SCRIPTS/R/10-collectSamplesFilled.R $OUTDIR $scanmode $normalization $SCRIPTS/R" > $OUTDIR/jobs/collectSamplesFilled_${scanmode}.sh
qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $OUTDIR/jobs/collectSamplesFilled_${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $SCRIPTS/5-queueSumAdducts.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
