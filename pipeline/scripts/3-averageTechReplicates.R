#!/usr/bin/Rscript

# load required packages  for TIC plots
library("ggplot2")
library("gridExtra")
pdf(NULL) 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep="")

indir <- cmd_args[1]
outdir <- cmd_args[2]
nrepl <- as.numeric(cmd_args[3])
thresh2remove <- as.numeric(cmd_args[4])
dimsThresh <- as.numeric(cmd_args[5])

# create output folder
dir.create(paste(outdir, "3-average_pklist", sep = "/"), showWarnings = F)

removeFromRepl.pat <- function(bad_samples, repl.pattern, nrepl) {
  # bad_samples=remove_pos
  
  tmp = repl.pattern
  
  removeFromGroup=NULL
  
  for (i in 1:length(tmp)){
    tmp2 = repl.pattern[[i]]
    
    remove=NULL
    
    for (j in 1:length(tmp2)){
      if (tmp2[j] %in% bad_samples){
        #cat(tmp2[j])
        #cat(paste("remove",tmp2[j]))
        #cat(paste("remove i",i))
        #cat(paste("remove j",j))
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


# get repl.pattern
load(paste(indir, "init.RData", sep="/"))

remove_neg=NULL
remove_pos=NULL
cat("Pklist sum threshold to remove technical replicate:", thresh2remove, "\n")
for (i in 1:length(repl.pattern)) {
  techRepsArray.pos = NULL
  techRepsArray.neg = NULL
  
  tech_reps = as.vector(unlist(repl.pattern[i]))
  sum_neg=0
  sum_pos=0
  n_pos=0
  n_neg=0
  for (j in 1:length(tech_reps)) {
    load(paste(paste(outdir, "2-pklist/", sep="/"), tech_reps[j], ".RData", sep=""))
    cat("\n\nParsing", tech_reps[j])
    # load(paste(paste(outdir, "pklist/", sep="/"), "RES_PL_20170220_0146", ".RData", sep=""))
    
    cat("\n\tNegative pklist sum",sum(pklist$neg[,1]))
    if (sum(pklist$neg[,1])<thresh2remove){
      cat(" ... Removed")
      remove_neg=c(remove_neg, tech_reps[j])
    } else {
      n_neg=n_neg+1
      sum_neg=sum_neg+pklist$neg
    }
    
    techRepsArray.neg = cbind(techRepsArray.neg, pklist$neg)
    
    cat("\n\tPositive pklist sum",sum(pklist$pos[,1]))
    if (sum(pklist$pos[,1])<thresh2remove){
      cat(" ... Removed")
      remove_pos=c(remove_pos, tech_reps[j])
    } else {
      n_pos=n_pos+1
      sum_pos=sum_pos+pklist$pos
    }
    
    techRepsArray.pos = cbind(techRepsArray.pos, pklist$pos)
  }
  
  # filter within bins on at least signal in more than one tech. rep.!!!
  # turned off for measurement in duplo (n=2)
  # if (!is.null(dim(sum_pos))) sum_pos[apply(techRepsArray.pos,1,function(x) length(which(x>dimsThresh))==1),1]=0
  # if (!is.null(dim(sum_neg))) sum_neg[apply(techRepsArray.neg,1,function(x) length(which(x>dimsThresh))==1),1]=0
  
  if (n_neg != 0){
    sum_neg[,1] <- sum_neg[,1]/n_neg
    colnames(sum_neg) <- names(repl.pattern)[i]
    save(sum_neg, file=paste(paste(outdir, "3-average_pklist", sep="/"),"/", names(repl.pattern)[i], "_neg.RData", sep=""))
  }
  if (n_pos != 0) {
    sum_pos[,1] <- sum_pos[,1]/n_pos
    colnames(sum_pos) <- names(repl.pattern)[i]
    save(sum_pos, file=paste(paste(outdir, "3-average_pklist", sep="/"),"/", names(repl.pattern)[i], "_pos.RData", sep=""))
  }
}

# remove_pos=c("RES_DBS_20180312_0184","RES_DBS_20180312_0185","RES_DBS_20180312_0186","RES_DBS_20180312_0229","RES_DBS_20180312_0230")
retVal <- removeFromRepl.pat(remove_pos, repl.pattern, nrepl)
repl.pattern.filtered <- retVal$pattern
save(repl.pattern.filtered, file=paste(outdir, "repl.pattern.positive.RData", sep="/"))
write.table(remove_pos, file=paste(outdir, "miss_infusions_pos.txt", sep="/"), row.names=FALSE, col.names=FALSE ,sep= "\t")

# remove_neg=c("RES_DBS_20180312_0121","RES_DBS_20180312_0122","RES_DBS_20180312_0123")
retVal <- removeFromRepl.pat(remove_neg, repl.pattern, nrepl)
repl.pattern.filtered <- retVal$pattern
save(repl.pattern.filtered, file=paste(outdir, "repl.pattern.negative.RData", sep="/"))
write.table(remove_neg, file=paste(outdir, "miss_infusions_neg.txt", sep="/"), row.names=FALSE, col.names=FALSE ,sep= "\t")

# New: generate TIC plots
run_name <- basename(outdir)
tic_input_dir <- paste(outdir, "2-pklist", sep = "/")

# get replication pattern
load(paste(outdir, "logs", "init.RData", sep="/"))
# get misinjections
bad_pos <- read.table(paste(outdir, "miss_infusions_pos.txt", sep="/"))
bad_neg <- read.table(paste(outdir, "miss_infusions_neg.txt", sep="/"))

# get all txt files
tic_files = list.files(tic_input_dir, full.names=TRUE, pattern="*TIC.txt")
all_samps <- sub('_TIC\\..*$', '', basename(tic_files))

print("\n")
print(paste0("reading TIC files", tic_files[1], " - till - ", tic_files[length(tic_files)]))
# determine maximum intensity
highest_tic_max <- 0
for (file in tic_files) {
  tic <- read.table(file)
  this_tic_max <- max(tic$TIC)
  if (this_tic_max > highest_tic_max) {
    highest_tic_max <- this_tic_max
    max_sample <- sub('_TIC\\..*$', '', basename(file))
  }
}

tic_plot_list <- list()
k = 0
for (i in c(1:length(repl.pattern))) { 
  tech_reps <- as.vector(unlist(repl.pattern[i]))
  sampleName <- names(repl.pattern)[i]
  for (j in 1:length(tech_reps)) {
    k = k + 1
    repl1.nr <- read.table(paste(paste(outdir, "2-pklist/", sep="/"), tech_reps[j], "_TIC.txt", sep=""))
    bad_color_pos <- tech_reps[j] %in% bad_pos[[1]]
    bad_color_neg <- tech_reps[j] %in% bad_neg[[1]]
    if (bad_color_neg & bad_color_pos) {
	    plotcolor = '#F8766D'
    } else if (bad_color_pos) {
	    plotcolor = "#ED8141"
    } else if (bad_color_neg) {
	    plotcolor = "#BF80FF"
    } else {
	    plotcolor = 'white'
    }
    tic_plot <- ggplot(repl1.nr, aes(retentionTime, TIC)) +
      geom_line(linewidth = 0.3) +
      geom_hline(yintercept = highest_tic_max, col = "grey", linetype = 2, linewidth = 0.3) +
      labs(x = 't (s)', y = 'TIC', title = paste0(tech_reps[j], "  ||  ", sampleName)) +
      theme(plot.background = element_rect(fill = plotcolor), axis.text = element_text(size = 4), axis.title = element_text(size = 4), plot.title = element_text(size = 6))
    tic_plot_list[[k]] <- tic_plot
  }

}
# Create a layout matrix with the size of the number of replicates as number of columns
layout <- matrix(1:(10 * nrepl), 10, nrepl, TRUE)

tic_plot_pdf <- marrangeGrob(grobs = tic_plot_list, 
			     nrow = 10, 
			     ncol = nrepl, 
			     layout_matrix = layout, 
			     top = quote(paste("TICs of run", run_name," \n colors: red = both modes misinjection, orange = pos mode misinjection, purple = neg mode misinjection \n ", g, "/", npages)))
ggsave(filename = paste0(outdir, "/", run_name, "_TICplots.pdf"), tic_plot_pdf, width = 21, height = 29.7, units = "cm")


