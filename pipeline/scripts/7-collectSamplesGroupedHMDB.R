#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

# load required packages 
# none 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

outdir <- cmd_args[1]
scanmode <- cmd_args[2]
ppm <- as.numeric(cmd_args[3])

# filepath =  paste(outdir, "grouping_hmdb", sep="/")
# files = list.files(filepath,recursive=TRUE, full.names=TRUE, pattern=paste("*_",scanmode,".RData",sep=""))
#
# outlist.tot=NULL
#
# for (i in 1:length(files)) {
#   #message(files[i])
#   load(files[i])
#
#   outlist.tot = rbind(outlist.tot, outpgrlist)
# }
#
# save(outlist.tot, file=paste(outdir, paste(paste("grouped_HMDB", scanmode, sep="_"), "RData", sep="."), sep="/"))

filepath =  paste(outdir, "6-grouping_hmdb_done", sep="/")
files = list.files(filepath,recursive=TRUE, full.names=TRUE, pattern=paste("*_",scanmode,".RData",sep=""))

load(paste(outdir, "5-specpks_all", paste(scanmode, "RData", sep="."), sep="/")) #outlist.tot

# Make a list of indexes of peaks that have been identified, then remove these from the peaklist.
remove = NULL
for (i in 1:length(files)) {
  message(files[i])
  load(files[i]) #outlist.grouped
  remove = c(remove, which(outlist.tot[,"mzmed.pkt"] %in% outlist.grouped[,"mzmed.pkt"]))
}
outlist.rest = outlist.tot[-remove,]

# save(outlist.rest, file=paste(outdir, "specpks_all", paste(scanmode, "rest.RData", sep="_"), sep="/"))

outdir=paste(outdir, "7-specpks_all_rest", sep="/")
dir.create(outdir, showWarnings = FALSE)

# sort on mass
outlist = outlist.rest[order(as.numeric(outlist.rest[,"mzmed.pkt"])),]

n=dim(outlist)[1]
sub=10000
end=0
min_1_last=sub
check=0
outlist_i_min_1=NULL
i = 0

if (n>=sub & (floor(n/sub)-1)>=2){
  for (i in 2:floor(n/sub)-1){
    start=-(sub-1)+i*sub
    end=i*sub
    
    if (i>1){
      outlist_i = outlist[c(start:end),]
      
      n_moved = 0
      
      # Calculate 3ppm and replace border, avoid cut within peakgroup!
      while ((as.numeric(outlist_i[1,"mzmed.pkt"]) - as.numeric(outlist_i_min_1[min_1_last,"mzmed.pkt"]))*1e+06/as.numeric(outlist_i[1,"mzmed.pkt"]) < 3) {
        outlist_i_min_1 = rbind(outlist_i_min_1, outlist_i[1,])
        outlist_i = outlist_i[-1,]
        n_moved = n_moved + 1
      }
      
      # message(paste("Process", i-1,":", dim(outlist_i_min_1)[1]))
      save(outlist_i_min_1, file=paste(outdir, paste(scanmode, paste("outlist_i_min_1",i-1,"RData", sep="."), sep="_"), sep="/"))
      check=check+dim(outlist_i_min_1)[1]
      
      outlist_i_min_1 = outlist_i
      min_1_last = dim(outlist_i_min_1)[1]
      
    } else {
      outlist_i_min_1 = outlist[c(start:end),]
    }
  }
}

start = end + 1
end = n
outlist_i = outlist[c(start:end),]
n_moved = 0

if(!is.null(outlist_i_min_1)){
  # Calculate 4ppm and replace border, avoid cut within peakgroup!
  while ((as.numeric(outlist_i[1,"mzmed.pkt"]) - as.numeric(outlist_i_min_1[min_1_last,"mzmed.pkt"]))*1e+06/as.numeric(outlist_i[1,"mzmed.pkt"]) < 2*ppm) {
    outlist_i_min_1 = rbind(outlist_i_min_1, outlist_i[1,])
    outlist_i = outlist_i[-1,]
    n_moved = n_moved + 1
  }
  
  cat(paste("Process", i+1-1,":", dim(outlist_i_min_1)[1]))
  save(outlist_i_min_1, file=paste(outdir, paste(scanmode, paste("outlist_i_min_1",i,"RData", sep="."), sep="_"), sep="/"))
  check=check+dim(outlist_i_min_1)[1]
}

outlist_i_min_1=outlist_i
cat(paste("Process", i+2-1,":", dim(outlist_i_min_1)[1]))
save(outlist_i_min_1, file=paste(outdir, paste(scanmode, paste("outlist_i_min_1",i+1,"RData", sep="."), sep="_"), sep="/"))
check=check+dim(outlist_i_min_1)[1]

if (check==dim(outlist)[1]){
  cat(paste("Check is oke!"))
} else {
  cat(paste("Check is failed!"))
}

}

cat("Start collectSamplesGroupedHMDB.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], as.numeric(cmd_args[3]))

cat("Ready collectSamplesGroupedHMDB.R")
