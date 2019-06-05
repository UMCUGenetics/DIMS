# statistics_z <- function(peaklist, plotdir, filename, control_label, case_label, sortCol, patients, plot=TRUE, adducts=FALSE){
statistics_z_2 <- function(peaklist, outputfolder, control_label, case_label, sortCol, patients, plot=TRUE, adducts=FALSE){
  # peaklist=as.data.frame(outlist.adducts.HMDB)
  # plotdir="./results/plots/adducts"
  # filename="./results/allpgrps_stats.txt"
  # adducts=TRUE
  
  # peaklist=outlist.pos.id
  # plotdir="./results/plots/positive"
  # filename="./results/Pos_allpgrps_stats.txt"
  # plot=TRUE
  # adducts=FALSE
  
  # OLD WAY
  dir.create("plots/adducts", showWarnings = F)
  
  ########## Statistics: Z-score
  
  startcol = dim(peaklist)[2]+3 
  
  # calculate mean and sd for Control group
  ctrl.cols <- grep(control_label, colnames(peaklist),fixed = TRUE) # 5:41
  int.cols <- c(grep(control_label, colnames(peaklist),fixed = TRUE), grep(case_label, colnames(peaklist),fixed = TRUE))
  peaklist[,int.cols][peaklist[,int.cols]==0] = NA
  
  # tmp = data.matrix(peaklist[ , ctrl.cols], rownames.force = TRUE)
  tmp = peaklist[ , ctrl.cols]
  
  peaklist$avg.ctrls <- apply(tmp, 1, function(x) mean(as.numeric(x),na.rm = TRUE))
  peaklist$sd.ctrls <- apply(tmp, 1, function(x) sd(as.numeric(x),na.rm = TRUE))
  
  cnames.z = NULL
  
  for (i in int.cols) {
    # message(i)
    cname = colnames(peaklist)[i]
    #     cnames.z = c(cnames.z, paste(cname, "Zscore", sep="_"), paste(cname, "incr", sep="_"), paste(cname, "decr", sep="_"))
    cnames.z = c(cnames.z, paste(cname, "Zscore", sep="_"))
    #     zscores.1col <- (as.numeric(peaklist[ , i]) - peaklist$avg.ctrls) / peaklist$sd.ctrls
    zscores.1col <- (as.numeric(as.vector(unlist(peaklist[ , i]))) - peaklist$avg.ctrls) / peaklist$sd.ctrls
    
    
    #     incr = rep(0, length(zscores.1col))
    #     incr[which(zscores.1col > 2)] = 1
    #     decr = rep(0, length(zscores.1col))
    #     decr[which(zscores.1col < -1.5)] = 1
    #     peaklist <- cbind(peaklist, zscores.1col, incr, decr)
    peaklist <- cbind(peaklist, zscores.1col)
  }
  
  colnames(peaklist)[startcol:ncol(peaklist)] <- cnames.z
  
  #   # again to avarage multiple timepoints (flags for Hanneke)
  #   z.cols = grep("Zscore", colnames(peaklist),fixed = TRUE)
  #   z.means = NULL
  #   z.means.names = NULL
  #   done = NULL
  #   
  #   for (i in z.cols) {
  #     cname = unlist(strsplit(colnames(peaklist)[i], "_",fixed = TRUE))[1]
  #     
  #     if (unlist(strsplit(cname, ".",fixed = TRUE))[2]!=1){
  #       p = unlist(strsplit(cname, ".",fixed = TRUE))[1]
  #       
  #       if (p %in% done) next
  #       
  #       index=grep(p, colnames(peaklist), fixed = TRUE)
  #       index2=grep("Zscore", colnames(peaklist)[index], fixed = TRUE)
  #       
  #       if (length(index[index2])>1){
  #         z.mean = as.vector(unlist(apply(peaklist[,index[index2]],1,mean)))
  #         z.means.names=c(z.means.names, paste(p, "Z_mean", sep="_"), paste(p, "Z_mean_incr", sep="_"), paste(p, "Z_mean_decr", sep="_"))
  #         incr = rep(0, length(z.mean))
  #         incr[which(z.mean > 2)] = 1
  #         decr = rep(0, length(z.mean))
  #         decr[which(z.mean < -1.5)] = 1
  #         z.means = cbind(z.means,z.mean,incr,decr)
  #         
  #         done = c(done, p)
  #       }
  #     }
  #   }
  #   
  #   colnames(z.means) = z.means.names
  # 
  #   peaklist = cbind(peaklist, z.means)
  
  ########## make a plot for every peak group: ################
  
  # selcols <- c(startcol:dim(peaklist)[2]) #77:131
  # => z.cols
  
  z.cols = grep("Zscore", colnames(peaklist),fixed = TRUE)
  
  if (plot) {  
    # make all plots:
    for (p in 1:nrow(peaklist)) { # p <- 1119 # in Neg  # p <- 2658  # in Pos
      
      if (!adducts){
        # only picture if identified
        # if ((peaklist[p,"assi_HMDB"]=="") & (peaklist[p,"iso_HMDB"]=="")) next
        # if (is.na(peaklist[p,"assi_HMDB"]) & (is.na(peaklist[p,"iso_HMDB"]))) next
        
        if ((is.na(peaklist[p,"assi_HMDB"]) | peaklist[p,"assi_HMDB"]=="") &
            (is.na(peaklist[p,"iso_HMDB"]) | peaklist[p,"iso_HMDB"]=="")) next
      }
      
      ########################## box plot ##################################################
      vl <- list(as.numeric(as.vector(unlist(tmp[p,]))))
      gene_name <- rownames(tmp[p,])
      labels <- c("C")
      
      for (i in 1:length(patients)){
        label=colnames(peaklist)[int.cols][grep(paste0(case_label, patients[i], "."), colnames(peaklist)[int.cols], fixed = TRUE)]
        # p.int=data.matrix(peaklist[p,label])
        p.int=as.numeric(as.vector(unlist(peaklist[p,label])))
        
        # assign(paste("P",i,sep=""),p.int[1,])
        assign(paste0("P",i),p.int)
        vl[[i+1]] <- get(paste0("P",i))
        labels <- c(labels,toString(patients[i]))
      }
      
      vl = setNames(vl, labels)
      
      # Set width of boxplot
      boxwidth <- length(labels) * 12 + 30
      
      png(filename=paste0(plotdir, "/", sprintf("%05d", p), "_box.png"), boxwidth, 240)
      boxplot(vl, col=c("green",rep("red",length(vl)-1)), las = 2, par(cex.axis=0.9), main = gene_name)
      dev.off()
      
      ########################## Z score ###################################################
      ints <- as.numeric(peaklist[p, z.cols])
      ints[ints > 10] <- 10.2
      ints[ints < -10] <- -10.2
      
      names(ints) = colnames(peaklist)[z.cols]
      
      if (is.na(peaklist[p, "mzmed.pgrp"])){
        id = rownames(peaklist[p,])
      } else {
        id = paste("m/z:", peaklist[p, "mzmed.pgrp"], sep=" ")
      }
      
      png(filename=paste0(plotdir, "/", sprintf("%05d", p), ".png"), 320, 240)
      plot(ints, ints, type="n", xlim <- c(-11, 11), ylim = c(0,(length(patients)+2)), yaxt='n', main=id, xlab="Zscore", ylab="")
      abline(v=0)
      abline(v=c(-2,2), lty=2)
      text(-10, length(patients)+1.2, control_label, cex=1.3)
      points(ints[grep(control_label, names(ints),fixed=TRUE)], rep((length(patients)+1),length(ctrl.cols)), col="green", pch=16, cex=1.2)
      abline(h=length(patients)+1,lty=3)
      
      ints.case = ints[grep(case_label, names(ints),fixed=TRUE)]
      
      for (i in 1:length(patients)){
        if (i%%2==0) {
          text(-10, length(patients)+1.2-i, paste0("P", patients[i]), cex=1.3)
        } else {
          text(10, length(patients)+1.2-i, paste0("P", patients[i]), cex=1.3)
        }
        #ints.p=ints.case[grep(paste(case_label, i, "_", sep=""), names(ints.case))]
        ints.p=ints.case[grep(paste0(case_label, patients[i], "."), names(ints.case),fixed=TRUE)]
        points(ints.p, rep(length(patients)+1-i,length(ints.p)), col="red", pch=16, cex=1.2)
        abline(h=length(patients)+1-i,lty=3)
      }
      
      dev.off()
      
    }  
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
  write.table(peaklist, file=paste0(outputfolder, "allpgrps_stats.txt", sep="/"))
  
  return(peaklist)
  
}  
