library("shiny")
library("shinyFiles")
suppressPackageStartupMessages(library("shinyjs"))

### Set workdir to location of this script
setwd(dirname(parent.frame(2)$ofile))

### Source functions and config file
source("dims/config.R")
source("dims/HPCPostFunctions.R")
df = NULL

### Recreate tmp dir 
tmpDir = paste(getwd(), "tmp", sep="/")
unlink(tmpDir, recursive = TRUE)
dir.create(tmpDir, showWarnings = FALSE)

### Start
runApp("dims")