statistics_z_4export <- function(peaklist, plotdir, patients, adducts, control_label, case_label){
  # peaklist=as.data.frame(peaklist)
  
  unlink(paste(getwd(), "results/xls", sep="/"), recursive = TRUE, force = TRUE)
  # unlink(paste(getwd(), "results/plots", sep="/"), recursive = TRUE, force = TRUE)
  unlink(paste(getwd(), "results/xls_fixed", sep="/"), recursive = TRUE, force = TRUE)
  
  dir.create(paste(getwd(), "results/plots", sep="/"), showWarnings = F)
  dir.create(paste(getwd(), "results/plots/positive", sep="/"), showWarnings = F)
  dir.create(paste(getwd(), "results/plots/negative", sep="/"), showWarnings = F)
  dir.create(paste(getwd(), "results/plots/adducts", sep="/"), showWarnings = F)
  
  ########## Statistics: Z-score
  
  startcol = dim(peaklist)[2]+3 
  
  # make all plots:
  for (i in 1:nrow(peaklist)) { # p <- 1119 # in Neg  # p <- 2658  # in Pos

    if (!adducts){
      if ((is.na(peaklist[i,"assi_HMDB"]) | peaklist[i,"assi_HMDB"]=="") &
          (is.na(peaklist[i,"iso_HMDB"]) | peaklist[i,"iso_HMDB"]=="")) next
    }

    plotBoxPlot(peaklist[i,,drop=FALSE], export=TRUE, control_label, case_label, paste(plotdir, "/", sprintf("%05d", i), "_box.png", sep=""), patients)

    # plotZscorePlot(peaklist[i,,drop=FALSE], export=TRUE, control_label, case_label, paste(plotdir, "/", sprintf("%05d", i), ".png", sep=""), patients)
  }
  
  if (!adducts){
    if ((dim(peaklist[, z.cols])[2]+6)!=(startcol-1)){
      ppmdev=array(1:dim(peaklist)[1], dim=c(dim(peaklist)[1]))
      
      # calculate ppm deviation
      for (i in 1:dim(peaklist)[1]){
        # if (peaklist$theormz_intdb[i]!=0 & (peaklist$theormz_intdb[i]!="")){
        #   ppmdev[i] <- 1000000*(as.numeric(peaklist$mzmed.pgrp[i])-as.numeric(peaklist$theormz_intdb[i]))/as.numeric(peaklist$theormz_intdb[i])
        # } else
        #
        if (!is.na(peaklist$theormz_HMDB[i]) & !is.null(peaklist$theormz_HMDB[i]) & (peaklist$theormz_HMDB[i]!="")){
          
          ppmdev[i] <- 10^6*(as.numeric(as.vector(peaklist$mzmed.pgrp[i]))-as.numeric(as.vector(peaklist$theormz_HMDB[i])))/as.numeric(as.vector(peaklist$theormz_HMDB[i]))
          
        } else {
          ppmdev[i]=NA
        }
      }
      
      peaklist <- cbind(peaklist[, 1:6], ppmdev=ppmdev, peaklist[ , 7:ncol(peaklist)])
    }
  }
  
  # remove index column
  int = which(colnames(peaklist)=="index")
  if (length(int)>0) peaklist=peaklist[,-int]
  
  # Add index to find plots and sort on p.value
  index = c(1:dim(peaklist)[1])
  peaklist = cbind(peaklist, "index"=index)
  
  #peaklist = peaklist[order(peaklist[,sortCol]),]
  
  #   # Order on average Z-score
  #   tmp = peaklist[,grep("Zscore", colnames(peaklist))]
  #   tmp.p = tmp[,grep("P", colnames(tmp)),drop=FALSE]
  #   tmp.p.avg = apply(tmp.p, 1, mean)
  #   
  #   peaklist = cbind(peaklist, "avg.z.score"=tmp.p.avg)
  #   peaklist = peaklist[order(abs(tmp.p.avg), decreasing = TRUE),]
  
  # write.table(peaklist, file=filename, sep="\t")
  
  return(peaklist)
  
} 
