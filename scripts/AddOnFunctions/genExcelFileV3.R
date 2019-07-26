genExcelFileV3 <- function(peaklist, subFile, plot = TRUE) {
  #peaklist <- outlist
  #subFile <- 1
  filelist <- "AllPeakGroups"
  
  wbfile <- paste0(getwd(), "/", subFile, ".xlsx")
  
  npeaks = dim(peaklist)[1]
  ncol = dim(peaklist)[2]
  
  endRow <- npeaks+1
  #detach("package:xlsx", unload=TRUE)
  wb <- createWorkbook()
  
  addWorksheet(wb, filelist) 

  if (plot) {
    ###  insert first column
    #intensities <- matrix(c(""), nrow=npeaks, ncol=1)
    #writeData(wb, sheet = 1, cbind(intensities, peaklist))
    writeData(wb, sheet = 1, peaklist)
    setColWidths(wb, 1, cols = 1:ncol, widths = 20)
    setRowHeights(wb, 1, rows = 1:npeaks, heights = 20)
    
    #setColWidths(wb, 1, cols = 1, widths = 35)
    #setColWidths(wb, 1, cols = 2:ncol, widths = 20)
    #setRowHeights(wb, 1, rows = 1:npeaks, heights = 150)
    
    bloop <- peaklist %>% select(-HMDB_name, -assi_HMDB,
                                 -name, -relevance, -descr, 
                                 -origin, -fluids, -tissue, 
                                 -disease, -pathway)
    ## create plot objects
    for (i in 1:npeaks) {
      bloop2 <- bloop %>% slice(i) %>% melt("HMDB_code")
      names(bloop2) <- c("HMDB_code", "replicate", "intensity")
      bloop2$intensity <- as.numeric(bloop2$intensity)
      
      p1 <- ggplot(bloop2, aes(replicate,intensity)) +
        ggtitle(bloop2[1,1]) +
        geom_bar(aes(fill=intensity),stat='identity') +
        labs(x='',y='intensity') +
        theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=3), 
              legend.position='none')
      #print(p1)
      ggsave(paste0("plots/",bloop2[1,1],".png"), plot=p1) # height=w/2.5, width=w, units="in"
      #insertPlot(wb, 1, width = dim(bloop2)[1]*0.5, height = 5, startRow = i+1, fileType = "png", units = "cm")
    }
  } else {
    setColWidths(wb, 1, cols = 1:ncol, widths = 20)
    setRowHeights(wb, 1, rows = 1:npeaks, heights = 20)
    writeData(wb, sheet = 1, peaklist)
  }
  
  ## Save workbook
  saveWorkbook(wb, wbfile, overwrite = TRUE)
  
}
