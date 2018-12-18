#!/bin/bash
file=$1
outdir=$2
indir=$3
trim=$4
resol=$5
scripts=$6
nrepl=$7

echo "### Inputs runGenerateBreaks.sh #####################################################"
echo "	file:		  $file"
echo "	outdir:		$outdir"
echo "	indir:		$indir"
echo "  trim:     $trim"
echo "  resol:    $resol"
echo "  scripts:    $scripts"
echo "  nrepl:    $nrepl"
echo "#############################################################################"

echo "Generate breaks.fwhm"
echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $file $outdir $indir $trim $resol $nrepl < $scripts/generateBreaksFwhm.HPC.R
