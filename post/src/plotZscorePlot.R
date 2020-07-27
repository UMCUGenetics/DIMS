plotZscorePlot <- function(peaklist, export, control_label, case_label, fileName, patients) {
  # patients=colnames(peaklist)[grep("P", colnames(peaklist), fixed = TRUE)]
  # patients=unique(as.vector(unlist(lapply(strsplit(patients, ".", fixed = TRUE), function(x) x[1]))))
  # # ToDo: If 2 P's in sample names!!!!!!!!!!!!!
  # # patients=sort(as.numeric(unique(as.vector(unlist(lapply(strsplit(patients, "_P", fixed = TRUE), function(x) x[2]))))))
  # patients=sort(as.numeric(unique(as.vector(unlist(lapply(strsplit(patients, "P", fixed = TRUE), function(x) x[2]))))))
  
  ctrl.cols = grep(control_label, colnames(peaklist),fixed = TRUE)
  ctrl.cols = ctrl.cols[-grep("Zscore", colnames(peaklist)[ctrl.cols],fixed = TRUE)]
  
  z.cols = grep("Zscore", colnames(peaklist),fixed = TRUE)
  
  ########################## Z score ###################################################
  ints = as.numeric(peaklist[, z.cols])
  ints[ints > 10] = 10.2
  ints[ints < -10] = -10.2
  
  names(ints) = colnames(peaklist)[z.cols]
  id = toString(peaklist[,"HMDB_code"])
  
  plotLocal <- function(){
    return({plot(ints, ints, type="n", xlim <- c(-11, 11), ylim = c(0,(length(patients)+2)), yaxt='n', main=id, xlab="Zscore", ylab="")
      abline(v=0)
      abline(v=c(-2,2), lty=2)
      text(-10, length(patients)+1.2, control_label, cex=1.3)
      points(ints[grep(control_label, names(ints),fixed=TRUE)], rep((length(patients)+1),length(ctrl.cols)), col="green", pch=16, cex=1.2)
      abline(h=length(patients)+1,lty=3)
      
      ints.case = ints[grep(case_label, names(ints),fixed=TRUE)]
      
      for (p in 1:length(patients)){
        if (p%%2==0) {
          text(-10, length(patients)+1.2-p, paste("P", patients[p], sep=""), cex=1.3)
        } else {
          text(10, length(patients)+1.2-p, paste("P", patients[p], sep=""), cex=1.3)
        }
        #ints.p=ints.case[grep(paste(case_label, p, "_", sep=""), names(ints.case))]
        ints.p=ints.case[grep(paste(case_label, patients[p], ".", sep=""), names(ints.case),fixed=TRUE)]
        points(ints.p, rep(length(patients)+1-p,length(ints.p)), col="red", pch=16, cex=1.2)
        abline(h=length(patients)+1-p,lty=3)
      }
    })
  }
  
  if (export){
    
    png(filename=fileName, 320, 240)
    plotLocal()
    dev.off()
    
  } else {
    
    return({
      plotLocal()
    })
    
  }
}