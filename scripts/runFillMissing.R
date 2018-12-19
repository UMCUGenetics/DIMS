.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")
run <- function(file, scanmode, resol, outdir, thresh, scripts) {
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

message("Start")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], as.numeric(cmd_args[3]), cmd_args[4], as.numeric(cmd_args[5]), cmd_args[6])

message("Ready")
