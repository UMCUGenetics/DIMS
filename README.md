# DIMS
Repository for diagnostic pipeline metabolomics using Direct Mass Spectrometry data.

## Setup
### Main scripts
- Install [GIT](https://git-scm.com/downloads). 
- Create the following folders in the same root map (eg. /hpc/dbg_mz)
  - `/development`
  - `/processed`
  - `/production`
  - `/raw_data`
  - `/tools`
- In `/development`, clone the dev branch of the DIMS repo. 
```
git clone -b dev --single-branch git@github.com:UMCUGenetics/DIMS.git
```
- In `/production`, clone the master branch of the DIMS repo.
```
git clone -b master --single-branch git@github.com:UMCUGenetics/DIMS.git
```

### Tools
- In `/tools`, install the [Proteowizard Docker](https://hub.docker.com/r/chambm/pwiz-skyline-i-agree-to-the-vendor-licenses) with [Singularity](https://singularity.lbl.gov/).
```
export SINGULARITY_CACHEDIR=/hpc/dbg_mz/tools/.singularity/
export SINGULARITY_TMPDIR=/hpc/dbg_mz/tools/.singularity/tmp
export SINGULARITY_LOCALCACHEDIR=/hpc/dbg_mz/tools/.singularity/tmp
export SINGULARITY_PULLFOLDER=/hpc/dbg_mz/tools/.singularity/pull
export SINGULARITY_BINDPATH=/hpc/dbg_mz/tools
export WINEDEBUG=-all
singularity build --sandbox proteowizard_3.0.19056-6b6b0a2b4/ docker://chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.19056-6b6b0a2b4
```
- In `/tools`, put the required Human Metabolome Database (HMDB) .RData files under /db.

## Usage

You generally wanna use the DIMS pipeline in combination with the [DIMS GUI](https://github.com/UMCUGenetics/DIMS_GUI/), which is an R shiny program to transfer data to the HPC and start the pipeline. However, manually starting the pipeline is also possible.
  ```
run.sh -i <input path> -o <output path> [-r] [-v] [-h]

REQUIRED ARGS:
  -i - full path input folder, eg /hpc/dbg_mz/raw_data/run1
  -o - full path output folder, eg. /hpc/dbg-mz/processed/run1

OPTIONAL ARGS:
  -r - restart the pipeline, removing any existing output for the entered run (default off)
  -v - verbose printing (default off)
  -h - show help

EXAMPLE:
  sh run.sh -i /hpc/dbg_mz/raw_data/run1 -o /hpc/dbg_mz/processed/run1$```
