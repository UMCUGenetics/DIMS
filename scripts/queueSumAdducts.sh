#!/bin/bash
scanmode=$1
outdir=$2
scripts=$3

echo "### Inputs queuesumAdducts.sh ###############################################"
echo "	scanmode: $scanmode"
echo "	outdir:   $outdir"
echo "	scripts:  $scripts"
echo "###############################################################################"

if [ "$scanmode" == "negative" ]; then
 label="negative_*"
 adducts="1" 
else
 label="positive_*"
 adducts="1,2"
fi

find "$outdir/hmdb_part_adductSums" -iname $label | while read hmdb;
 do
  echo "Sum adducts for sample $hmdb"
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_$scanmode" $scripts/runSumAdducts.sh $hmdb $scanmode $outdir $adducts $scripts
 done

qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_$scanmode" $scripts/runCollectSamplesAdded.sh $scripts $outdir $scanmode -M a.m.willemsen-8@umcutrecht.nl -m e
qsub -l h_rt=00:05:00 -l h_vmem=1G -N "mail_$scanmode" -hold_jid "collect3_$scanmode" $scripts/mail.sh $scanmode
echo $(date)