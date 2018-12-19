#!/bin/bash
file=$1
scripts=$2
outdir=$3
resol=$4
scanmode=$5

echo "### Inputs runPeakGrouping.sh ###############################################"
echo "	file:    ${file}"
echo "	scripts:	${scripts}"
echo "	outdir:		${outdir}"
echo "	resol:    ${resol}"
echo "	scanmode: ${scanmode}"
echo "#############################################################################"

module load R
R --slave --no-save --no-restore --no-environ --args ${file} ${scripts} ${outdir} ${resol} ${scanmode} < "${scripts}/peakGrouping.2.0.R"

echo $(date)
