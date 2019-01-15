#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(file, outdir, scanmode, adducts, scripts) {

  load(paste0(outdir, "/repl.pattern.",scanmode, ".RData"))

  adducts=as.vector(unlist(strsplit(adducts, ",",fixed = TRUE)))

  load(file)
  load(paste(outdir, "/outlist_identified_", scanmode, ".RData", sep=""))

  # Local and on HPC
  batch = strsplit(file, "/",fixed = TRUE)[[1]]
  batch = batch[length(batch)]
  batch = strsplit(batch, ".",fixed = TRUE)[[1]][2]

  outlist.tot=unique(outlist.ident)

  source(paste(scripts, "AddOnFunctions/sumAdducts.R", sep="/"))
  sumAdducts(outlist.tot, outlist_part, names(repl.pattern.filtered), adducts, batch, scanmode, outdir)
}

message("\nStart runSumAdducts.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], cmd_args[3], cmd_args[4], cmd_args[5])

message("Ready runSumAdducts.R")
