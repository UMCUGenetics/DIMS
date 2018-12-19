#!/bin/bash
file=$1
scanmode=$2
resol=$3
outdir=$4
thresh=$5
scripts=$6

echo "### Inputs runFillMissing.sh ###############################################"
echo "	rdata:	    $file"
echo "	scanmode: $scanmode"
echo "	resol:    $resol"
echo "	outdir:   $outdir"
echo "	thresh:   $thresh"
echo "	scripts:   $scripts"
echo "############################################################################"

echo "Outdir: $outdir"

module load R
R --slave --no-save --no-restore --no-environ --args $file $scanmode $resol $outdir $thresh $scripts< "$scripts/runFillMissing.R"
