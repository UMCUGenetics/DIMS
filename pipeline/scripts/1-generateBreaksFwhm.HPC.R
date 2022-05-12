#!/usr/bin/Rscript

#.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")
suppressPackageStartupMessages(library(mzR))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(stringr))
# load required packages 
#suppressPackageStartupMessages(library(xcms))

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

filepath <- cmd_args[1] #"/Users/nunen/Documents/Metab/raw_data/test_mzXML/RES_DBS_20180716_01.mzXML"
outdir <- cmd_args[2] #"/Users/nunen/Documents/Metab/3.6.2"
trim <- as.numeric(cmd_args[3]) #0.1
resol <- as.numeric(cmd_args[4]) #14000
nrepl <- as.numeric(cmd_args[5]) #3
stitch <- as.numeric(cmd_args[7]) #1
trimLeft=NULL
trimRight=NULL
breaks.fwhm=NULL
breaks.fwhm.avg=NULL
bins=NULL
posRes=NULL
negRes=NULL
TrimlowerMZrange<-function(hdr){
  for(i in 1:length(hdr$scanWindowLowerLimit)){
    #if (70%in%hdr$scanWindowLowerLimit[[i]]){print('Lowerlimit of current scan is 70')}
    if (hdr$scanWindowLowerLimit[[i]]==min(hdr$scanWindowLowerLimit)) {cat('Lowerlimit has reached:', hdr$scanWindowLowerLimit[[i]])}
    else{hdr$scanWindowLowerLimit[[i]]<-hdr$scanWindowLowerLimit[[i]]+5}
    
  } 
  return(hdr)
}    


#Trims the MZ range in header file (upper scan window limit)
TrimupperMZrange<-function(hdr){
  for(i in 1:length(hdr$scanWindowUpperLimit)){
    #if (1280%in%hdr$scanWindowUpperLimit[[i]]){print('Upperlimit of current scan is 1280')}
    if (hdr$scanWindowUpperLimit[[i]]==max(hdr$scanWindowUpperLimit)) {cat('Upperlimit has reached:', hdr$scanWindowUpperLimit[[i]])}  
    else{hdr$scanWindowUpperLimit[[i]]<-hdr$scanWindowUpperLimit[[i]]-5}
  } 
  return(hdr)
}   

#replace FTMS + p filterstring to correct mz-range
Replace_FTMS<-function(hdr){
  for(i in 1:length(hdr$filterString)){
    hdr$filterString[i]<-str_replace(hdr$filterString[i],"(?<=\\[)\\d+", toString(hdr$scanWindowLowerLimit[i]))
  } 
  return(hdr)
}   

# replace FTMS + upper mz
Replace_FTMShigh<-function(hdr){
  for(i in 1:length(hdr$filterString)){
    hdr$filterString[i]<-str_replace(hdr$filterString[i],"(?<=\\-)\\d+", toString(hdr$scanWindowUpperLimit[i]))
  } 
  return(hdr)
} 

#Removes all peaks outside of the scanwindow lower limit
TrimPeaklistlower<-function(pks, hdr){
  for (i in 1:length(pks)) { 
    #a<-hdr$scanWindowLowerLimit[i]
    #print(a)
    x<-which(pks[[i]][,1]<hdr$scanWindowLowerLimit[i],arr.ind = TRUE)
    #print(x)
    if(length(x)!=0) {pks[[i]]<-pks[[i]][-x,]}
  }
  return(pks)
  #return(hdr)
}

#Removes all peaks outside of the scanwindow upper limit
TrimPeaklistupper<-function(pks, hdr){
  for (i in 1:length(pks)) {
    #b<-hdr$scanWindowUpperLimit[i]
    #print(b)
    y<-which(pks[[i]][,1]<hdr$scanWindowUppperLimit[i],arr.ind = TRUE)
    #print(y)
    if(length(y)!=0) {pks[[i]]<-pks[[i]][-y,]}
  } 
  return(pks)
  #return(hdr)
}

#Replaces the peakcount, lowMZ and HighMZ in the header file based on the new peaklist
Replace_low_high_MZ_and_pkCount<-function(hdr, pks){ 
  for (i in 1:length(pks)) {
    hdr$peaksCount[[i]] <-length(pks[[i]][,1]) 
    hdr$lowMZ[[i]]<-min(pks[[i]][,1])
    hdr$highMZ[[i]]<-max(pks[[i]][,1])
  }
  return(hdr)
}
Dat <- openMSfile(filepath)

hdr <- header(Dat)
pks <- spectra(Dat)
hdr <- TrimlowerMZrange(hdr)
hdr <- TrimupperMZrange(hdr)
hdr <- Replace_FTMS(hdr)
hdr <- Replace_FTMShigh(hdr)
pks <- TrimPeaklistlower(pks, hdr)
pks <- TrimPeaklistupper(pks, hdr)
hdr <- Replace_low_high_MZ_and_pkCount(hdr, pks)

#x <- readMSData(filepath, mode = "onDisk", msLevel. = 1)
#trimLeft = round(x@featureData@data[["retentionTime"]][length(x@featureData@data[["retentionTime"]])*trim])
#trimRight = round(x@featureData@data[["retentionTime"]][length(x@featureData@data[["retentionTime"]])*(1-trim)])
if (stitch==1){
  trimLeft = round(hdr$retentionTime[2]+0.5)
  trimRight = round(hdr$retentionTime[length(hdr$retentionTime)-1]-0.5)
} else {
  trimLeft = round(hdr$retentionTime[length(hdr$retentionTime)*trim])
  trimRight = round(hdr$retentionTime[length(hdr$retentionTime)*(1-trim)])
}
cat(paste("\ntrimLeft", trimLeft, sep=" "))
cat(paste("\ntrimRight", trimRight, sep=" "))

# Mass range m/z
#lowMZ = round(x@featureData@data[["lowMZ"]][1])
#highMZ = round(x@featureData@data[["highMZ"]][1])
lowMZ = round(min(hdr$lowMZ))
highMZ = round(max(hdr$highMZ))
#trimLeft = round(x@scantime[length(x@scantime)*trim])
#trimRight = round(x@scantime[length(x@scantime)*(1-trim)])
#cat(paste("\ntrimLeft", trimLeft, sep=" "))
#cat(paste("\ntrimRight", trimRight, sep=" "))

# Mass range m/z
#lowMZ = x@mzrange[1]
#highMZ = x@mzrange[2]
#cat(paste("lowMZ", lowMZ, sep=" "))
#cat(paste("highMZ", highMZ, sep=" "))

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

#writeMSData(object = pks, file = filepath, hdr)

save(breaks.fwhm,breaks.fwhm.avg,trimLeft,trimRight,file=paste(outdir, "breaks.fwhm.RData", sep="/"))
