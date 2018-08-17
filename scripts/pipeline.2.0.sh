#!/bin/bash
#####################################################################
#####################################################################
user=marcel
#####################################################################
#####################################################################

# scripts="./scripts"
# outdir="./results"
# inpdir="./data"

scripts="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/scripts"
outdir="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/results"
inpdir="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/data"

thresh_pos=2000
thresh_neg=2000
dimsThresh=100
resol=140000
trim=0.1
nrepl=3 # 3 or 5!
normalization="none" # "none", "total_IS", "total_ident", "total"

# thresh2remove = 1*10^9 ============> set in averageTechReplicates.R
# thresh2remove = 5*10^8

echo "`pwd`"

it=0
find $inpdir -iname "*.mzXML" | while read mzXML;
 do
     echo "Processing file $mzXML"
     it=$((it+1))

     if [[ $it == 1 ]] || [[ $it == 2 ]]; then
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" $scripts/runGenerateBreaks.sh $mzXML $outdir $trim $resol $scripts $nrepl
     fi

     qsub -l h_rt=00:10:00 -l h_vmem=2G -N "dims" -hold_jid "breaks" $scripts/runDIMS.sh $mzXML $scripts $outdir $trim $dimsThresh $resol
 done

qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -hold_jid "dims" $scripts/runAverageTechReps.sh $scripts $outdir $nrepl

scanmode="negative"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_$scanmode" -hold_jid "average" $scripts/queuePeakFinding.sh $scripts $outdir $inpdir $thresh_neg $resol $scanmode $normalization
scanmode="positive"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_$scanmode" -hold_jid "average" $scripts/queuePeakFinding.sh $scripts $outdir $inpdir $thresh_pos $resol $scanmode $normalization
