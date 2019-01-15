#!/usr/bin/Rscript

run <- function(file, outdir, scanmode, thresh, resol, scripts) {
# file="./results/grouping_rest/negative_1.RData"
# file="./results/grouping_hmdb/1_negative.RData"
# scanmode= "negative"
# scripts="./scripts"
# resol=140000
# thresh=2000
# outdir="./results"

  message(paste(scripts, "AddOnFunctions/replaceZeros.R", sep="/"))

  source(paste(scripts, "AddOnFunctions/replaceZeros.R", sep="/"))
  replaceZeros(file,scanmode,resol,outdir,thresh,scripts)
}

message("\nStart runFillMissing.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], cmd_args[3],  as.numeric(cmd_args[4]), as.numeric(cmd_args[5]), cmd_args[6])

message("Ready runFillMissing.R")
