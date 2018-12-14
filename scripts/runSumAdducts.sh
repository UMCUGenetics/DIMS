#!/bin/bash
file=$1
scanmode=$2
outdir=$3
adducts=$4
scripts=$5

echo "### Inputs runSumAdducts.sh ###############################################"
echo "	rdata:	    $file"
echo "	scanmode: $scanmode"
echo "	outdir:   $outdir"
echo "	adducts:   $adducts"
echo "	scripts:   $scripts"
echo "############################################################################"

echo "Outdir: $outdir"

module load R
R --slave --no-save --no-restore --no-environ --args $file $scanmode $outdir $adducts < "$scripts/runSumAdducts.R"