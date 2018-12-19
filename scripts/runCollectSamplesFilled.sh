#!/bin/bash
scripts=$1
outdir=$2
scanmode=$3
normalization=$4

echo "### Inputs runCollectSamplesFilled.sh #############################################"
echo "	scripts:	$scripts"
echo "	outdir:		$outdir"
echo "	scanmode:	$scanmode"
echo "	normalization:	$normalization"
echo "#############################################################################"

echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args $outdir $scanmode $scripts $normalization < "$scripts/collectSamplesFilled.R"

echo $(date)
