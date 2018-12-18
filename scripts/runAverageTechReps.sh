#!/bin/bash
scripts=$1
outdir=$2
indir=$3
nrepl=$4
thresh2remove=$5
dimsThresh=$6

echo "### Inputs runAverageTechReps.sh ############################################"
echo "	scripts:	$scripts"
echo "	outdir:		$outdir"
echo "	indir:		$indir"
echo "  nrepl:    $nrepl"
echo "	thresh2remove:		$thresh2remove"
echo "	dimsThresh:		$dimsThresh"
echo "#############################################################################"

echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $outdir $indir $nrepl $thresh2remove $dimsThresh < "$scripts/averageTechReplicates.R"
