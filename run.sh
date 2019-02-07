#!/bin/bash

# todo :
# getting the same output as before;
# mailing;
# something that checks which steps have already been done when starting pipeline
# figure out .Rprofile to never have to load libraries or point to where they are


start=`date +%s`

set -o pipefail
set -e
#set -x

R='\033[0;31m' # Red
G='\033[0;32m' # Green
Y='\033[0;33m' # Yellow
B='\033[0;34m' # Blue
P='\033[0;35m' # Pink
C='\033[0;36m' # Cyan
NC='\033[0m' # No Color

# Defaults
verbose=0
restart=0
name=""

# Show usage information
function show_help() {
  if [[ ! -z $1 ]]; then
  printf "
  ${R}ERROR:
    $1${NC}"
  fi
  printf "
  ${P}USAGE:
    ${0} -n <run dir> [-r] [-v] [-h]

  ${B}REQUIRED ARGS:
    -n - name of input folder, eg run1 (required)${NC}

  ${C}OPTIONAL ARGS:
    -r - restart the pipeline, removing any existing output for the entered run (default off)
    -v - verbose logging (default off)
    -h - show help${NC}

  ${G}EXAMPLE:
    sh run.sh -n run1${NC}

  "
  exit 1
}

while getopts "h?vrqn:" opt
do
	case "${opt}" in
	h|\?)
		show_help
		exit 0
		;;
	v) verbose=1 ;;
  r) restart=1 ;;
  n) name=${OPTARG} ;;
	esac
done

shift "$((OPTIND-1))"

if [ -z ${name} ] ; then show_help "Required arguments were not given.\n" ; fi
if [ ${verbose} -gt 0 ] ; then set -x ; fi

base=/hpc/dbg_mz
#BASE=/Users/nunen/Documents/GitHub/Dx_metabolomics
indir=$base/raw_data/${name}
outdir=$base/processed/${name}
scripts=$pwd/scripts

while [[ ${restart} -gt 0 ]]
do
  printf "\nAre you sure you want to restart the pipeline for this run, causing all existing files at ${Y}$outdir${NC} to get deleted?"
  read -p " " yn
  case $yn in
      [Yy]* ) rm -rf $outdir; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
  esac
done

declare -a scriptsR=("1-generateBreaksFwhm.HPC" \
                     "2-DIMS" \
                     "3-averageTechReplicates" \
                     "4-peakFinding.2.0" \
                     "5-collectSamples" \
                     "6-peakGrouping.2.0" \
                     "7-collectSamplesGroupedHMDB" \
                     "8-peakGrouping.rest" \
                     "9-runFillMissing" \
                     "10-collectSamplesFilled" \
                     "11-runSumAdducts" \
                     "12-collectSamplesAdded" )


# Check existence input dir
if [ ! -d $indir ]; then
	show_help "The input directory for run $NAME does not exist at
    $indir${NC}\n"
else
  # R scripts
  for s in "${scriptsR[@]}"
  do
    script=$scripts/${s}.R
    if ! [ -f ${script} ]; then
     show_help "${script} does not exist."
    fi
    mkdir -p $outdir/logs/$s
    mkdir -p $outdir/jobs/$s
  done

  # etc files
  for file in \
		$indir/settings.config \
	  $indir/init.RData \
	  $pwd/db/HMDB_add_iso_corrNaCl_only_IS.RData \
    $pwd/db/HMDB_add_iso_corrNaCl_with_IS.RData \
    $pwd/db/HMDB_add_iso_corrNaCl.RData \
    $pwd/db/HMDB_with_info_relevance.RData \
    $pwd/db/TheoreticalMZ_NegPos_incNaCl.txt
	do
		if ! [ -f ${file} ]; then
			show_help "${file} does not exist."
		fi
	done
fi


mkdir -p $outdir/logs/queue
mkdir -p $outdir/jobs/queue

cp $indir/settings.config $outdir/logs
cp $indir/init.RData $outdir/logs
git rev-parse HEAD > $outdir/logs/commit


. $indir/settings.config
thresh2remove=$(printf "%.0f" $thresh2remove) # to convert to decimal from scientific notation

