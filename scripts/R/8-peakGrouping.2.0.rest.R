#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(fileIn, outdir, scanmode, resol, scriptDir) {
  # rdata="./results/specpks_all_rest/negative_outlist_i_min_1.9.RData"
  # scriptDir="./scripts"
  # outdir="./results"
  # scanmode="negative"

  dir.create(outdir,showWarnings = F)
  dir.create(paste(outdir, "grouping_rest", sep="/"),showWarnings = F)

  options(digits=16)

  source(paste(scriptDir, "AddOnFunctions/sourceDir.R", sep="/"))
  sourceDir(paste(scriptDir, "AddOnFunctions", sep="/"))

  #message(paste("File to group:", fileIn))

  groupingRest(outdir, fileIn, scanmode)

}

cat("Start peakGrouping.2.0.rest.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], cmd_args[3], as.numeric(cmd_args[4]), cmd_args[5])

cat("Ready peakGrouping.2.0.rest.R")
