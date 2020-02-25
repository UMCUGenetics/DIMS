#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)

df <- read.csv(args[1], sep="\t")
nrepl <- as.numeric(args[2])

sampleNames <- trimws(as.vector(unlist(df$File_Name)))
nsampgrps <- length(sampleNames)/nrepl
groupNames <- trimws(as.vector(unlist(df$Sample_Name)))
groupNames <- gsub('[^-.[:alnum:]]','_',groupNames)
groupNamesUnique <- unique(groupNames)
groupNamesNotUnique <- groupNames[duplicated(groupNames)]

repl.pattern <- c()
for (a in 1:nsampgrps) {
  tmp <- c()
  for (b in nrepl:1) {
    i <- ((a*nrepl)-b)+1
    tmp <- c(tmp, sampleNames[i])
  }
  repl.pattern <- c(repl.pattern, list(tmp))
}

names(repl.pattern) <- groupNamesUnique

#just to preview
head(repl.pattern)

save(repl.pattern, file=args[2], version=2)
