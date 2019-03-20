#!/usr/bin/Rscript

thresh_pos=2000
thresh_neg=2000
dims_thresh=100
dimsThresh=100
trim=0.1
nrepl=3
normalization=disabled
thresh2remove=500000000
resol=140000

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(indir, outdir, nrepl, thresh2remove, dimsThresh) {
  removeFromRepl.pat <- function(bad_samples, repl.pattern, nrepl) {
    # bad_samples=remove_pos
    
    tmp = repl.pattern
    
    removeFromGroup=NULL
    
    for (i in 1:length(tmp)){
      tmp2 = repl.pattern[[i]]
      
      remove=NULL
      
      for (j in 1:length(tmp2)){
        if (tmp2[j] %in% bad_samples){
          cat(tmp2[j])
          cat(paste("remove",tmp2[j]))
          cat(paste("remove i",i))
          cat(paste("remove j",j))
          
          remove = c(remove, j)
        }
      }
      
      if (length(remove)==nrepl) removeFromGroup=c(removeFromGroup,i)
      if (!is.null(remove)) repl.pattern[[i]]=repl.pattern[[i]][-remove]
    }
    
    if (length(removeFromGroup)!=0) {
      repl.pattern=repl.pattern[-removeFromGroup]
    }
    
    return(list("pattern"=repl.pattern))
  }
  
  indir = "/Users/nunen/Documents/GitHub/DIMS/16_SinglePatients_XVI/logs"
  outdir = "/Users/nunen/Documents/GitHub/DIMS/16_SinglePatients_XVI"
  
  dir.create(paste(outdir, "average_pklist", sep="/"),showWarnings = F)
  
  # get repl.pattern
  load(paste(indir, "init.RData", sep="/"))
  
  remove_neg=NULL
  remove_pos=NULL
  for (i in 1:length(repl.pattern)) {
    i= 1
    techRepsArray.pos = NULL
    techRepsArray.neg = NULL
    
    tech_reps = as.vector(unlist(repl.pattern[i]))
    sum_neg=0
    sum_pos=0
    n_pos=0
    n_neg=0
    for (j in 1:length(tech_reps)){
      j = 3
      load(paste(paste(outdir, "pklist/", sep="/"), tech_reps[j], ".RData", sep=""))
      message(sum(pklist$neg[,1]))
      message(sum(pklist$pos[,1]))
      # load(paste(paste(outdir, "pklist/", sep="/"), "RES_PL_20170220_0146", ".RData", sep=""))
      
      if (sum(pklist$neg[,1])<thresh2remove){
        remove_neg=c(remove_neg, tech_reps[j])
      } else {
        n_neg=n_neg+1
        sum_neg=sum_neg+pklist$neg
      }
      
      techRepsArray.neg = cbind(techRepsArray.neg, pklist$neg)
      
      if (sum(pklist$pos[,1])<thresh2remove){
        remove_pos=c(remove_pos, tech_reps[j])
      } else {
        n_pos=n_pos+1
        sum_pos=sum_pos+pklist$pos
      }
      
      techRepsArray.pos = cbind(techRepsArray.pos, pklist$pos)
    }
    
    # filter within bins on at least signal in more than one tech. rep.!!!
    if (!is.null(dim(sum_pos))) sum_pos[apply(techRepsArray.pos,1,function(x) length(which(x>dimsThresh))==1),1]=0
    if (!is.null(dim(sum_neg))) sum_neg[apply(techRepsArray.neg,1,function(x) length(which(x>dimsThresh))==1),1]=0
    
    if (n_neg!=0){
      sum_neg[,1]=sum_neg[,1]/n_neg
      colnames(sum_neg)=names(repl.pattern)[i]
      save(sum_neg, file=paste(paste(outdir, "average_pklist", sep="/"),"/", names(repl.pattern)[i], "_neg.RData", sep=""))
    }
    if (n_pos!=0){
      sum_pos[,1]=sum_pos[,1]/n_pos
      colnames(sum_pos)=names(repl.pattern)[i]
      save(sum_pos, file=paste(paste(outdir, "average_pklist", sep="/"),"/", names(repl.pattern)[i], "_pos.RData", sep=""))
    }
  }
  
  # remove_pos=c("RES_DBS_20180312_0184","RES_DBS_20180312_0185","RES_DBS_20180312_0186","RES_DBS_20180312_0229","RES_DBS_20180312_0230")
  retVal = removeFromRepl.pat(remove_pos, repl.pattern, nrepl)
  repl.pattern.filtered = retVal$pattern
  save(repl.pattern.filtered, file=paste(outdir, "repl.pattern.positive.RData", sep="/"))
  write.table(remove_pos, file=paste(outdir, "miss_infusions_pos.txt", sep="/"), row.names=FALSE, col.names=FALSE ,sep= "\t")
  
  # remove_neg=c("RES_DBS_20180312_0121","RES_DBS_20180312_0122","RES_DBS_20180312_0123")
  retVal = removeFromRepl.pat(remove_neg, repl.pattern, nrepl)
  repl.pattern.filtered = retVal$pattern
  save(repl.pattern.filtered, file=paste(outdir, "repl.pattern.negative.RData", sep="/"))
  write.table(remove_neg, file=paste(outdir, "miss_infusions_neg.txt", sep="/"), row.names=FALSE, col.names=FALSE ,sep= "\t")
}

cat("Start averageTechReplicates.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], as.numeric(cmd_args[3]), as.numeric(cmd_args[4]), as.numeric(cmd_args[5]))

cat("Ready averageTechReplicates.R")
