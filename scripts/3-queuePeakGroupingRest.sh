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
find "$OUTDIR/specpks_all_rest" -iname "${scanmode}_*" | sort | while read file;
 do
   it=$((it+1))
   echo "Rscript $SCRIPTS/R/8-peakGrouping.2.0.rest.R $file $OUTDIR $scanmode $resol $SCRIPTS/R" > $OUTDIR/jobs/peakGroupingRest_${scanmode}_${it}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_${scanmode}_${it}" -m as -M $MAIL -o $OUTDIR/logs/grouping_rest/${scanmode}_${it}.o -e $OUTDIR/logs/grouping_rest/${scanmode}_${it}.e $OUTDIR/jobs/peakGroupingRest_${scanmode}_${it}.sh
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "queueFillMissing_$scanmode" -hold_jid "grouping2_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $SCRIPTS/4-queueFillMissing.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts