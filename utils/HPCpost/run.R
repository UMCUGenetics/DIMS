library("shiny")
suppressPackageStartupMessages(library("shinyjs"))
library("shinyFiles")
library("ssh")

### Set workdir to this dir
this.dir <- dirname(parent.frame(2)$ofile)
setwd(this.dir)

### Connect to HPC
ssh <- ssh_connect("nvanunen@hpcsubmit.op.umcutrecht.nl")
print(ssh)

### Default mail
mail = "n.vanunen@umcutrecht.nl"

### Root for raw data file selector  
#root = "/Users/nunen/Documents/GitHub/Dx_metabolomics/raw_data"
#root = "C:/Xcalibur/data/Research"
root = "Y:/Metabolomics/DIMS_pipeline/R_workspace_NvU"

### Root for experimental design file selector 
#root2 = "/Users/nunen/Documents/GitHub/Dx_metabolomics/raw_data"
#root2 = "Y:/Metabolomics/Research Metabolomic Diagnostics/Metabolomics Projects"
root2 = root

### Source functions
source("./dims/HPCPostFunctions.R")
df = NULL

### Recreate tmp dir 
tmpDir = paste(getwd(), "tmp", sep="/")
unlink(tmpDir, recursive = TRUE)
dir.create(tmpDir, showWarnings = FALSE)

### Start
runApp("dims")