#!/bin/bash
file=$1
outdir=$2
trim=$3
resol=$4
scripts=$5/generateBreaksFwhm.HPC.R
nrepl=$6

echo "### Inputs runGenerateBreaks.sh #####################################################"
echo "	file:		  $file"
echo "	outdir:		$outdir"
echo "  trim:     $trim"
echo "  resol:    $resol"
echo "  scripts:    $scripts"
echo "  nrepl:    $nrepl"
echo "#############################################################################"

echo "Generate breaks.fwhm"
echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $file $outdir $indir $trim $resol $nrepl < $scripts
