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

find "$OUTDIR/hmdb_part" -iname "${scanmode}_*" | while read hmdb;
 do
     qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/8-runPeakGrouping.sh $hmdb $OUTDIR $scanmode $resol $SCRIPTS/R
     #Rscript peakGrouping.2.0.R $hmdb $SCRIPTS $OUTDIR $resol $scanmode
 done

qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/9-runCollectSamplesGroupedHMDB.sh $OUTDIR $scanmode $SCRIPTS/R 
#Rscript collectSamplesGroupedHMDB.R $OUTDIR $scanmode

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/10-queuePeakGroupingRest.sh $INDIR $OUTDIR $SCRIPTS $JOBS $ERRORS $MAIL $scanmode $thresh $label $adducts
