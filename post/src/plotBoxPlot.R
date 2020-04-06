plotBoxPlot <- function(peaklist, export, control_label, case_label, plotdir, patients) {
  # peaklist= my_table[selectedRow,,drop=FALSE]
  # export=FALSE
  # fileName=NULL
  # patients=getPatients(my_table)
  
  ctrl.cols = grep(control_label, colnames(peaklist),fixed = TRUE)
  ctrl.cols = ctrl.cols[-grep("Zscore", colnames(peaklist)[ctrl.cols],fixed = TRUE)]
  int.cols = c(grep(control_label, colnames(peaklist),fixed = TRUE), grep(case_label, colnames(peaklist),fixed = TRUE))
  int.cols = int.cols[-grep("Zscore", colnames(peaklist)[int.cols],fixed = TRUE)]
  
  vl = list(as.numeric(as.vector(unlist(peaklist[1,ctrl.cols,drop=FALSE]))))
  gene_name <- rownames(peaklist[1])
  labels=c("C")
  
  for (p in 1:length(patients)){
    label <- colnames(peaklist)[int.cols][grep(paste(case_label, patients[p], ".", sep=""), colnames(peaklist)[int.cols], fixed = TRUE)]
    p.int <- as.numeric(as.vector(unlist(peaklist[1,label,drop=FALSE])))
    
    assign(paste("P",p,sep=""),p.int)
    
    vl[[p+1]] <- get(paste("P",p,sep=""))
    labels <- c(labels,toString(patients[p]))
  }
  
  labels <- paste0("P",labels)
  
  vl <- setNames(vl, labels)

  plot_width <- length(vl)*12+90

  if (export){
    png(filename = paste(plotdir, "/", gene_name, "_box.png", sep=""), plot_width, 240)
    # png(filename = paste(plotdir, "/", sprintf("%05d", i), "_box.png", sep=""), plot_width, 240)
    boxplot(vl, 
            col = c("green",rep("red",length(vl)-1)),
            names.arg = labels, 
            las = 2, 
            main = gene_name)
    dev.off()
  } else {
    return(boxplot(vl, col=c("green",rep("red",length(vl)-1)),names.arg = labels, las=2, main = gene_name))  
  }
}
