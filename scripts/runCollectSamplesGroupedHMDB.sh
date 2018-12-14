#!/bin/bash
scripts=$1
outdir=$2
scanmode=$3

echo "### Inputs runCollectSamples.sh #############################################"
echo "	scripts:	$scripts"
echo "	outdir:		$outdir"
echo "	scanmode:		$scanmode"
echo "#############################################################################"

echo "`pwd`"

module load R
R --slave --no-save --no-restore --no-environ --args "$outdir" "$scanmode" < "$scripts/collectSamplesGroupedHMDB.R"

echo $(date)