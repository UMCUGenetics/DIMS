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
  detach("package:xlsx", unload=TRUE)
  wb <- loadWorkbook(wbfile, create = TRUE)
  
  createSheet(wb, name = filelist)
  setRowHeight(wb, sheet = filelist, row = 2:endRow, height = 75)
  
  printit = cbind("Intensity"=addCol, peaklist)
  setColumnWidth(wb, sheet = filelist, column = 1, width = 5500)
  
  if (imageNum == 2) {
    # Judith
    printit = cbind("Z-scores"=addCol, "Intensity"=addCol, peaklist)
    #   # Ruben
    #   printit = cbind("Time-series-plot"=addCol, "Intensity"=addCol, peaklist)
    setColumnWidth(wb, sheet = filelist, column = 2, width = 5500)
  }
  
  ###Images
  for (i in 1:npeaks) {
    
    # if ((i %% 100)==0){
    #   message(i);
    #   message(Sys.time());
    # }
    
    if (!adducts){
      # only picture if identified
      if ((peaklist[i,"assi_HMDB"]=="") & (peaklist[i,"iso_HMDB"]=="")) next
    }
    
    # j <- i+1 
    f = peaklist[i,"index"]
    # 
    # file_png <- paste(plotdir, "/", subName[1], sprintf("%05d", as.numeric(f)), ".png", sep="")
    # 
    # formloc_box <- paste(filelist, "!$A$",j, sep="")
    # name_box <- paste("A", i, runif(1, min=0.001), sep="")
    # createName(wb, name = name_box , formula = formloc_box, overwrite=TRUE)
    # addImage(wb, filename = file_png, name = name_box , originalSize = FALSE)
    # 
    # if (imageNum == 2) {  
      j <- i+1
      
      # Ruben
      # file_png <- paste(plotdir, "/", subName[2], sprintf("%05d", f), ".png", sep="")
      
      # Judith
      #file_png <- paste(plotdir, "/", sprintf("%05d", as.numeric(f)), subName[2], ".png", sep="")
      
      # hmdb 
      file_png <- paste0(plotdir, "/", peaklist[i, "HMDB_code"], subName, ".png")
      
      # formloc_box = the excel sheet, column and row in one string
      formloc_box <- paste(filelist, "!$A$",j, sep="")
      name_box <- paste("B", i, runif(1, min=0.001), sep="")
      createName(wb, name = name_box , formula = formloc_box, overwrite=TRUE)
      addImage(wb, filename = file_png, name = name_box , originalSize = FALSE)
    # }
    jgc()
  }
  #########
  
  writeWorksheet(wb, printit, sheet = filelist)
  saveWorkbook(wb)
  rm(wb)
  xlcFreeMemory()
  # gc()
  # jgc()
  
}
