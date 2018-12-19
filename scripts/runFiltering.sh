#!/bin/bash
scripts=$1
resol=$2
outdir=$3
thresh=$4
indir=$5
scanmode=$6
version=$7

echo "### Inputs runFiltering.sh ################################"
echo "	scripts:	$scripts"
echo "	resol:    $resol"
echo "	outdir:		$outdir"
echo "	thresh:		$thresh"
echo "	indir:		$indir"
echo "	indir:		$scanmode"
echo "	version:		$version"
#################################################################"

module load R
R --slave --no-save --no-restore --no-environ --args "$scripts" $resol "$outdir" $thresh "$indir" "$scanmode" $version < "$scripts/peakFiltering.R"

echo $(date)
