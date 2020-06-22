# DIMS
Pipeline that processes raw Direct Mass Spectrometry data.

## Setup GUI
Used R version: 3.6.1 \
Libraries: DT, shiny, shinydashboard, shinyFiles, ssh

- Copy config_default.R to your own config.R, and configure as needed.

## Setup HPC
Used R versions: 3.6.2 and 3.2.2 (which R version is used is found at the top of the main .R scripts) \
Libraries: xcms, Cairo, ggplot2, reshape2, openxlsx, loder

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
- In `/tools`, install mono with GUIX under /mono
- In `/tools`, place the latest tested release of [ThermoRawFileParser](https://github.com/compomics/ThermoRawFileParser/releases/tag/v1.1.11) (v1.1.11) under /ThermoRawFileParser_1.1.11
- In `/tools`, put the required Human Metabolome Database (HMDB) .RData files under /db.


## Usage
The pipeline is meant to be started with the GUI, which is an R shiny program to transfer data to the HPC and start the pipeline. To open the GUI, open GUI.Rproj in Rstudio, which should open run.R and config.R. Then click "Run App" from the run.R file. 

Manually starting the pipeline is also possible.
```
CMD:
  sh run.sh -i <input path> -o <output path> [-r] [-v] [-h]

REQUIRED ARGS:
  -i - full path input folder, eg /hpc/dbg_mz/raw_data/run1
  -o - full path output folder, eg. /hpc/dbg-mz/processed/run1

OPTIONAL ARGS:
  -r - restart the pipeline, removing any existing output for the entered run (default off)
  -v - verbose printing (default off)
  -h - show help

EXAMPLE:
  sh run.sh -i /hpc/dbg_mz/raw_data/run1 -o /hpc/dbg_mz/processed/run1
```

Input folder requirements:
- all the .raw files 
- init.RData (sampelsheet, which contains which technical replicates belong to which biological sample)
- a 'setting.config' file containing eg:
```thresh_pos=2000
thresh_neg=2000
dims_thresh=100
trim=0.1
nrepl=3
normalization=disabled
thresh2remove=1000000000
resol=140000
email=example@example.com
matrix=DBS
db=.../tools/db/HMDB_add_iso_corrNaCl_withIS_withC5OH.RData
db2=.../tools/db/HMDB_with_info_relevance_IS_C5OH.RData
z_score=1```
