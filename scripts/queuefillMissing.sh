#!/bin/bash
scanmode=$1
resol=$2
outdir=$3
thresh=$4
scripts=$5
normalization=$6

echo "### Inputs queuefillMissing.sh ###############################################"
echo "	scanmode: $scanmode"
echo "	resol:    $resol"
echo "	outdir:   $outdir"
echo "	thresh:   $thresh"
echo "	scripts:  $scripts"
echo "	normalization:  $normalization"
echo "###############################################################################"

if [ "$scanmode" == "negative" ]; then
 label="negative_*"
 label2="*_negative.RData"
else
 label="positive_*"
 label2="*_positive.RData"
fi

find "$outdir/grouping_rest" -iname $label | while read rdata;
 do
  echo "Filling in missing values for sample $rdata"
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_$scanmode" $scripts/runFillMissing.sh $rdata $scanmode $resol $outdir $thresh $scripts
 done

find "$outdir/grouping_hmdb" -iname $label2 | while read rdata2;
 do
  echo "Filling in missing values for sample $rdata2"
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_$scanmode" -hold_jid "peakFilling_$scanmode" $scripts/runFillMissing.sh $rdata2 $scanmode $resol $outdir $thresh $scripts
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_$scanmode" $scripts/runCollectSamplesFilled.sh $scripts $outdir $scanmode $normalization
qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" $scripts/queueSumAdducts.sh $scanmode $outdir $scripts

echo $(date)
