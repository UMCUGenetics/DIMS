#!/usr/bin/Rscript

#.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

outdir <- cmd_args[1]
scanmode <- cmd_args[2]
  

object.files = list.files(paste(outdir, "11-adductSums", sep="/"), full.names=TRUE, pattern=paste(scanmode, "_", sep=""))

outlist.tot=NULL
for (i in 1:length(object.files)) {
  load(object.files[i])
  outlist.tot = rbind(outlist.tot, adductsum)
}

save(outlist.tot, file=paste0(outdir, "/adductSums_", scanmode, ".RData"))
