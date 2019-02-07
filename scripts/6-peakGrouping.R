#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(fileIn, outdir, scanmode, resol, scriptDir) {

  options(digits=16)

  source(paste(scriptDir, "AddOnFunctions/sourceDir.R", sep="/"))
  sourceDir(paste(scriptDir, "AddOnFunctions", sep="/"))

  cat(paste("File to group:", fileIn))

  # load(paste(outdir, "repl.pattern.RData", sep="/"))
  # if (scanmode=="negative") {
  #   sampleNames=groupNames.neg
  # } else {
  #   sampleNames=groupNames.pos
  # }
  #
  # peak.grouping.Gauss.HPC(outdir, fileIn, scanmode, resol, sampleNames)
  # groupingAndIdent(outdir, fileIn, scanmode)
  groupingOnHMDB(outdir, fileIn, scanmode)

}

cat("Start peakGrouping.2.0.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], cmd_args[3], as.numeric(cmd_args[4]), cmd_args[5])

cat("Ready peakGrouping.2.0.R")
