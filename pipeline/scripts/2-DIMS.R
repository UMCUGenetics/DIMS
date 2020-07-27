#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.6.2")

# load required packages 
suppressPackageStartupMessages(library("xcms"))

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

filepath <- cmd_args[1] #"/Users/nunen/Documents/Metab/raw_data/test_mzXML/RES_DBS_20180716_01.mzXML"
outdir <- cmd_args[2] #"/Users/nunen/Documents/Metab/3.6.2"
trim <- as.numeric(cmd_args[3]) #0.1
dimsThresh <- as.numeric(cmd_args[4]) #100
resol <- as.numeric(cmd_args[5]) #140000

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

x <- suppressMessages(xcmsRaw(filepath))

load(paste(outdir, "breaks.fwhm.RData", sep="/"))

# Create empty placeholders for later use
bins <- rep(0,length(breaks.fwhm)-1)

# Generate a matrix
y <- rawMat(x)

# Get time values for positive and negative scans
posTimes <- x@scantime[x@polarity == "positive"]
negTimes <- x@scantime[x@polarity == "negative"]
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
