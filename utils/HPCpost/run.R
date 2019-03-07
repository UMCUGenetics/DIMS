library("shiny")
library("shinyjs")
library("shinyFiles")
library("ssh")

### Connect to HPC
ssh <- ssh_connect("nvanunen@hpcsubmit.op.umcutrecht.nl")
print(ssh)

### Default mail
mail = "n.vanunen@umcutrecht.nl"

### Root for raw data file selector  
root = "/Users/nunen/Documents/GitHub/Dx_metabolomics/raw_data"

### Root for experimental design file selector 
root2 = "/Users/nunen/Documents/GitHub/Dx_metabolomics/raw_data"

### Source functions
source("./dims/HPCPostFunctions.R")

### Recreate tmp dir 
tmpDir = paste(getwd(), "tmp", sep="/")
unlink(tmpDir, recursive = TRUE)
dir.create(tmpDir, showWarnings = FALSE)

### Start
runApp("dims")