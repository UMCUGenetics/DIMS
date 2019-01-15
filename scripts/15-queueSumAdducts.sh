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

find "$OUTDIR/hmdb_part_adductSums" -iname "${scanmode}_*" | while read hmdb;
 do
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/16-runSumAdducts.sh $hmdb $OUTDIR $scanmode $adducts $SCRIPTS/R
  #Rscript runSumAdducts.R $hmdb $scanmode $OUTDIR $adducts $SCRIPTS
done

qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/17-runCollectSamplesAdded.sh $OUTDIR $scanmode $SCRIPTS/R
#Rscript collectSamplesAdded.R $OUTDIR $scanmode

#qsub -l h_rt=00:05:00 -l h_vmem=500M -N "mail_$scanmode" -hold_jid "sumAdducts_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/18-mail.sh $MAIL
