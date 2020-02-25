#!/usr/bin/env Rscript

# run it from the input dir that contains sampleNames.txt
# to make init.RData in the same dir

df <- read.csv("sampleNames.txt", sep="\t")

args <- commandArgs(trailingOnly=TRUE)
nrepl <- as.numeric(args[1])

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

# just to preview
head(repl.pattern)

save(repl.pattern, file="init.RData", version=2)
