#!/bin/bash
file=$1
scripts=$2
outdir=$3
trim=$4
dimsThresh=$5
resol=$6

echo "### Inputs runDIMS.sh #####################################################"
echo "	file:		  $file"
echo "	scripts:	$scripts"
echo "	outdir:		$outdir"
echo "  trim:     $trim"
echo "	dimsThresh:   $dimsThresh"
echo "  resol:    $resol"
echo "#############################################################################"

echo "Run file $file in R"
echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $file $scripts $outdir $trim $dimsThresh $resol < "$scripts/DIMS.R"