# 1-queueStart.sh
it=0
find $indir -iname "*.mzXML" | sort | while read mzXML;
 do
     it=$((it+1))
     input=$(basename $mzXML .mzXML)
     if [ $it == 1 ] && [ ! -f $outdir/breaks.fwhm.RData ] ; then # || [[ $it == 2 ]]
       echo "Rscript $scripts/1-generateBreaksFwhm.HPC.R $mzXML $outdir $trim $resol $nrepl $scripts" > $outdir/jobs/1-generateBreaksFwhm.HPC/breaks.sh
       qsub -l h_rt=00:05:00 -l h_vmem=1G -N "breaks" -m as -M $email -o $outdir/logs/1-generateBreaksFwhm.HPC -e $outdir/logs/1-generateBreaksFwhm.HPC $outdir/jobs/1-generateBreaksFwhm.HPC/breaks.sh
     fi

     echo "Rscript $scripts/2-DIMS.R $mzXML $outdir $trim $dims_thresh $resol $scripts" > $outdir/jobs/2-DIMS/${input}.sh
     qsub -l h_rt=00:10:00 -l h_vmem=4G -N "dims_${input}" -hold_jid "breaks" -m as -M $email -o $outdir/logs/2-DIMS -e $outdir/logs/2-DIMS $outdir/jobs/2-DIMS/${input}.sh
 done

echo "Rscript $scripts/3-averageTechReplicates.R $indir $outdir $nrepl $thresh2remove $dims_thresh $scripts" > $outdir/jobs/3-averageTechReplicates/average.sh
qsub -l h_rt=01:30:00 -l h_vmem=5G -N "average" -hold_jid "dims_*" -m as -M $email -o $outdir/logs/3-averageTechReplicates -e $outdir/logs/3-averageTechReplicates $outdir/jobs/3-averageTechReplicates/average.sh


