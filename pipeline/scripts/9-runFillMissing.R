#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

file <- cmd_args[1]
outdir <- cmd_args[2]
scanmode <- cmd_args[3]
thresh  <- as.numeric(cmd_args[4])
resol <- as.numeric(cmd_args[5])
scripts <- cmd_args[6]
ppm <- as.numeric(cmd_args[7])

# file="./results/grouping_rest/negative_1.RData"
# file="./results/grouping_hmdb/1_negative.RData"
# scanmode= "negative"
# scripts="./scripts"
# resol=140000
# thresh=2000
# outdir="./results"

#message(paste(scripts, "AddOnFunctions/replaceZeros.R", sep="/"))

# load in function scripts
source(paste(scripts, "AddOnFunctions/sourceDir.R", sep="/"))
sourceDir(paste(scripts, "AddOnFunctions", sep="/"))

replaceZeros(file,scanmode,resol,outdir,thresh,scripts,ppm)
