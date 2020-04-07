#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args = commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

file <- cmd_args[1]
outdir <- cmd_args[2]
scanmode <- cmd_args[3]
adducts <- cmd_args[4]
scripts <- cmd_args[5]
z_score <- as.numeric(cmd_args[6])

load(paste0(outdir, "/repl.pattern.",scanmode, ".RData"))

adducts=as.vector(unlist(strsplit(adducts, ",",fixed = TRUE)))

load(file)
load(paste(outdir, "/10-outlist_identified_", scanmode, ".RData", sep=""))

# Local and on HPC
batch = strsplit(file, "/",fixed = TRUE)[[1]]
batch = batch[length(batch)]
batch = strsplit(batch, ".",fixed = TRUE)[[1]][2]

outlist.tot=unique(outlist.ident)

source(paste(scripts, "AddOnFunctions/sumAdducts.R", sep="/"))
sumAdducts(outlist.tot, outlist_part, names(repl.pattern.filtered), adducts, batch, scanmode, outdir, z_score)