doScanmode() {
  scanmode=$1
  thresh=$2
  label=$3
  adducts=$4


  # 2-queuePeakFinding.sh
cat << EOF >> $outdir/jobs/queue/2-queuePeakFinding_${scanmode}.sh
#!/bin/bash

find "$outdir/average_pklist" -iname $label | sort | while read sample;
 do
   input=\$(basename \$sample .RData)
   echo "Rscript $scripts/4-peakFinding.R \$sample $outdir $scanmode $thresh $resol $scripts" > $outdir/jobs/4-peakFinding.2.0/${scanmode}_\${input}.sh
   qsub -l h_rt=00:30:00 -l h_vmem=8G -N "peakFinding_${scanmode}_\${input}" -m as -M $email -o $outdir/logs/4-peakFinding.2.0 -e $outdir/logs/4-peakFinding.2.0 $outdir/jobs/4-peakFinding.2.0/${scanmode}_\${input}.sh
 done

echo "Rscript $scripts/5-collectSamples.R $outdir $scanmode $scripts" > $outdir/jobs/5-collectSamples/${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect_$scanmode" -hold_jid "peakFinding_${scanmode}_*" -m as -M $email -o $outdir/logs/5-collectSamples -e $outdir/logs/5-collectSamples $outdir/jobs/5-collectSamples/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGrouping_$scanmode" -hold_jid "collect_$scanmode" -m as -M $email -o $outdir/logs/queue/3-queuePeakGrouping -e $outdir/logs/queue/3-queuePeakGrouping $outdir/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
EOF


  # 3-queuePeakGrouping.sh
cat << EOF >> $outdir/jobs/queue/3-queuePeakGrouping_${scanmode}.sh
#!/bin/bash

find "$outdir/hmdb_part" -iname "${scanmode}_*" | sort | while read hmdb;
 do
   input=\$(basename \$hmdb .RData)
   echo "Rscript $scripts/6-peakGrouping.R \$hmdb $outdir $scanmode $resol $scripts" > $outdir/jobs/6-peakGrouping.2.0/${scanmode}_\${input}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_${scanmode}_\${input}" -m as -M $email -o $outdir/logs/6-peakGrouping.2.0 -e $outdir/logs/6-peakGrouping.2.0 $outdir/jobs/6-peakGrouping.2.0/${scanmode}_\${input}.sh
 done

echo "Rscript $scripts/7-collectSamplesGroupedHMDB.R $outdir $scanmode $scripts" > $outdir/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh
qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_${scanmode}_*" -m as -M $email -o $outdir/logs/7-collectSamplesGroupedHMDB -e $outdir/logs/7-collectSamplesGroupedHMDB $outdir/jobs/7-collectSamplesGroupedHMDB/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" -m as -M $email -o $outdir/logs/queue/4-queuePeakGroupingRest -e $outdir/logs/queue/4-queuePeakGroupingRest $outdir/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
EOF

  # 4-queuePeakGroupingRest.sh
cat << EOF >> $outdir/jobs/queue/4-queuePeakGroupingRest_${scanmode}.sh
#!/bin/bash

find "$outdir/specpks_all_rest" -iname "${scanmode}_*" | sort | while read file;
 do
   input=\$(basename \$file .RData)
   echo "Rscript $scripts/8-peakGrouping.rest.R \$file $outdir $scanmode $resol $scripts" > $outdir/jobs/8-peakGrouping.rest/${scanmode}_\${input}.sh
   qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_${scanmode}_\${input}" -m as -M $email -o $outdir/logs/8-peakGrouping.rest -e $outdir/logs/8-peakGrouping.rest $outdir/jobs/8-peakGrouping.rest/${scanmode}_\${input}.sh
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "queueFillMissing_$scanmode" -hold_jid "grouping2_${scanmode}_*" -m as -M $email -o $outdir/logs/queue/5-queueFillMissing -e $outdir/logs/queue/5-queueFillMissing $outdir/jobs/queue/5-queueFillMissing_${scanmode}.sh
EOF

  # 5-queueFillMissing.sh
cat << EOF >> $outdir/jobs/queue/5-queueFillMissing_${scanmode}.sh
#!/bin/bash

find "$outdir/grouping_rest" -iname "${scanmode}_*" | sort | while read rdata;
 do
  input=\$(basename \$rdata .RData)
  echo "Rscript $scripts/9-runFillMissing.R \$rdata $outdir $scanmode $thresh $resol $scripts" > $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_${scanmode}_\${input}" -m as -M $email -o $outdir/logs/9-runFillMissing -e $outdir/logs/9-runFillMissing $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
 done

find "$outdir/grouping_hmdb" -iname "*_${scanmode}.RData" | sort | while read rdata2;
 do
  input=\$(basename \$rdata2 .RData)
  echo "Rscript $scripts/9-runFillMissing.R \$rdata2 $outdir $scanmode $thresh $resol $scripts" > $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_${scanmode}_\${input}" -hold_jid "peakFilling_${scanmode}_*" -m as -M $email -o $outdir/logs/9-runFillMissing -e $outdir/logs/9-runFillMissing $outdir/jobs/9-runFillMissing/${scanmode}_\${input}.sh
 done

echo "Rscript $scripts/10-collectSamplesFilled.R $outdir $scanmode $normalization $scripts" > $outdir/jobs/10-collectSamplesFilled/${scanmode}.sh
qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_${scanmode}_*" -m as -M $email -o $outdir/logs/10-collectSamplesFilled -e $outdir/logs/10-collectSamplesFilled $outdir/jobs/10-collectSamplesFilled/${scanmode}.sh

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" -m as -M $email -o $outdir/logs/queue/6-queueSumAdducts -e $outdir/logs/queue/6-queueSumAdducts $outdir/jobs/queue/6-queueSumAdducts_${scanmode}.sh
EOF

  # 6-queueSumAdducts.sh
cat << EOF >> $outdir/jobs/queue/6-queueSumAdducts_${scanmode}.sh
#!/bin/bash

find "$outdir/hmdb_part_adductSums" -iname "${scanmode}_*" | sort | while read hmdb;
 do
    input=\$(basename \$hmdb .RData)
    echo "Rscript $scripts/11-runSumAdducts.R \$hmdb $outdir $scanmode $adducts $scripts" > $outdir/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
    qsub -l h_rt=02:00:00 -l h_vmem=8G -N "sumAdducts_${scanmode}_\${input}" -m as -M $email -o $outdir/logs/11-runSumAdducts -e $outdir/logs/11-runSumAdducts $outdir/jobs/11-runSumAdducts/${scanmode}_\${input}.sh
done

echo "Rscript $scripts/12-collectSamplesAdded.R $outdir $scanmode $scripts" > $outdir/jobs/12-collectSamplesAdded/${scanmode}.sh
qsub -l h_rt=00:30:00 -l h_vmem=8G -N "collect3_$scanmode" -hold_jid "sumAdducts_${scanmode}_*" -m ase -M $email -o $outdir/logs/12-collectSamplesAdded -e $outdir/logs/12-collectSamplesAdded $outdir/jobs/12-collectSamplesAdded/${scanmode}.sh
EOF


  qsub -l h_rt=00:05:00 -l h_vmem=500M -N "queueFinding_${scanmode}" -hold_jid "average" -m as -M $email -o $outdir/logs/queue/2-queuePeakFinding -e $outdir/logs/queue/2-queuePeakFinding $outdir/jobs/queue/2-queuePeakFinding_${scanmode}.sh
}

doScanmode "negative" $thresh_neg "*_neg.RData" "1"
doScanmode "positive" $thresh_pos "*_pos.RData" "1,2"


# start
#qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueStart" -m as -M $email -o $outdir/logs/queue/1-queueStart -e $outdir/logs/queue/1-queueStart $outdir/jobs/1-queueStart.sh
