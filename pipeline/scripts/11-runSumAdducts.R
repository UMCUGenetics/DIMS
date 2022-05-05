#!/usr/bin/Rscript

#.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

file <- cmd_args[1]
outdir <- cmd_args[2]
scanmode <- cmd_args[3]
adducts <- cmd_args[4]
z_score <- as.numeric(cmd_args[5])

# create output folder
dir.create(paste(outdir, "11-adductSums", sep="/"), showWarnings = FALSE)

load(paste0(outdir, "/repl.pattern.",scanmode, ".RData"))

adducts=as.vector(unlist(strsplit(adducts, ",",fixed = TRUE)))

load(file)
load(paste(outdir, "/outlist_identified_", scanmode, ".RData", sep=""))

# Local and on HPC
batch = strsplit(file, "/",fixed = TRUE)[[1]]
batch = batch[length(batch)]
batch = strsplit(batch, ".",fixed = TRUE)[[1]][2]

outlist.tot=unique(outlist.ident)

sumAdducts <- function(peaklist, theor.MZ, grpnames.long, adducts, batch, scanmode, outdir, z_score){
  #theor.MZ = outlist_part
  #grpnames.long = names(repl.pattern.filtered)
  #peaklist = outlist.ident
  #adducts = c(1) #for neg or c(1,2) for pos
  #batch <- 300
  #outdir <- "/Users/nunen/Documents/Metab/processed/zebrafish"
  #scanmode <- "negative"
  #z_score <- 0
  
  hmdb_codes <- rownames(theor.MZ)
  hmdb_names <- theor.MZ[,1, drop=FALSE]
  hmdb_names[] <- lapply(hmdb_names, as.character)
  
  # remove isotopes!!!
  index <- grep("HMDB",hmdb_codes,fixed=TRUE)
  hmdb_codes <- hmdb_codes[index]
  hmdb_names <- hmdb_names[index,]
  index = grep("_",rownames(hmdb_codes),fixed=TRUE)
  if (length(index)>0) hmdb_codes = hmdb_codes[-index]
  if (length(index)>0) hmdb_names = hmdb_names[-index]
  
  #i=which(hmdb_codes=="HMDB41792")
  
  # negative
  names=NULL
  adductsum=NULL
  names_long=NULL
  
  if (length(hmdb_codes)!=0) {
    
    # assign("last.warning", NULL, envir = baseenv())
    # result = tryCatch(
    #   {
    
    for(i in 1:length(hmdb_codes)){
      # for(i in 1:10){
      
      #compound="HMDB00045"
      compound=hmdb_codes[i]
      compound_plus=c(compound,paste(compound, adducts, sep = "_"))
      
      # x=peaklist$HMDB_code[1]
      metab=unlist(lapply(peaklist$HMDB_code, function(x) {(length(intersect(unlist(strsplit(as.vector(x),";")),compound_plus))>0)}))
      # peaklist[metab, "assi.hmdb"]
      # which(metab==TRUE)
      
      #if (length(which(metab==TRUE))>0) message("Bingo found something")
      
      total=c()
      
      # peaklist[metab, c("mzmed.pgrp", "HMDB_code", "C34.1")]
      # ints=peaklist[metab, c(7:(length(grpnames.long)+6))]
      if (z_score == 1) {
        ints=peaklist[metab, c(15:(length(grpnames.long)+14))]
      } else {
        ints=peaklist[metab, c(7:(length(grpnames.long)+6))]
      }
      total=apply(ints, 2, sum)
      
      if (sum(total)!=0) {
        #message(i)
        names = c(names, compound)
        adductsum<-rbind(adductsum,total)
        names_long = c(names_long, hmdb_names[i])
      }
    }
    
    # }
    # , warning=function(w) {
    #   message(paste("CATCHED", w))
    # }
    # , error = function(e) {
    #   message(paste("CATCHED", e))
    # })
    
    if (!is.null(adductsum)){ 
      rownames(adductsum)=names
      adductsum = cbind(adductsum, "HMDB_name"=names_long)
      save(adductsum, file=paste(outdir, "11-adductSums", paste(scanmode, "_",batch,".RData", sep=""), sep="/"))
    }
  }  
}


sumAdducts(outlist.tot, outlist_part, names(repl.pattern.filtered), adducts, batch, scanmode, outdir, z_score)

