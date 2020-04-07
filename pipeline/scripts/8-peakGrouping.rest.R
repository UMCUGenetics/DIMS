#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args = commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

fileIn <- cmd_args[1]
outdir <- cmd_args[2]
scanmode <- cmd_args[3]
resol <- as.numeric(cmd_args[4])
scriptDir <- cmd_args[5]

# rdata="./results/specpks_all_rest/negative_outlist_i_min_1.9.RData"
# scriptDir="./scripts"
# outdir="./results"
# scanmode="negative"

dir.create(outdir, showWarnings = F)
dir.create(paste(outdir, "8-grouping_rest", sep = "/"),showWarnings = F)

options(digits=16)

source(paste(scriptDir, "AddOnFunctions/sourceDir.R", sep = "/"))
sourceDir(paste(scriptDir, "AddOnFunctions", sep = "/"))

#message(paste("File to group:", fileIn))

groupingRest(outdir, fileIn, scanmode)
