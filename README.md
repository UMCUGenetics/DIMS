# DIMS
Pipeline that processes raw Direct Infusion Mass Spectrometry data.

### Folder Structure
```
.
|───CustomModules/ (GitHub repo with pipeline scripts)
|───assests/ (extra Nextflow files)
|───db/ (Human Metabolome Database files)
```

## Docker image 
```
docker build -t ghcr.io/umcugenetics/[NAME]:[tag] .
docker push ghcr.io/umcugenetics/[NAME]:[tag]
```

on HPC: 
```
srun -c 2 -t 0:30:00 -A dbg_mz --mem=100G --gres=tmpspace:100G --pty /usr/bin/bash 
cd /hpc/dbg_mz/tools/singularity_cache/ 
singularity build /hpc/dbg_mz/tools/MAP/NAME.img docker://ghcr.io/umcugenetics/[NAME]:[tag]
```

## Setup HPC
Used R version: 4.1.0 \
Libraries: xcms, stringr, dplyr, Rcpp, openxlsx, reshape2, loder, ggplot2, gridExtra 

- Create the following folders in the same root map (e.g. /hpc/dbg_mz)
  - `/development`
  - `/processed`
  - `/production`
  - `/raw_data`
  - `/tools`
- In `/development`, clone the dev branch of the DIMS repo. 
```
git clone -b develop --single-branch git@github.com:UMCUGenetics/DIMS.git
cd DIMS
git submodule update --init --recursive
```
- In `/production`, clone the master branch of the DIMS repo.
```
git clone -b master --single-branch git@github.com:UMCUGenetics/DIMS.git
cd DIMS
git submodule update --init --recursive
```
- In `/tools`, install [mono](https://www.mono-project.com/) with [GUIX](https://guix.gnu.org/) under /mono
- In `/tools`, place the latest tested release of [ThermoRawFileParser](https://github.com/compomics/ThermoRawFileParser/releases/tag/v1.1.11) (v1.1.11) under /ThermoRawFileParser_1.1.11
- In `/tools`, put the required Human Metabolome Database (HMDB) .RData files under /db.


## Usage
The pipeline can be started with a GUI, which is an R shiny program to transfer data to the HPC and start the pipeline. The GUI access can only be used when someone has access. To get access contact the bioinformaticians. 

Manually starting the pipeline is also possible.
```
CMD:
/hpc/dbg_mz/production/DIMS/run_nextflow_dims.sh -i <input path> -o <output path> -e <email> -s <samplesheet> -n <nr_replicates> -r <resolution> -p <ppm> -z <zscore> -m <matrix> -t <standard_run> [-v] [-h]

REQUIRED ARGS:
    -i - full path input folder, eg /hpc/dbg_mz/raw_data/run1 (required)
    -o - full path output folder, eg. /hpc/dbg_mz/processed/run1 (required)
    -e - emailadress, eg. user@umcutrecht.nl (required)
    -s - samplesheet, eg. sampleNames.txt (required)
    -n - number of replicates, eg. 2 (required)
    -r - resolution, eg. 140000 (required)
    -p - ppm, eg. 5 (required)
    -z - zscore, 1 for Z-score and 0 for no Z-score (required)
    -m - matrix, eg. Plasma (required)
    -t - standard run, yes or no (required)

OPTIONAL ARGS:
  -v - verbose printing (default off)
  -h - show help

EXAMPLE:
  /hpc/dbg_mz/production/DIMS/run_nextflow_dims.sh -i /hpc/dbg_mz/raw_data/run1 -o /hpc/dbg_mz/processed/run1$ -e user@umcutrecht.nl -s sampleNames.txt -n 2 -r 140000 -p 5 -z 1 -m Plasma -t yes
```

Input folder requirements:
- all the .raw files 
- text file with all samples and their raw files, e.g. sampleNames.txt

