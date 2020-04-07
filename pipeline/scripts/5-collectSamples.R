#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args = commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

outdir <- cmd_args[1]
scanmode <- cmd_args[2]
db <- cmd_args[3]
ppm <- as.numeric(cmd_args[4])

# Check if all jobs terminated correct!
notRun = NULL

load(paste0(outdir, "/repl.pattern.", scanmode, ".RData"))
groupNames = names(repl.pattern.filtered)

indir <- paste(outdir, "4-specpks", sep = "/")
object.files = list.files(indir, full.names=TRUE, pattern="*.RData")

for (i in 1:length(groupNames)) {
  group <- paste0(indir, paste0(paste(groupNames[i], scanmode, sep = "_"), ".RData"))
  if (!(group %in% object.files)) {
    notRun = c(notRun, group)
  }
}

#if (is.null(notRun)){
cat("\nCollecting samples!")

# negative
filepath <- paste(outdir, "4-specpks", sep = "/")
files <- list.files(filepath,recursive=TRUE, full.names=TRUE, pattern=paste("*_",scanmode,".RData",sep=""))

outlist.tot=NULL
for (i in 1:length(files)) {
  
  cat("\n", files[i])
  load(files[i])
  
  if (is.null(outlist.persample) || (dim(outlist.persample)[1]==0)){
    tmp=strsplit(files[i], "/")[[1]]
    fname = tmp[length(tmp)]
    #fname = strsplit(files[i], "/")[[1]][8]
    fname = strsplit(fname, ".RData")[[1]][1]
    fname = substr(fname, 13, nchar(fname))
    
    if (i == 1) { outlist.tot <- c(fname, rep("-1",5)) } else { outlist.tot <- rbind(outlist.tot, c(fname, rep("-1",5)))}
  } else {
    if (i == 1) { outlist.tot <- outlist.persample } else { outlist.tot <- rbind(outlist.tot, outlist.persample)}
  }
}

# remove negative values
index=which(outlist.tot[,"height.pkt"]<=0)
if (length(index)>0) outlist.tot = outlist.tot[-index,]
index=which(outlist.tot[,"mzmed.pkt"]<=0)
if (length(index)>0) outlist.tot = outlist.tot[-index,]

outdir_specpks <- paste(outdir, "5-specpks_all", sep = "/")
dir.create(outdir_specpks, showWarnings = F)
save(outlist.tot, file = paste(outdir_specpks, paste(scanmode, "RData", sep = "."), sep = "/"))

# cut HMDB ##########################################################################################################################################
load(db)
outdir_hmdb <- paste(outdir, "hmdb_part", sep = "/")
dir.create(outdir_hmdb, showWarnings = FALSE)
load(paste(outdir, "breaks.fwhm.RData", sep = "/"))

if (scanmode=="negative"){
  label = "MNeg"
  HMDB_add_iso=HMDB_add_iso.Neg
} else {
  label = "Mpos"
  HMDB_add_iso=HMDB_add_iso.Pos
}

# filter mass range meassured!!!
HMDB_add_iso = HMDB_add_iso[which(HMDB_add_iso[,label]>=breaks.fwhm[1] & HMDB_add_iso[,label]<=breaks.fwhm[length(breaks.fwhm)]),]

# sort on mass
outlist = HMDB_add_iso[order(as.numeric(HMDB_add_iso[,label])),]

n=dim(outlist)[1]
sub=5000
end=0
min_1_last=sub
check=0
outlist_part=NULL


if (n < sub) {
  outlist_part <- outlist
  save(outlist_part, file = paste(outdir_hmdb, paste0(scanmode, "_hmdb.1.RData"), sep = "/"))
} else {
  
  if (n >= sub & (floor(n/sub) - 1) >= 2){
    for (i in 2:floor(n/sub) - 1){
      start <- -(sub - 1) + i*sub
      end <- i*sub
      
      if (i > 1){
        outlist_i = outlist[c(start:end),]
        
        n_moved = 0
        
        # Calculate 3ppm and replace border, avoid cut within peakgroup!
        while ((as.numeric(outlist_i[1,label]) - as.numeric(outlist_part[min_1_last,label]))*1e+06/as.numeric(outlist_i[1,label]) < ppm) {
          outlist_part <- rbind(outlist_part, outlist_i[1,])
          outlist_i <- outlist_i[-1,]
          n_moved <- n_moved + 1
        }
        
        # message(paste("Process", i-1,":", dim(outlist_part)[1]))
        save(outlist_part, file = paste(outdir_hmdb, paste(scanmode, paste("hmdb",i-1,"RData", sep="."), sep="_"), sep = "/"))
        check <- check + dim(outlist_part)[1]
        
        outlist_part <- outlist_i
        min_1_last <- dim(outlist_part)[1]
        
      } else {
        outlist_part <- outlist[c(start:end),]
      }
    }
  }
  
  start <- end + 1
  end <- n
  outlist_i <- outlist[c(start:end),]
  n_moved <- 0
  
  if (!is.null(outlist_part)) {
    # Calculate 3ppm and replace border, avoid cut within peakgroup!
    while ((as.numeric(outlist_i[1,label]) - as.numeric(outlist_part[min_1_last,label]))*1e+06/as.numeric(outlist_i[1,label]) < ppm) {
      outlist_part = rbind(outlist_part, outlist_i[1,])
      outlist_i = outlist_i[-1,]
      n_moved = n_moved + 1
    }
    
    # message(paste("Process", i+1-1,":", dim(outlist_part)[1]))
    save(outlist_part, file = paste(outdir_hmdb, paste(scanmode, paste("hmdb",i,"RData", sep = "."), sep = "_"), sep = "/"))
    check <- check + dim(outlist_part)[1]
  }
  
  outlist_part <- outlist_i
  # message(paste("Process", i+2-1,":", dim(outlist_part)[1]))
  save(outlist_part, file = paste(outdir_hmdb, paste(scanmode, paste("hmdb", i + 1, "RData", sep="."), sep="_"), sep = "/"))
  check <- check + dim(outlist_part)[1]
  cat("\n", "Check", check == dim(outlist)[1])
  
}

#} else {

if (!is.null(notRun)){
  for (i in 1:length(notRun)){
    message(paste(notRun[i], "was not generated"))
  }
}
