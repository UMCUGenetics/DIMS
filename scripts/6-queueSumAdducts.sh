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

find "$OUTDIR/hmdb_part_adductSums" -iname "${scanmode}_*" | sort | while read hmdb;
 do
    input=$(basename $hmdb .RData)
    echo "Rscript $SCRIPTS/R/11-runSumAdducts.R $hmdb $OUTDIR $scanmode $adducts $SCRIPTS/R" > $OUTDIR/jobs/11-runSumAdducts/${scanmode}_${input}.sh
    qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_${scanmode}_${input}" -m as -M $MAIL -o $OUTDIR/logs/11-runSumAdducts -e $OUTDIR/logs/11-runSumAdducts $OUTDIR/jobs/11-runSumAdducts/${scanmode}_${input}.sh
done

echo "Rscript $SCRIPTS/R/12-collectSamplesAdded.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/12-collectSamplesAdded/${scanmode}.sh
qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_${scanmode}_*" -m ase -M $MAIL -o $OUTDIR/logs/12-collectSamplesAdded -e $OUTDIR/logs/12-collectSamplesAdded $OUTDIR/jobs/12-collectSamplesAdded/${scanmode}.sh

#qsub -l h_rt=00:05:00 -l h_vmem=500M -N "mail_$scanmode" -hold_jid "sumAdducts_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/18-mail.sh $MAIL
