#!/usr/bin/Rscript

#.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.6.2")

# load required packages 
suppressPackageStartupMessages(library("mzR"))
suppressPackageStartupMessages(library("dplyr"))
suppressPackageStartupMessages(library("stringr"))

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

filepath <- cmd_args[1] #"/Users/nunen/Documents/Metab/raw_data/test_mzXML/RES_DBS_20180716_01.mzXML"
outdir <- cmd_args[2] #"/Users/nunen/Documents/Metab/3.6.2"
trim <- as.numeric(cmd_args[3]) #0.1
dimsThresh <- as.numeric(cmd_args[4]) #100
resol <- as.numeric(cmd_args[5]) #140000
stitch <- 1 #0
dir.create(paste(outdir, "2-pklist", sep = "/"), showWarnings = F)
#dir.create(paste(outdir, "QC", sep="/"),showWarnings = F)

sampname <- sub('\\..*$', '', basename(filepath))
cat(paste0("\n",sampname))

#suppressPackageStartupMessages(library("Cairo"))
options(digits=16)

### process one sample at a time and find peaks FOR BOTH SCAN MODES! #
int.factor=1*10^5 # Number of x used to calc area under Gaussian (is not analytic)
scale=2 # Initial value used to estimate scaling parameter
width=1024
height=768

# ########################### QC #################################################
# rawCtrl = xcmsRaw(filepath, profstep=0.01)
#
# # rawCtrl = tryCatch(
# #   { xcmsRaw(filepath, profstep=0.01)
# #   }
# #   , error = function(e) {
# #     message(paste("CATCHED", e))
# #     save(pklist=NULL, file=paste(paste(outdir, "pklist", sep="/"),"/", sampname, ".RData", sep=""))
# #   })
#
# if (class(rawCtrl) == "try-error") {
#   message(paste("Bad file:", filepath))
# }
#
# # extract sample name
# tmp=unlist(strsplit(filepath, "/",fixed = T))[3]
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

# Aggregate

trimLeft=NULL
trimRight=NULL
breaks.fwhm=NULL
breaks.fwhm.avg=NULL
bins=NULL
posRes=NULL
negRes=NULL

#x <- suppressMessages(xcmsRaw(filepath))
#Dat<-openMSfile(filepath)
#hdr=header(Dat)
#pks=peaks(Dat)

### functions for stitching

#Trims the MZ-range in header file (lower scan window limit) 
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


#x <- suppressMessages(xcmsRaw(filepath))
Dat<-openMSfile(filepath)
hdr <- header(Dat)
pks <- spectra(Dat)
hdr <- TrimlowerMZrange(hdr)
hdr <- TrimupperMZrange(hdr)
hdr <- Replace_FTMS(hdr)
hdr <- Replace_FTMShigh(hdr)
pks <- TrimPeaklistlower(pks, hdr)
pks <- TrimPeaklistupper(pks, hdr)
hdr <- Replace_low_high_MZ_and_pkCount(hdr, pks)

#



load(paste(outdir, "breaks.fwhm.RData", sep="/"))

# Create empty placeholders for later use
bins <- rep(0,length(breaks.fwhm)-1)

# Generate a matrix
#y <- rawMat(x)
times <- hdr$retentionTime
y_proxybig <- NA
t = NULL
length(pks)
for (i in 1:length(pks)) {
  t = times[i]
  this_scan <- pks[[i]]
  l <- length(this_scan[,1])
  time <- rep(t, l)
  #print(paste0("length:",l," = ",length(time)))
  this_scan <- cbind(time, this_scan)
  colnames(this_scan) <- c("time", "mz", "intensity")
  if (i==1) { y_proxybig <- this_scan } else{ y_proxybig <- rbind(y_proxybig, this_scan) }
}
y <- y_proxybig


