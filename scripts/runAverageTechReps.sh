#!/bin/bash
scripts=$1
outdir=$2
nrepl=$3

echo "### Inputs runAverageTechReps.sh ############################################"
echo "	scripts:	$scripts"
echo "	outdir:		$outdir"
echo "  nrepl:    $nrepl"
echo "#############################################################################"

echo "Run file $file in R"
echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $outdir $nrepl< "$scripts/averageTechReplicates.R"