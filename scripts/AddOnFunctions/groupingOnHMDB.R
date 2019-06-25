groupingOnHMDB <- function(outdir, fileIn, scanmode, ppm=2) {
  # fileIn="./results/hmdb_part/negative_hmdb.14.RData"
  # fileIn="/hpc/shared/dbg_mz/marcel/DIMSinDiagnostics/results/hmdb_part/positive_hmdb.187.RData"
  # scanmode="negative"
  # outdir="./results"
  # ppm=2
  
  options(digits=16)
  load(fileIn) # outlist_part(HMDB_add_iso)
  HMDB_add_iso = outlist_part
  
  # Windows and Unix-like
  batch = strsplit(fileIn, "/",fixed = TRUE)[[1]]
  batch = batch[length(batch)] 
  batch = strsplit(batch, ".",fixed = TRUE)[[1]][2]
  
  load(paste(outdir, "specpks_all", paste(scanmode, "RData", sep="."), sep="/"))
  outlist.copy = outlist.tot
  grouped <- rep(0, length(outlist.copy))
  outlist.copy <- cbind (outlist.copy, grouped)
  rm(outlist.tot)
  
  load(paste0(outdir, "/repl.pattern.", scanmode,".RData"))
  load(paste(outdir, "breaks.fwhm.RData", sep="/"))
  
  outpgrlist = NULL
  
  if (scanmode=="negative"){
    label = "MNeg"
    # HMDB_add_iso=HMDB_add_iso.Neg
  } else {
    label = "Mpos"
    # HMDB_add_iso=HMDB_add_iso.Pos
  }
  
  # First group on HMDB masses
  while (dim(HMDB_add_iso)[1] > 0) {  
    index = 1
    # message(HMDB_add_iso[index,"CompoundName"])
    
    mass = as.numeric(HMDB_add_iso[index,label])
    mtol = (mass*ppm)/10^6
    
    mzmed = as.numeric(outlist.copy[,"mzmed.pkt"])
    selp = which((mzmed > (mass - mtol)) & (mzmed < (mass + mtol)))
    tmplist = outlist.copy[selp,,drop=FALSE]
    
    nrsamples = length(selp)
    if (nrsamples > 0) {
      # message(paste("Bingo ",n))
      
      mzmed.pgrp = mean(as.numeric(outlist.copy[selp, "mzmed.pkt"]))
      # mzmed.pgrp = median(as.numeric(outlist.copy[selp, "mzmed.pkt"]))
      mzmin.pgrp = mass - mtol
      mzmax.pgrp = mass + mtol
      
      fq.worst.pgrp = as.numeric(max(outlist.copy[selp, "fq"]))
      fq.best.pgrp = as.numeric(min(outlist.copy[selp, "fq"]))
      ints.allsamps = rep(0, length(names(repl.pattern.filtered)))
      names(ints.allsamps) = names(repl.pattern.filtered) # same order as sample list!!!
      
      # # Check for each sample if multiple peaks exists, if so take the sum!
      labels=unique(tmplist[,"samplenr"])
      ints.allsamps[labels] = as.vector(unlist(lapply(labels, function(x) {sum(as.numeric(tmplist[which(tmplist[ , "samplenr"]==x), "height.pkt"]))})))
      # ints.allsamps[labels] = as.vector(unlist(lapply(labels, function(x) {as.numeric(tmplist[which(tmplist[ , "samplenr"]==x), "height.pkt"])})))
      
      # Identification
      # assi_HMDB = iso_HMDB = HMDB_code = ""
      assi_HMDB = iso_HMDB = HMDB_code = NA
      tmplist.mass.iso = tmplist.mass.adduct = NULL
      # index = which(HMDB_add_iso[,label]==mass)
      
      # Consider groups off 4ppm
      mass.all = as.numeric(HMDB_add_iso[,label])
      index = which((mass.all > (mass - mtol)) & (mass.all < (mass + mtol)))
      # index = which(mass.all < (mass + 2*mtol))
      tmplist.mass = HMDB_add_iso[index,,drop=FALSE]
      
      if (dim(tmplist.mass)[1]>0) {
        
        index.iso = grep(" iso ", tmplist.mass[, "CompoundName"], fixed = TRUE)
        if (length(index.iso)>0){
          tmplist.mass.iso = tmplist.mass[index.iso,,drop=FALSE]
          tmplist.mass = tmplist.mass[-index.iso,,drop=FALSE]
        }
        
        if (dim(tmplist.mass)[1]>0) {        
          index.adduct = grep(" [M", tmplist.mass[, "CompoundName"], fixed = TRUE)
          if (length(index.adduct)>0){
            tmplist.mass.adduct = tmplist.mass[index.adduct,,drop=FALSE]
            tmplist.mass = tmplist.mass[-index.adduct,,drop=FALSE]
          }  
        }  
        
        # First compouds without adducts or isotopes
        if (dim(tmplist.mass)[1]>0) {
          
          # pure compounds
          assi_HMDB = as.character(paste(as.character(tmplist.mass[, "CompoundName"]), collapse = ";"))
          HMDB_code = as.character(paste(as.character(rownames(tmplist.mass)), collapse = ";"))
          theormz_HMDB = as.numeric(tmplist.mass[1,label])
          
          # adducts
          if (!is.null(tmplist.mass.adduct)) {
            if (dim(tmplist.mass.adduct)[1]>0) {
              if (is.na(assi_HMDB)){
                assi_HMDB = as.character(paste(as.character(tmplist.mass.adduct[, "CompoundName"]), collapse = ";"))
                HMDB_code = as.character(paste(as.character(rownames(tmplist.mass.adduct)), collapse = ";"))
              } else {
                assi_HMDB = paste(assi_HMDB, as.character(paste(as.character(tmplist.mass.adduct[, "CompoundName"]), collapse = ";")), sep = ";")
                HMDB_code = paste(HMDB_code, as.character(paste(as.character(rownames(tmplist.mass.adduct)), collapse = ";")), sep = ";")
              }}}
          
          # isotopes
          if (!is.null(tmplist.mass.iso)) {
            if (dim(tmplist.mass.iso)[1]>0) {
              iso_HMDB = as.character(paste(as.character(tmplist.mass.iso[, "CompoundName"]), collapse = ";"))
            }}
          
          # No pure compounts  
        } else if (!is.null(tmplist.mass.adduct)) {
          
          theormz_HMDB = as.numeric(tmplist.mass.adduct[1,label])
          
          # adducts
          if (!is.null(tmplist.mass.adduct)) {
            if (dim(tmplist.mass.adduct)[1]>0) {
              if (is.na(assi_HMDB)){
                assi_HMDB = as.character(paste(as.character(tmplist.mass.adduct[, "CompoundName"]), collapse = ";"))
                HMDB_code = as.character(paste(as.character(rownames(tmplist.mass.adduct)), collapse = ";"))
              } else {
                assi_HMDB = paste(assi_HMDB, as.character(paste(as.character(tmplist.mass.adduct[, "CompoundName"]), collapse = ";")), sep = ";")
                HMDB_code = paste(HMDB_code, as.character(paste(as.character(rownames(tmplist.mass.adduct)), collapse = ";")), sep = ";")
              }}}
          
          # isotopes
          if (!is.null(tmplist.mass.iso)) {
            if (dim(tmplist.mass.iso)[1]>0) {
              iso_HMDB = as.character(paste(as.character(tmplist.mass.iso[, "CompoundName"]), collapse = ";"))
            }}
          
          # only isotopes  
        } else if (!is.null(tmplist.mass.iso)) {
          
          if (dim(tmplist.mass.iso)[1]>0) {
            theormz_HMDB = as.numeric(tmplist.mass.iso[1,label])
            iso_HMDB = as.character(paste(as.character(tmplist.mass.iso[, "CompoundName"]), collapse = ";"))
          }
        }  
        
        
        # if(grepl(" iso ", HMDB_add_iso[index, "CompoundName"])){
        #   
        #   ############# this will not work when run in parallel!!!!!!!#################################################################################################
        #   #############################################################################################################################################################            
        #   # mainpeak <- strsplit(HMDB_add_iso[selp[i],"CompoundName"]," iso ")[[1]][1]
        #   # 
        #   # # Check if peak without isotope occurs, this assumes that peaklist is ordered on mass!!! this will not work when run in parallel!!!!!!!
        #   # if(length(grep(mainpeak, assi_HMDB, fixed=TRUE)) > 0){
        #   #############################################################################################################################################################
        #   
        #   # iso_HMDB = as.character(paste(iso_HMDB,as.character(HMDB_add_iso[index[i],"CompoundName"]), sep=";"))
        #   iso_HMDB = as.character(paste(as.character(HMDB_add_iso[index,"CompoundName"]), collapse = ";"))
        #   theormz_HMDB = NA
        #   
        # } else {
        #   # assi_HMDB = as.character(paste(assi_HMDB,as.character(HMDB_add_iso[index[i], "CompoundName"]), sep=";"))
        #   # HMDB_code = as.character(paste(HMDB_code, as.character(rownames(HMDB_add_iso)[index[i]]), sep=";"))
        #   assi_HMDB = as.character(paste(as.character(HMDB_add_iso[index, "CompoundName"]), collapse = ";"))
        #   HMDB_code = as.character(paste(as.character(rownames(HMDB_add_iso)[index]), collapse = ";"))
        #   theormz_HMDB = as.numeric(mass)
        # }
      }
      
      outpgrlist = rbind(outpgrlist, cbind(data.frame(mzmed.pgrp, "fq.best"=fq.best.pgrp, "fq.worst"=fq.worst.pgrp, nrsamples, mzmin.pgrp, mzmax.pgrp),
                                           t(as.matrix(ints.allsamps)),
                                           data.frame(assi_HMDB, iso_HMDB, HMDB_code, theormz_HMDB)))
    }
    
    if (length(selp)>0) outlist.copy[selp, "grouped"] = 1
    HMDB_add_iso = HMDB_add_iso[-index,]
    
    # n=n+1
  }
  
  dir.create(paste(outdir, "grouping_hmdb", sep="/"), showWarnings = FALSE)
  save(outpgrlist, file=paste(paste(outdir, "grouping_hmdb", sep="/"), paste(paste(batch, scanmode, sep="_"), "RData", sep="."), sep="/"))
  
  dir.create(paste(outdir, "grouping_hmdb_done", sep="/"), showWarnings = FALSE)
  save(outlist.copy, file=paste(paste(outdir, "grouping_hmdb_done", sep="/"), paste(paste(batch, scanmode, sep="_"), "RData", sep="."), sep="/"))
  
  # message(Sys.time())
}  