#!/bin/bash
file=$1
scripts=$2
outdir=$3
thresh=$4
resol=$5
scanmode=$6

echo "### Inputs runPeakFinding.sh #####################################################"
echo "	file:		  $file"
echo "	scripts:	$scripts"
echo "	outdir:		$outdir"
echo "  thresh:     $thresh"
echo "  resol:    $resol"
echo "  scanmode:    $scanmode"
echo "#############################################################################"

echo "Run file $file in R"
echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $file $scripts $outdir $thresh $resol $scanmode < "$scripts/peakFinding.2.0.R"