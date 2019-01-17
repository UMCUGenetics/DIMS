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
find "$OUTDIR/hmdb_part" -iname "${scanmode}_*" | while read hmdb;
 do
   it=$((it+1))
   echo "Rscript $SCRIPTS/R/6-peakGrouping.2.0.R $hmdb $OUTDIR $scanmode $resol $SCRIPTS/R" > $OUTDIR/jobs/peakGrouping_${scanmode}_${it}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_${scanmode}_${it}" -m as -M $MAIL -o $OUTDIR/logs/grouping_hmdb/${scanmode}_${it}.o -e $OUTDIR/logs/grouping_hmdb/${scanmode}_${it}.e $OUTDIR/jobs/peakGrouping_${scanmode}_${it}.sh
 done

echo "Rscript $SCRIPTS/R/7-collectSamplesGroupedHMDB.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/collectSamplesGroupedHMDB_${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_${scanmode}_*" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $OUTDIR/jobs/collectSamplesGroupedHMDB_${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $SCRIPTS/3-queuePeakGroupingRest.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