# Get time values for positive and negative scans
posTimes <- hdr$retentionTime[hdr$polarity==1]
negTimes <- hdr$retentionTime[hdr$polarity==0]
if (stitch==1){
  trimLeft = round(hdr$retentionTime[2]+0.5)
  trimRight = round(hdr$retentionTime[length(hdr$retentionTime)-1]-0.5)
} else {
  trimLeft = round(hdr$retentionTime[length(hdr$retentionTime)*trim])
  trimRight = round(hdr$retentionTime[length(hdr$retentionTime)*(1-trim)])
}
#posTimes <- x@scantime[x@polarity == "positive"]
#negTimes <- x@scantime[x@polarity == "negative"]
# Select scans where sample is present
posTimes <- posTimes[posTimes > trimLeft & posTimes < trimRight]
negTimes <- negTimes[negTimes > trimLeft & negTimes < trimRight]


# Generate an index with which to select values for each mode
posInd <- which(y[,"time"] %in% posTimes)
negInd <- which(y[,"time"] %in% negTimes)
# Separate each mode into its own matrix
posY <- y[posInd,]
negY <- y[negInd,]

# Get index for binning intensity values
## This doesn't round the value for mz - is this an issue?
yp <- cut(posY[,"mz"], breaks.fwhm, include.lowest=TRUE, right=TRUE, labels=FALSE)
yn <- cut(negY[,"mz"], breaks.fwhm, include.lowest=TRUE, right=TRUE, labels=FALSE)

#     Z <- seq(from=1, to=10, by=0.5)
#     cut(Z, breaks = 1:10, include.lowest=TRUE, right=TRUE, labels=FALSE)

# Empty the bins
posBins<-bins
negBins<-bins

# Get the list of intensity values for each bin, and add the
# intensity values which are in the same bin
if (nrow(posY) > 0) {
  #       ap <- aggregate(posY[,"intensity"],list(yp),sum)
  #       posBins[ap[,1]] <- posBins[ap[,1]] + ap[,2] / length(posTimes)
  ap <- aggregate(posY[,"intensity"],list(yp), FUN = function(x){if (is.na(mean(x[which(x>dimsThresh)]))){
    0 
  } else {
    mean(x[which(x>dimsThresh)])
  }})
  posBins[ap[,1]] <- ap[,2]
  
}
if (nrow(negY) > 0) {
  #       an <- aggregate(negY[,"intensity"],list(yn),sum)
  #       negBins[an[,1]] <- negBins[an[,1]] + an[,2] / length(negTimes)
  an <- aggregate(negY[,"intensity"],list(yn), FUN = function(x){if (is.na(mean(x[which(x>dimsThresh)]))){
    0 
  } else {
    mean(x[which(x>dimsThresh)])
  }})
  negBins[an[,1]] <- an[,2]
}

# Zero any values that are below the threshold
posBins[posBins < dimsThresh] <- 0
negBins[negBins < dimsThresh] <- 0

posRes = cbind(posRes, posBins)
negRes = cbind(negRes, negBins)
# }

#which(posRes[,3]!=0)
posRes = t(posRes)
negRes = t(negRes)

# Add in file names as row names
rownames(posRes) = sampname
rownames(negRes) = sampname

# Add 0.5 to the values in breaks.fwhm, and delete the last value
a <- breaks.fwhm.avg[-length(breaks.fwhm.avg)]  # + 0.5*deltaMZ

# Format as string and show precision of float to 2 digits
b <- sprintf("%.5f",a)

# Use this as the column names
colnames(posRes) <- b
colnames(negRes) <- b

# omit rows with only zeros
posResT <- t(posRes)
#  sumsp <- apply(posResT,1,sum)
#  posResT.nonzero <- posResT[(sumsp != 0), ] # <=============================================!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
negResT <- t(negRes)
#  sums <- apply(negResT,1,sum)
#  negResT.nonzero <- negResT[(sums != 0), ] # <=============================================!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

pklist <- list("pos"=posResT,"neg"=negResT, "breaksFwhm"=breaks.fwhm)

save(pklist, file=paste(paste(outdir, "2-pklist", sep="/"),"/", sampname, ".RData", sep=""), version = 2)
writeMSData(object = pks, file = paste0(outdir, "/1-data/", sampname, "_St.mzML"), hdr)