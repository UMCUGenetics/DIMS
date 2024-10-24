initialize <- function(){

  # load("output/repl.pattern.positive.RData")
  # repl.pattern.pos = repl.pattern.filtered
  # rm(repl.pattern.filtered)
  #
  # load("output/repl.pattern.negative.RData")
  # repl.pattern.neg = repl.pattern.filtered
  # rm(repl.pattern.filtered)

  #load("output/init.RData")

  options(digits=16)

  load(paste("input", "adductSums_negative.RData", sep="/"))
  outlist.neg.adducts.HMDB=outlist.tot
  load(paste("input", "adductSums_positive.RData", sep="/"))
  outlist.pos.adducts.HMDB=outlist.tot
  rm(outlist.tot)

  tmp = intersect(colnames(outlist.neg.adducts.HMDB), colnames(outlist.pos.adducts.HMDB))
  outlist.neg.adducts.HMDB = outlist.neg.adducts.HMDB[,tmp]
  outlist.pos.adducts.HMDB = outlist.pos.adducts.HMDB[,tmp]

  # samples = groupNames[which(repl.pattern.neg[]=="character(0)")]
  # if (length(samples)>0){
  #   for (i in 1:length(samples)){
  #     outlist.neg.adducts.HMDB=cbind(rep(0,dim(outlist.neg.adducts.HMDB)[1]),outlist.neg.adducts.HMDB)
  #     colnames(outlist.neg.adducts.HMDB)[1]=samples[i]
  #   }
  #   outlist.neg.adducts.HMDB=cbind(outlist.neg.adducts.HMDB[,groupNames],outlist.neg.adducts.HMDB[,dim(outlist.neg.adducts.HMDB)[2]])
  # }
  #
  # samples = groupNames[which(repl.pattern.pos[]=="character(0)")]
  # if (length(samples)>0){
  #   for (i in 1:length(samples)){
  #     outlist.pos.adducts.HMDB=cbind(rep(0,dim(outlist.pos.adducts.HMDB)[1]),outlist.pos.adducts.HMDB)
  #     colnames(outlist.pos.adducts.HMDB)[1]=samples[i]
  #   }
  #   outlist.pos.adducts.HMDB=cbind(outlist.pos.adducts.HMDB[,groupNames],outlist.pos.adducts.HMDB[,dim(outlist.pos.adducts.HMDB)[2]])
  # }

  index.neg = which(rownames(outlist.neg.adducts.HMDB) %in% rownames(outlist.pos.adducts.HMDB))
  index.pos = which(rownames(outlist.pos.adducts.HMDB) %in% rownames(outlist.neg.adducts.HMDB))

  tmp.pos = outlist.pos.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], 1:(dim(outlist.pos.adducts.HMDB)[2]-1)]
  tmp.hmdb_name.pos = outlist.pos.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], dim(outlist.pos.adducts.HMDB)[2]]
  tmp.pos.left = outlist.pos.adducts.HMDB[-index.pos,]

  tmp.neg = outlist.neg.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], 1:(dim(outlist.neg.adducts.HMDB)[2]-1)]
  tmp.neg.left = outlist.neg.adducts.HMDB[-index.neg,]

  tmp = apply(tmp.pos, 2,as.numeric) + apply(tmp.neg, 2,as.numeric)
  rownames(tmp) = rownames(tmp.pos)
  tmp = cbind(tmp, "HMDB_name"=tmp.hmdb_name.pos)
  adducts.neg.pos = rbind(tmp, tmp.pos.left,tmp.neg.left)

  dummy.neg = rep(NA, dim(adducts.neg.pos)[1])
  outlist.adducts.HMDB = cbind("mzmed.pgrp"=dummy.neg,
                               "fq.best"=dummy.neg,
                               "fq.worst"=dummy.neg,
                               "nrsamples"=dummy.neg,
                               "mzmin.pgrp"=dummy.neg,
                               "mzmax.pgrp"=dummy.neg,
                               adducts.neg.pos)

  outlist.adducts.HMDB=cbind(outlist.adducts.HMDB, "assi_HMDB"=rownames(outlist.adducts.HMDB))
  ###################################################################

  control_label = "C"
  case_label= "P"

  tmp=colnames(outlist.adducts.HMDB)[7:length(colnames(outlist.adducts.HMDB))]
  patients=tmp[grep("P", tmp, fixed = TRUE)]
  patients=unique(as.vector(unlist(lapply(strsplit(patients, ".", fixed = TRUE), function(x) x[1]))))
  # ToDo: If 2 P's in sample names!!!!!!!!!!!!!
  # patients=sort(as.numeric(unique(as.vector(unlist(lapply(strsplit(patients, "_P", fixed = TRUE), function(x) x[2]))))))
  patients=sort(as.numeric(unique(as.vector(unlist(lapply(strsplit(patients, "P", fixed = TRUE), function(x) x[2]))))))

  outlist.adducts.stats = statistics_z(as.data.frame(outlist.adducts.HMDB), #as.data.frame(adducts.neg.pos),
                                       "output/plots/adducts",
                                       "output/allpgrps_stats.txt",
                                       control_label, case_label, sortCol="mzmed.pgrp", patients, plot=FALSE, adducts=TRUE)

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
  ###################################################################

  #load("./db/HMDB_with_info_relevance.RData")
  #load("./db/HMDB_with_info_relevance_IS.RData")
  load("../db/HMDB_with_info_relevance_IS_C5OH.RData")

  outlist.adducts.stats=cbind("HMDB_code"=rownames(outlist.adducts.stats), outlist.adducts.stats)

  # tmp = matrix(
  #      rep(NA,dim(outlist.adducts.stats)[1]*dim(rlvnc)[2]),
  #      nrow=dim(outlist.adducts.stats)[1],
  #      ncol=dim(rlvnc)[2],
  #      byrow = TRUE)
  # colnames(tmp)=colnames(rlvnc)

  outlist.adducts = outlist.adducts.stats
  PeaksInList = which(rownames(outlist.adducts) %in% rownames(rlvnc))
  outlist.adducts = cbind(outlist.adducts[PeaksInList,],as.data.frame(rlvnc[rownames(outlist.adducts)[PeaksInList],]))

  load("input/outlist_identified_negative.RData")
  outlist.neg.ident=outlist.ident
  outlist.neg.not.ident=outlist.not.ident
  rm(outlist.ident, outlist.not.ident)

  load("input/outlist_identified_positive.RData")
  outlist.pos.ident=outlist.ident
  outlist.pos.not.ident=outlist.not.ident
  rm(outlist.ident, outlist.not.ident)

  #save(outlist.neg.not.ident, outlist.pos.not.ident, outlist.neg.ident, outlist.pos.ident, outlist.adducts, file=rdataFile)
  save(outlist.adducts, outlist.neg.ident, outlist.pos.ident, file="output/ViewInShiny.RData")

  return(list("adducts"=outlist.adducts, "negative"=outlist.neg.ident, "positive"=outlist.pos.ident))
}
