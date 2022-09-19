#!/usr/bin/Rscript

# load required packages 
suppressPackageStartupMessages(library("xcms"))

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

filepath <- cmd_args[1] #"/Users/nunen/Documents/Metab/raw_data/test_mzXML/RES_DBS_20180716_01.mzXML"
outdir <- cmd_args[2] #"/Users/nunen/Documents/Metab/3.6.2"
trim <- as.numeric(cmd_args[3]) #0.1
resol <- as.numeric(cmd_args[4]) #14000
nrepl <- as.numeric(cmd_args[5]) #3

trimLeft=NULL
trimRight=NULL
breaks.fwhm=NULL
breaks.fwhm.avg=NULL
bins=NULL
posRes=NULL
negRes=NULL

x <- suppressMessages(xcmsRaw(filepath))

trimLeft = round(x@scantime[length(x@scantime)*trim])
trimRight = round(x@scantime[length(x@scantime)*(1-trim)])
cat(paste("\ntrimLeft", trimLeft, sep=" "))
cat(paste("\ntrimRight", trimRight, sep=" "))

# Mass range m/z
lowMZ = x@mzrange[1]
highMZ = x@mzrange[2]
cat(paste("lowMZ", lowMZ, sep=" "))
cat(paste("highMZ", highMZ, sep=" "))

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
