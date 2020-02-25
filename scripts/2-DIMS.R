#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(xmlfile, outdir, trim, dimsThresh, resol, scripts) {
  
  dir.create(paste(outdir, "pklist", sep = "/"), showWarnings = F)
  #dir.create(paste(outdir, "QC", sep="/"),showWarnings = F)
  
  sampname <- strsplit(xmlfile, "/")[[1]]
  sampname <- sampname[length(sampname)]
  sampname <- strsplit(sampname, ".mzXML")[[1]][1]
  print(sampname)
  
  suppressPackageStartupMessages(library("xcms"))
  suppressPackageStartupMessages(library("Cairo"))
  options(digits=16)
  
  ### process one sample at a time and find peaks FOR BOTH SCAN MODES! #
  int.factor=1*10^5 # Number of x used to calc area under Gaussian (is not analytic)
  scale=2 # Initial value used to estimate scaling parameter
  width=1024
  height=768
  
  source(paste(scripts, "AddOnFunctions/sourceDir.R", sep="/"))
  sourceDir(paste(scripts, "AddOnFunctions", sep="/"))
  
  # ########################### QC #################################################
  # rawCtrl = xcmsRaw(xmlfile, profstep=0.01)
  #
  # # rawCtrl = tryCatch(
  # #   { xcmsRaw(xmlfile, profstep=0.01)
  # #   }
  # #   , error = function(e) {
  # #     message(paste("CATCHED", e))
  # #     save(pklist=NULL, file=paste(paste(outdir, "pklist", sep="/"),"/", sampname, ".RData", sep=""))
  # #   })
  #
  # if (class(rawCtrl) == "try-error") {
  #   message(paste("Bad file:", xmlfile))
  # }
  #
  # # extract sample name
  # tmp=unlist(strsplit(xmlfile, "/",fixed = T))[3]
  # sample=unlist(strsplit(tmp, ".",fixed = T))[1]
  # samples=c(samples, sample)
  #
  # CairoPNG(filename=paste(paste(outdir, "QC/raw/TIC", sep="/"), paste(sample, "png", sep="."), sep="/"), width, height)
  # plotTIC(rawCtrl, ident=TRUE, msident=TRUE) # waits for mouse input; hit Esc
  # dev.off()
  #
  # CairoPNG(filename=paste(paste(outdir, "QC/raw/BPC", sep="/"), paste(sample, "png", sep="."), sep="/"), width, height)
  # plot(rawCtrl@scantime,apply(rawCtrl@env$profile,2,max),type="l", main="Base peak chromatogram")
  # dev.off()
  # ################################################################################
  
  # Aggregate with dims scipt
  cat("making pklist...\n")
  pklist = dims(xmlfile, outdir, dimsThresh, trim, resol)
  cat("pklist created\n")
  save(pklist, file=paste(paste(outdir, "pklist", sep="/"),"/", sampname, ".RData", sep=""))
  
}

cat("Start DIMS.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], as.numeric(cmd_args[3]), as.numeric(cmd_args[4]), as.numeric(cmd_args[5]), cmd_args[6])

cat("Ready DIMS.R")
