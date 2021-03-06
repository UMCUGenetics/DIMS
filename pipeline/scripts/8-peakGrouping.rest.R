#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

fileIn <- cmd_args[1]
outdir <- cmd_args[2]
scanmode <- cmd_args[3]
resol <- as.numeric(cmd_args[4])
ppm <- as.numeric(cmd_args[5])

# create output folder
dir.create(paste(outdir, "8-grouping_rest", sep = "/"),showWarnings = F)

options(digits=16)

groupingRest <- function(outdir, fileIn, scanmode, ppm) {
  # fileIn="./results/specpks_all_rest/negative_outlist_i_min_1.1.RData"
  # scanmode="negative"
  # outdir="./results"
  # ppm=2
  
  options(digits=16)
  load(fileIn)
  outlist.copy = outlist_i_min_1
  #batch = strsplit(fileIn, ".",fixed = TRUE)[[1]][3]
  batch = strsplit(fileIn, ".",fixed = TRUE)[[1]][2] 
  load(paste0(outdir, "/repl.pattern.", scanmode, ".RData"))
  # load(paste(outdir, "breaks.fwhm.RData", sep="/"))
  
  outpgrlist = NULL
  
  # Then group on highest peaks
  range = ppm*1e-06
  startcol=7
  
  # while (max(as.numeric(outlist.copy[ , "height.pkt"])) > 0 ) {
  while (dim(outlist.copy)[1] > 0) {
    
    sel = which(as.numeric(outlist.copy[ , "height.pkt"]) == max(as.numeric(outlist.copy[ , "height.pkt"])))[1]
    
    # 3ppm range around max
    mzref = as.numeric(outlist.copy[sel, "mzmed.pkt"])
    pkmin = -(range*mzref - mzref)
    pkmax = 2*mzref-pkmin
    
    selp = as.numeric(outlist.copy[ , "mzmed.pkt"]) > pkmin & as.numeric(outlist.copy[ , "mzmed.pkt"]) < pkmax
    tmplist = outlist.copy[selp,,drop=FALSE]
    
    nrsamples = length(unique(tmplist[,"samplenr"]))
    if (nrsamples > 0) {
      
      mzmed.pgrp = mean(as.numeric(outlist.copy[selp, "mzmed.pkt"]))
      mzmin.pgrp = -(range*mzmed.pgrp - mzmed.pgrp)
      mzmax.pgrp = 2*mzmed.pgrp - mzmin.pgrp
      
      selp = as.numeric(outlist.copy[ , "mzmed.pkt"]) > mzmin.pgrp & as.numeric(outlist.copy[ , "mzmed.pkt"]) < mzmax.pgrp
      tmplist = outlist.copy[selp,,drop=FALSE]
      
      # remove used peaks!!!
      tmp = as.vector(which(tmplist[,"height.pkt"]==-1))
      if (length(tmp)>0) tmplist=tmplist[-tmp,,drop=FALSE]
      
      nrsamples = length(unique(tmplist[,"samplenr"]))
      
      fq.worst.pgrp = as.numeric(max(outlist.copy[selp, "fq"]))
      fq.best.pgrp = as.numeric(min(outlist.copy[selp, "fq"]))
      ints.allsamps = rep(0, length(names(repl.pattern.filtered)))
      names(ints.allsamps) = names(repl.pattern.filtered) # same order as sample list!!!
      
      # Check for each sample if multiple peaks exists, if so take the sum!
      labels=unique(tmplist[,"samplenr"])
      ints.allsamps[labels] = as.vector(unlist(lapply(labels, function(x) {sum(as.numeric(tmplist[which(tmplist[ , "samplenr"]==x), "height.pkt"]))})))
      
      outpgrlist = rbind(outpgrlist, c(mzmed.pgrp, fq.best.pgrp, fq.worst.pgrp, nrsamples, mzmin.pgrp, mzmax.pgrp, ints.allsamps,NA,NA,NA,NA))
    }
    # outlist.copy[selp, "height.pkt"] = -1
    outlist.copy = outlist.copy[-which(selp==TRUE),,drop=FALSE]
  }
  
  outpgrlist = as.data.frame(outpgrlist)  # ignore warnings of duplicate row names
  colnames(outpgrlist)[1:6] = c("mzmed.pgrp", "fq.best", "fq.worst", "nrsamples", "mzmin.pgrp", "mzmax.pgrp")
  colnames(outpgrlist)[(length(repl.pattern.filtered)+7):ncol(outpgrlist)] = c("assi_HMDB", "iso_HMDB", "HMDB_code", "theormz_HMDB")
  
  #save(outpgrlist_part, file=paste(outdir, paste(scanmode, "_", mzstart, "_", mzend, ".RData", sep=""), sep="/"))
  # save(final.outlist.filt, file=paste(outdir, "peak_grouping", paste(scanmode, "_",batch,".RData", sep=""), sep="/"))
  save(outpgrlist, file=paste(outdir, "8-grouping_rest", paste(scanmode, "_",batch,".RData", sep=""), sep="/"))
  
}

cat("File to group: ", fileIn)

groupingRest(outdir, fileIn, scanmode, ppm=ppm)
