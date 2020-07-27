#!/usr/bin/env Rscript

# used for when init.RData has to be created manually
# arg1 : path to sampleNames.txt or whatever the name of the samplesheet txt file may be
# arg2 : amount of technical replicates (usually 3)

args <- commandArgs(trailingOnly=TRUE)
df <- read.csv(args[1], sep="\t")
nrepl <- as.numeric(args[2])

sampleNames <- trimws(as.vector(unlist(df[1])))
nsampgrps <- length(sampleNames)/nrepl
groupNames <- trimws(as.vector(unlist(df[2])))
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

# just to preview
head(repl.pattern)

save(repl.pattern, file="init.RData", version=2)
