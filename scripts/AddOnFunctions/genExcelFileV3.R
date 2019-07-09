genExcelFileV3 <- function(peaklist, imageNum=1, subFile, plotdir, subName, adducts) { 
  # peaklist = peaklist[c(start:end),]
  # imageNum=2
  # subFile=paste(fileName, 1, sep="_")
  
  # Tip!!!
  # Use read.xlsx() in the openxlsx package. It has no dependency on rJava 
  
  # options(java.parameters = "-Xmx4096m")
  # options(java.parameters = "-Xmx8192m")
  # options(java.parameters = "-Xmx2048m")
  options(java.parameters = "-Xmx4g" )
  library("rJava")
  library("XLConnect")
  
  jgc <- function()
  {
    .jcall("java/lang/System", method = "gc")
  }
  
  # Frees Java Virtual Machine (JVM) memory
  xlcFreeMemory()
  
  filelist <- "AllPeakGroups"
  npeaks = dim(peaklist)[1]
  
  ###  insert first column
  addCol <- matrix(c(""), nrow=npeaks, ncol=1)
  wbfile <- paste0(getwd(), "/", subFile, ".xlsx")
  endRow <- npeaks+1
  #detach("package:xlsx", unload=TRUE)
  wb <- loadWorkbook(wbfile, create = TRUE)
  
  createSheet(wb, name = filelist)
  setRowHeight(wb, sheet = filelist, row = 2:endRow, height = 75)
  
  printit = cbind("Intensity"=addCol, peaklist)
  setColumnWidth(wb, sheet = filelist, column = 1, width = 5500)

  
  writeWorksheet(wb, printit, sheet = filelist)
  saveWorkbook(wb)
  rm(wb)
  xlcFreeMemory()
  # gc()
  # jgc()
  
}
