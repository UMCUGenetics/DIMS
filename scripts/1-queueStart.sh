#!/bin/bash

INDIR=$1
OUTDIR=$2
SCRIPTS=$3
LOGDIR=$4
MAIL=$5

. $INDIR/settings.config

it=0
find $INDIR -iname "*.mzXML" | sort | while read mzXML;
 do
     it=$((it+1))
     input=$(basename $mzXML .mzXML)
     if [ $it == 1 ] && [ ! -f $OUTDIR/breaks.fwhm.RData ] ; then # || [[ $it == 2 ]]
       echo "Rscript $SCRIPTS/R/1-generateBreaksFwhm.HPC.R $mzXML $OUTDIR $trim $resol $nrepl $SCRIPTS/R" > $OUTDIR/jobs/1-generateBreaksFwhm.HPC.sh
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -m as -M $MAIL -o $OUTDIR/logs/1-generateBreaksFwhm.HPC -e $OUTDIR/logs/1-generateBreaksFwhm.HPC $OUTDIR/jobs/1-generateBreaksFwhm.HPC.sh
     fi

     echo "Rscript $SCRIPTS/R/2-DIMS.R $mzXML $OUTDIR $trim $dimsThresh $resol $SCRIPTS/R" > $OUTDIR/jobs/2-DIMS/${input}.sh
     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims_${input}" -hold_jid "breaks" -m as -M $MAIL -o $OUTDIR/logs/2-DIMS -e $OUTDIR/logs/2-DIMS $OUTDIR/jobs/2-DIMS/${input}.sh
 done

echo "Rscript $SCRIPTS/R/3-averageTechReplicates.R $INDIR $OUTDIR $nrepl $thresh2remove $dimsThresh $SCRIPTS/R" > $OUTDIR/jobs/3-averageTechReplicates.sh
qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -hold_jid "dims_*" -m as -M $MAIL -o $OUTDIR/logs/3-averageTechReplicates -e $OUTDIR/logs/3-averageTechReplicates $OUTDIR/jobs/3-averageTechReplicates.sh


qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_negative" -hold_jid "average" -m as -M $MAIL -o $OUTDIR/logs/queue/2-queuePeakFinding -e $OUTDIR/logs/queue/2-queuePeakFinding $SCRIPTS/2-queuePeakFinding.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL "negative" $thresh_neg "*_neg.RData" "1"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_positive" -hold_jid "average" -m as -M $MAIL -o $OUTDIR/logs/queue/2-queuePeakFinding -e $OUTDIR/logs/queue/2-queuePeakFinding $SCRIPTS/2-queuePeakFinding.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL "positive" $thresh_pos "*_pos.RData" "1,2"
