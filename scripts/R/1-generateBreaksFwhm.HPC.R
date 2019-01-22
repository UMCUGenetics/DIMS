#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(xmlfile, outdir, trim, resol, nrepl) {
  trimLeft=NULL
  trimRight=NULL
  breaks.fwhm=NULL
  breaks.fwhm.avg=NULL
  bins=NULL
  posRes=NULL
  negRes=NULL

  library("xcms")

  dir.create(outdir, showWarnings = F)

  x = NULL
  try({x = xcmsRaw(xmlfile)}, silent = TRUE)
  if (is.null(x)){
    return(NULL)
  }

  trimLeft = round(x@scantime[length(x@scantime)*trim])
  trimRight = round(x@scantime[length(x@scantime)*(1-trim)])
  message(paste("trimLeft", trimLeft, sep=" "))
  message(paste("trimRight", trimRight, sep=" "))

  # Mass range m/z
  lowMZ = x@mzrange[1]
  highMZ = x@mzrange[2]
  message(paste("lowMZ", lowMZ, sep=" "))
  message(paste("highMZ", highMZ, sep=" "))

  # breaks.fwhm <- seq(from=lowMZ, to=highMZ, by=deltaMZ)
  # breaks has fixed distance between min and max of a bin.
  # better if this distance were a function of fwhm=f(mz)
  #segment <- seq(from=lowMZ, to=highMZ, length.out=1001)
  nsegment = 2*(highMZ-lowMZ)
  segment = seq(from=lowMZ, to=highMZ, length.out=nsegment+1)
  breaks.fwhm=NULL
  breaks.fwhm.avg=NULL
  # for (i in 1:2) {
  for (i in 1:nsegment) {
    startsegm <- segment[i]
    endsegm <- segment[i+1]
    resol.mz <- resol*(1/sqrt(2)^(log2(startsegm/200)))
    fwhmsegm <- startsegm/resol.mz
    breaks.fwhm <- c(breaks.fwhm, seq(from=(startsegm+fwhmsegm),to=endsegm, by=0.2*fwhmsegm))
    #breaks.fwhm <- c(breaks.fwhm, seq(from=(startsegm), to=endsegm, by=0.2*fwhmsegm))

    # average the m/z instead of start value
    range = seq(from=(startsegm+fwhmsegm),to=endsegm, by=0.2*fwhmsegm)
    deltaMZ = range[2]-range[1]
    breaks.fwhm.avg <- c(breaks.fwhm.avg, range + 0.5 * deltaMZ)

  }

  save(breaks.fwhm,breaks.fwhm.avg,trimLeft,trimRight,file=paste(outdir, "breaks.fwhm.RData", sep="/"))
}


cat("Start generateBreaksFwhm.HPC.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], as.numeric(cmd_args[3]), as.numeric(cmd_args[4]), as.numeric(cmd_args[5]))

cat("Ready generateBreaksFwhm.HPC.R")
