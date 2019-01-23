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

find "$OUTDIR/hmdb_part" -iname "${scanmode}_*" | sort | while read hmdb;
 do
   input=$(basename $hmdb .RData)
   echo "Rscript $SCRIPTS/R/6-peakGrouping.2.0.R $hmdb $OUTDIR $scanmode $resol $SCRIPTS/R" > $OUTDIR/jobs/6-peakGrouping.2.0/${scanmode}_${input}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_${scanmode}_${input}" -m as -M $MAIL -o $OUTDIR/logs/6-peakGrouping.2.0 -e $OUTDIR/logs/6-peakGrouping.2.0 $OUTDIR/jobs/6-peakGrouping.2.0/${scanmode}_${input}.sh
 done

echo "Rscript $SCRIPTS/R/7-collectSamplesGroupedHMDB.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/7-collectSamplesGroupedHMDB_${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs/7-collectSamplesGroupedHMDB -e $OUTDIR/logs/7-collectSamplesGroupedHMDB $OUTDIR/jobs/7-collectSamplesGroupedHMDB_${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/queue/4-queuePeakGroupingRest -e $OUTDIR/logs/queue/4-queuePeakGroupingRest $SCRIPTS/4-queuePeakGroupingRest.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
