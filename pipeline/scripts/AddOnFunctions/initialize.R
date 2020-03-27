initialize <- function(outputfolder, hmdb, z_score=1){
  # load("./results/repl.pattern.positive.RData")
  # repl.pattern.pos = repl.pattern.filtered
  # rm(repl.pattern.filtered)
  #
  # load("./results/repl.pattern.negative.RData")
  # repl.pattern.neg = repl.pattern.filtered
  # rm(repl.pattern.filtered)


  options(digits=16)

  # Load pos and neg adduct sums
  load(paste("adductSums_negative.RData"))
  outlist.neg.adducts.HMDB=outlist.tot
  load(paste("adductSums_positive.RData"))
  outlist.pos.adducts.HMDB=outlist.tot
  rm(outlist.tot)

  # Only continue with patients (columns) that are in both pos and neg
  tmp = intersect(colnames(outlist.neg.adducts.HMDB), colnames(outlist.pos.adducts.HMDB))
  outlist.neg.adducts.HMDB = outlist.neg.adducts.HMDB[,tmp]
  outlist.pos.adducts.HMDB = outlist.pos.adducts.HMDB[,tmp]

  # Find indexes of neg hmdb code that are also found in pos and vice versa
  index.neg = which(rownames(outlist.neg.adducts.HMDB) %in% rownames(outlist.pos.adducts.HMDB))
  index.pos = which(rownames(outlist.pos.adducts.HMDB) %in% rownames(outlist.neg.adducts.HMDB))

  # Get number of columns
  # Only continue with HMDB codes (rows) that were found in both pos and neg mode and remove last column
  tmp.pos = outlist.pos.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], 1:(dim(outlist.pos.adducts.HMDB)[2]-1)]
  tmp.hmdb_name.pos = outlist.pos.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], dim(outlist.pos.adducts.HMDB)[2]]
  tmp.pos.left = outlist.pos.adducts.HMDB[-index.pos,]

  tmp.neg = outlist.neg.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], 1:(dim(outlist.neg.adducts.HMDB)[2]-1)]
  tmp.neg.left = outlist.neg.adducts.HMDB[-index.neg,]

  # Combine positive and negative numbers and paste back HMDB column
  tmp = apply(tmp.pos, 2,as.numeric) + apply(tmp.neg, 2,as.numeric)
  rownames(tmp) = rownames(tmp.pos)
  tmp = cbind(tmp, "HMDB_name"=tmp.hmdb_name.pos)
  adducts.neg.pos = rbind(tmp, tmp.pos.left,tmp.neg.left)

  # Create new matrix
  dummy.neg = rep(NA, dim(adducts.neg.pos)[1])
  outlist.adducts.HMDB = cbind("mzmed.pgrp"=dummy.neg,
                               "fq.best"=dummy.neg,
                               "fq.worst"=dummy.neg,
                               "nrsamples"=dummy.neg,
                               "mzmin.pgrp"=dummy.neg,
                               "mzmax.pgrp"=dummy.neg,
                               adducts.neg.pos)

  # Add assi_HMDB column with all the HMDB IDs
  outlist.adducts.HMDB=cbind(outlist.adducts.HMDB, "assi_HMDB"=rownames(outlist.adducts.HMDB))
  ###################################################################

  if (z_score == 1) {
    control_label = "C"
    case_label= "P"

    # Get all patient IDs
    tmp=colnames(outlist.adducts.HMDB)[7:length(colnames(outlist.adducts.HMDB))]
    patients=tmp[grep("P", tmp, fixed = TRUE)]

    # Remove everything after .1 (P128.1 -> P128)
    patients=unique(as.vector(unlist(lapply(strsplit(patients, ".", fixed = TRUE), function(x) x[1]))))

    # ToDo: If 2 P's in sample names!!!!!!!!!!!!!
    # patients=sort(as.numeric(unique(as.vector(unlist(lapply(strsplit(patients, "_P", fixed = TRUE), function(x) x[2]))))))

    # Sort on patient ID (128, 135 ...)
    patients=sort(as.numeric(unique(as.vector(unlist(lapply(strsplit(patients, "P", fixed = TRUE), function(x) x[2]))))))

    # Add Z-scores and create plots
    outlist.adducts.stats = statistics_z_2(peaklist = as.data.frame(outlist.adducts.HMDB), #as.data.frame(adducts.neg.pos),
                                         # plotdir = paste0(outputfolder, project, "/plots/adducts/"),
                                         # filename = paste0(outputfolder, project, "/allpgrps_stats.txt"),
                                         outputfolder = outputfolder,
                                         control_label = control_label,
                                         case_label = case_label,
                                         sortCol = "mzmed.pgrp",
                                         patients = patients,
                                         plot = FALSE,
                                         adducts = TRUE)


    # Remove the empty columns that were added earlier ..
    outlist.adducts.stats = outlist.adducts.stats[,-c(1:6)]
    ###################################################################

    tmp=which(colnames(outlist.adducts.stats)=="HMDB_name")
    order.index.int.adduct=order(colnames(outlist.adducts.stats)[1:(tmp-1)])
    outlist.adducts.stats.sorted = cbind(outlist.adducts.stats[,order.index.int.adduct],outlist.adducts.stats[,tmp:(dim(outlist.adducts.stats)[2])])

    tmp.index=grep("_Zscore", colnames(outlist.adducts.stats.sorted), fixed = TRUE)
    tmp.index.order=order(colnames(outlist.adducts.stats.sorted[,tmp.index]))
    tmp = outlist.adducts.stats.sorted[,tmp.index[tmp.index.order]]
    outlist.adducts.stats.sorted=outlist.adducts.stats.sorted[,-tmp.index]
    outlist.adducts.stats.sorted=cbind(outlist.adducts.stats.sorted,tmp)

    outlist.adducts.stats=outlist.adducts.stats.sorted
    rm(outlist.adducts.stats.sorted)
    outlist.adducts = outlist.adducts.stats
    ###################################################################
  } else {
    outlist.adducts = outlist.adducts.HMDB
  }

  outlist.adducts=cbind("HMDB_code"=rownames(outlist.adducts), outlist.adducts)

  #load("./db/HMDB_with_info_relevance.RData")
  #load("./db/HMDB_with_info_relevance_IS.RData")
  # load("./db/HMDB_with_info_relevance_IS_C5OH.RData")
  load(hmdb)



  PeaksInList = which(rownames(outlist.adducts) %in% rownames(rlvnc))
  outlist.adducts = cbind(outlist.adducts[PeaksInList,],as.data.frame(rlvnc[rownames(outlist.adducts)[PeaksInList],]))

  load("outlist_identified_negative.RData")
  outlist.neg.ident=outlist.ident
  outlist.neg.not.ident=outlist.not.ident
  rm(outlist.ident, outlist.not.ident)

  load("outlist_identified_positive.RData")
  outlist.pos.ident=outlist.ident
  outlist.pos.not.ident=outlist.not.ident
  rm(outlist.ident, outlist.not.ident)

  #save(outlist.neg.not.ident, outlist.pos.not.ident, outlist.neg.ident, outlist.pos.ident, outlist.adducts, file=rdataFile)
  save(outlist.adducts, outlist.neg.ident, outlist.pos.ident, file="ViewInShiny.RData")

  return(list("adducts"=outlist.adducts, "negative"=outlist.neg.ident, "positive"=outlist.pos.ident))
}
