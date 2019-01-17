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
find "$OUTDIR/hmdb_part_adductSums" -iname "${scanmode}_*" | while read hmdb;
 do
    it=$((it+1))
    echo "Rscript $SCRIPTS/R/11-runSumAdducts.R $hmdb $OUTDIR $scanmode $adducts $SCRIPTS/R" > $OUTDIR/jobs/sumAdducts_${scanmode}_${i}.sh
    qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_$scanmode" -m as -M $MAIL -o $OUTDIR/logs/adductSums/${i}.o -e $OUTDIR/logs/adductSums/${i}.e $OUTDIR/jobs/sumAdducts_${scanmode}_${i}.sh
  #Rscript runSumAdducts.R $hmdb $scanmode $OUTDIR $adducts $SCRIPTS
done

echo "Rscript $SCRIPTS/R/12-collectSamplesAdded.R $OUTDIR $scanmode $SCRIPTS/R" > $OUTDIR/jobs/collectSamplesAdded_${scanmode}.sh
qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_$scanmode" -m as -M $MAIL -o $OUTDIR/logs -e $OUTDIR/logs $OUTDIR/jobs/collectSamplesAdded_${scanmode}.sh

#qsub -l h_rt=00:05:00 -l h_vmem=500M -N "mail_$scanmode" -hold_jid "sumAdducts_$scanmode" -m as -M $MAIL -o $JOBS -e $ERRORS $SCRIPTS/18-mail.sh $MAIL
