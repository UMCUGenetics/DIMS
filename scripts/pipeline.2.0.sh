#!/bin/bash

user=Martin
scripts="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/scripts"
outdir="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/results"
inpdir="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/data"
jobsdir="/hpc/shared/dbg_mz/$user/Direct-Infusion-Pipeline_2.1/jobs"

#run= ?
#scripts="/hpc/dbg_mz/production/Dx_pipeline/"
#outdir="/hpc/dbg_mz/processed/"+ run 
#inpdir= "/hpc/dbg_mz/raw_data/"+ run
#jobsdir=outir+"/jobs/
# nrepl= $1
# normalization=$2
# make folder structure in output dir?


thresh_pos=2000
thresh_neg=2000
dimsThresh=100
resol=140000
trim=0.1

## these should be input parameters in run.sh and provided by Rshiny interface!
nrepl=3 # 3 or 5!
normalization="none" # "none", "total_IS", "total_ident", "total"

echo "`pwd`"

it=0
find $inpdir -iname "*.mzXML" | while read mzXML;
 do
     echo "Processing file $mzXML"
     it=$((it+1))

     if [[ $it == 1 ]] || [[ $it == 2 ]]; then
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -o $jobsdir -e $jobsdir -m as $scripts/runGenerateBreaks.sh $mzXML $outdir $trim $resol $scripts $nrepl
     fi

     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims" -o $jobsdir -e $jobsdir -m as -hold_jid "breaks" $scripts/runDIMS.sh $mzXML $scripts $outdir $trim $dimsThresh $resol
 done

qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -o $jobsdir -e $jobsdir -m as -hold_jid "dims" $scripts/runAverageTechReps.sh $scripts $outdir $nrepl

scanmode="negative"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_$scanmode" -o $jobsdir -e $jobsdir -m as -hold_jid "average" $scripts/queuePeakFinding.sh $scripts $outdir $inpdir $thresh_neg $resol $scanmode $normalization 
scanmode="positive"
qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_$scanmode" -o $jobsdir -e $jobsdir -m as -hold_jid "average" $scripts/queuePeakFinding.sh $scripts $outdir $inpdir $thresh_pos $resol $scanmode $normalization
