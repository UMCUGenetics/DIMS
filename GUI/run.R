library("shiny")
library("shinyFiles")
library("shinydashboard")
library("DT")
library("ssh")

cat("Doing application setup\n")

onStop(function() {
  cat("Doing application cleanup\n")
  config <- NULL
  functions <- NULL
  rm(list=ls())
  gc()
  cat("DONE!")
})

### Set workdir to location of this script
setwd(dirname(parent.frame(2)$ofile))

### Clear all variables from memory
rm(list=ls())   

### Source functions and config file
config <- new.env()
functions <- new.env()
source("src/config.R", local=config)
source("src/functions.R", local=functions)

### Recreate tmp dir 
tmp_dir = paste(getwd(), "tmp", sep="/")
unlink(tmp_dir, recursive = TRUE)
dir.create(tmp_dir, showWarnings = FALSE)

### Start
runApp("src")