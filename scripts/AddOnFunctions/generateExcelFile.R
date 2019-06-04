generateExcelFile <- function(peaklist, plotdir, imageNum, fileName, subName=c("",""), sub, adducts=FALSE) {
  # plotdir=file.path(plotdir)
  # imageNum=2
  # fileName="./results/xls/Pos_allpgrps_identified"
  # subName=c("","_box")
  # adducts=TRUE
  
  # -Xms512m initial java heap size
  # -Xmx8000m max java heap size
  
  # tmp = which(colnames(peaklist)=="nrsamples")
  # if (length(tmp)>0) peaklist = peaklist[,-c(tmp)]
  #  peaklist = peaklist[,-c(which(colnames(peaklist)=="metlin.1"))]
  
  end=0
  i=0
  
  if (dim(peaklist)[1]>=sub & (sub>0)){
    for (i in 1:floor(dim(peaklist)[1]/sub)){
      start=-(sub-1)+i*sub
      end=i*sub
      message(paste0(start, ":", end))
      
      genExcelFileV3(peaklist[c(start:end),], imageNum, paste(fileName, i, sep="_"), plotdir, subName, adducts)
    }
  }  
  start = end + 1
  end = dim(peaklist)[1]
  message(start)
  message(end)
  genExcelFileV3(peaklist[c(start:end),], imageNum, paste(fileName, i+1, sep="_"), plotdir, subName, adducts)
}
