#!/usr/bin/Rscript

.libPaths(new = "/hpc/local/CentOS7/dbg_mz/R_libs/3.6.2")

# load required packages 
library("ggplot2")
library("reshape2")
library("openxlsx")
library("loder")

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n", sep = "")

outdir <- cmd_args[1] #"/Users/nunen/Documents/Metab/test_set"
project <- cmd_args[2] #"test"
matrix <- cmd_args[3] #"DBS"
hmdb <- cmd_args[4] #"/Users/nunen/Documents/Metab/DIMS/db/HMDB_with_info_relevance_IS_C5OH.RData"
scripts <- cmd_args[5] #"/Users/nunen/Documents/Metab/DIMS/scripts"
z_score <- as.numeric(cmd_args[6])
plot <- TRUE
init <- "logs/init.RData"

export <- TRUE
control_label <- "C"
case_label <- "P"
imagesize_multiplier <- 2

rundate <- Sys.Date()

plotdir <- paste0(outdir, "/plots/adducts")
dir.create(paste0(outdir, "/plots"), showWarnings = F)
dir.create(plotdir, showWarnings = F)

options(digits=16)

# sum positive and negative adductsums

# Load pos and neg adduct sums
load(paste0(outdir,"/adductSums_negative.RData"))
outlist.neg.adducts.HMDB <- outlist.tot

load(paste0(outdir,"/adductSums_positive.RData"))
outlist.pos.adducts.HMDB <- outlist.tot
rm(outlist.tot)

# Only continue with patients (columns) that are in both pos and neg
tmp <- intersect(colnames(outlist.neg.adducts.HMDB), colnames(outlist.pos.adducts.HMDB))
outlist.neg.adducts.HMDB <- outlist.neg.adducts.HMDB[,tmp]
outlist.pos.adducts.HMDB <- outlist.pos.adducts.HMDB[,tmp]

# Find indexes of neg hmdb code that are also found in pos and vice versa
index.neg <- which(rownames(outlist.neg.adducts.HMDB) %in% rownames(outlist.pos.adducts.HMDB))
index.pos <- which(rownames(outlist.pos.adducts.HMDB) %in% rownames(outlist.neg.adducts.HMDB))

# Get number of columns
# Only continue with HMDB codes (rows) that were found in both pos and neg mode and remove last column
tmp.pos <- outlist.pos.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], 1:(dim(outlist.pos.adducts.HMDB)[2]-1)]
tmp.hmdb_name.pos <- outlist.pos.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], dim(outlist.pos.adducts.HMDB)[2]]
tmp.pos.left <- outlist.pos.adducts.HMDB[-index.pos,]

tmp.neg <- outlist.neg.adducts.HMDB[rownames(outlist.pos.adducts.HMDB)[index.pos], 1:(dim(outlist.neg.adducts.HMDB)[2]-1)]
tmp.neg.left <- outlist.neg.adducts.HMDB[-index.neg,]

# Combine positive and negative numbers and paste back HMDB column
tmp <- apply(tmp.pos, 2,as.numeric) + apply(tmp.neg, 2,as.numeric)
rownames(tmp) <- rownames(tmp.pos)
tmp <- cbind(tmp, "HMDB_name"=tmp.hmdb_name.pos)
outlist <- rbind(tmp, tmp.pos.left, tmp.neg.left)

# Create new matrix
#outlist <- cbind("mzmed.pgrp"=NA,
#                 "fq.best"=NA,
#                 "fq.worst"=NA,
#                 "nrsamples"=dummy.neg,
#                 "mzmin.pgrp"=dummy.neg,
#                 "mzmax.pgrp"=dummy.neg,
#                 adducts.neg.pos)

# Filter 
load(hmdb)

peaksInList <- which(rownames(outlist) %in% rownames(rlvnc))
outlist <- cbind(outlist[peaksInList,],as.data.frame(rlvnc[rownames(outlist)[peaksInList],]))

outlist <- outlist[-grep("Exogenous", outlist[,"relevance"], fixed = TRUE),]
outlist <- outlist[-grep("exogenous", outlist[,"relevance"], fixed = TRUE),]
outlist <- outlist[-grep("Drug", outlist[,"relevance"], fixed = TRUE),]

# Add HMDB_code column with all the HMDB ID and sort on it
outlist <- cbind(outlist, "HMDB_code" = rownames(outlist))
outlist <- outlist[order(outlist[,"HMDB_code"]),]

# Create excel
filelist <- "AllPeakGroups"

wb <- createWorkbook("SinglePatient")
addWorksheet(wb, filelist)
#outlist.backup <- outlist 
#outlist <- outlist.backup

# Add Z-scores and create plots
if (z_score == 1) {
  ########## Statistics: Z-score
  outlist <- cbind(plots = NA, outlist)
  #outlist <- as.data.frame(outlist)
  
  startcol <- dim(outlist)[2] + 3 
  
  # Get columns with control intensities 
  control_col_ids <- grep(control_label, colnames(outlist), fixed = TRUE)
  control_columns <- outlist[, control_col_ids]
  
  # Get columns with patient intensities 
  patient_col_ids <- grep(case_label, colnames(outlist), fixed = TRUE)
  patient_columns <- outlist[, patient_col_ids]
  
  intensity_col_ids <- c(control_col_ids, patient_col_ids)
  
  # set intensities of 0 to NA?
  outlist[,intensity_col_ids][outlist[,intensity_col_ids] == 0] <- NA
  
  # calculate mean and sd for Control group
  outlist$avg.ctrls <- apply(control_columns, 1, function(x) mean(as.numeric(x),na.rm = TRUE))
  outlist$sd.ctrls <- apply(control_columns, 1, function(x) sd(as.numeric(x),na.rm = TRUE))
  
  # Make and add columns with zscores
  cnames.z <- NULL
  for (i in intensity_col_ids) {
    cname <- colnames(outlist)[i]
    cnames.z <- c(cnames.z, paste(cname, "Zscore", sep="_"))
    zscores.1col <- (as.numeric(as.vector(unlist(outlist[ , i]))) - outlist$avg.ctrls) / outlist$sd.ctrls
    outlist <- cbind(outlist, zscores.1col)
  }
  colnames(outlist)[startcol:ncol(outlist)] <- cnames.z
  
  patient_ids <- unique(as.vector(unlist(lapply(strsplit(colnames(patient_columns), ".", fixed = TRUE), function(x) x[1]))))
  patient_ids <- patient_ids[order(nchar(patient_ids), patient_ids)] # sorts 
  
  temp_png <- NULL
  
  # Iterate through every row, make boxplot, insert into excel, and make Zscore for every patient
  for (p in 1:nrow(outlist)) {
    ########################## box plot ###########################
    hmdb_name <- rownames(outlist[p,])
    
    intensities <- list(as.numeric(as.vector(unlist(control_columns[p,]))))
    labels <- c("C", patient_ids)
    
    for (i in 1:length(patient_ids)) {
      id <- patient_ids[i]
      # get all intensities that start with ex. P18. (so P18.1, P18.2, but not x_P18.1 and not P180.1)
      p.int <- as.numeric(as.vector(unlist(outlist[p, names(patient_columns[1,])[startsWith(names(patient_columns[1,]), paste0(id, "."))]])))
      intensities[[i+1]] <- p.int
    }
    
    intensities <- setNames(intensities, labels)
    
    plot_width <- length(labels) * 12 + 90
    
    plot.new()
    if (export) {
      png(filename = paste0(plotdir, "/", hmdb_name, "_box.png"), 
          width = plot_width, 
          height = 280)
    }
    par(oma=c(2,0,0,0))
    boxplot(intensities, 
            col=c("green", rep("red", length(intensities)-1)),
            names.arg = labels, 
            las=2, 
            main = hmdb_name) 
    dev.off()
    
    file_png <- paste0(plotdir, "/", hmdb_name, "_box.png")
    if (is.null(temp_png)) {
      temp_png <- readPng(file_png)
      img_dim <- dim(temp_png)[c(1,2)]
      cell_dim <- img_dim * imagesize_multiplier
      setColWidths(wb, filelist, cols = 1, widths = cell_dim[2]/20)
    }
    
    insertImage(wb, 
                filelist, 
                file_png, 
                startRow = p + 1, 
                startCol = 1, 
                height = cell_dim[1], 
                width = cell_dim[2], 
                units = "px")
    
    if (p %% 100 == 0) {
      cat("at row: ", p, "\n")
    }
  }
  
  setRowHeights(wb, filelist, rows = c(1:nrow(outlist) + 1), heights = cell_dim[1]/4)
  setColWidths(wb, filelist, cols = c(2:ncol(outlist)), widths = 20)
} else {
  setRowHeights(wb, filelist, rows = c(1:nrow(outlist)), heights = 18)
  setColWidths(wb, filelist, cols = c(1:ncol(outlist)), widths = 20)
}
writeData(wb, sheet = 1, outlist, startCol = 1)
xlsx_name <- paste0(outdir, "/", project, ".xlsx")
saveWorkbook(wb,
             xlsx_name,
             overwrite = TRUE)
cat(xlsx_name)
rm(wb)

write.table(outlist, file=paste(outdir, "allpgrps_stats.txt", sep="/"))



# INTERNE STANDAARDEN
load(init)
len <- length(repl.pattern)

IS <- outlist[grep("Internal standard", outlist[,"relevance"], fixed = TRUE),]
IS_codes <- rownames(IS)
cat(IS_codes,"\n")

# Retrieve IS summed adducts
IS_summed <- IS[,1:(len+1)]
IS_summed$HMDB.name <- IS$name
IS_summed <- melt(IS_summed, id.vars=c('HMDB_code','HMDB.name'))
colnames(IS_summed) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_summed$Intensity <- as.numeric(IS_summed$Intensity)
IS_summed$Matrix <- matrix
IS_summed$Rundate <- rundate
IS_summed$Project <- project
IS_summed$Intensity <- as.numeric(as.character(IS_summed$Intensity))

# Retrieve IS positive mode
load("adductSums_positive.RData")
IS_pos <- as.data.frame(subset(outlist.tot,rownames(outlist.tot) %in% IS_codes))
IS_pos$HMDB_name <- IS[match(row.names(IS_pos),IS$HMDB_code,nomatch=NA),'name']
IS_pos$HMDB.code <- row.names(IS_pos)
IS_pos <- melt(IS_pos, id.vars=c('HMDB.code','HMDB_name'))
colnames(IS_pos) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_pos$Matrix <- matrix
IS_pos$Rundate <- rundate
IS_pos$Project <- project
IS_pos$Intensity <- as.numeric(as.character(IS_pos$Intensity))

# Retrieve IS negative mode
load("adductSums_negative.RData")
IS_neg <- as.data.frame(subset(outlist.tot,rownames(outlist.tot) %in% IS_codes))
IS_neg$HMDB_name <- IS[match(row.names(IS_neg),IS$HMDB_code,nomatch=NA),'name']
IS_neg$HMDB.code <- row.names(IS_neg)
IS_neg <- melt(IS_neg, id.vars=c('HMDB.code','HMDB_name'))
colnames(IS_neg) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_neg$Matrix <- matrix
IS_neg$Rundate <- rundate
IS_neg$Project <- project
IS_neg$Intensity <- as.numeric(as.character(IS_neg$Intensity))

# Save results
save(IS_pos,IS_neg,IS_summed, file='IS_results_test.RData')

w <- 9 + 0.35 * len

# Barplot voor alle IS
IS_neg_plot <- ggplot(IS_neg, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Neg)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8),
        legend.position='none')+
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10))
ggsave("plots/IS_bar_neg.png", plot=IS_neg_plot, height=w/2.5, width=w, units="in")

IS_pos_plot <- ggplot(IS_pos, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Pos)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8),
        legend.position='none')+
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10))
ggsave("plots/IS_bar_pos.png", plot=IS_pos_plot, height=w/2.5, width=w, units="in")

IS_sum_plot <- ggplot(IS_summed, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Summed)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8),
        legend.position='none')+
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10))
ggsave("plots/IS_bar_sum.png", plot=IS_sum_plot, height=w/2.5, width=w, units="in")




# Lineplot voor alle IS
IS_neg_plot <- ggplot(IS_neg, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Neg)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8))

IS_pos_plot <- ggplot(IS_pos, aes(Sample,Intensity)) +
  ggtitle("Interne Standaard (Pos)") +
  geom_point(aes(col = HMDB.name)) +
  geom_line(aes(col = HMDB.name, group = HMDB.name)) +
  labs(x = '', y = 'Intensity') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 8))

IS_sum_plot <- ggplot(IS_summed, aes(Sample, Intensity)) +
  ggtitle("Interne Standaard (Sum)") +
  geom_point(aes(col = HMDB.name)) +
  geom_line(aes(col = HMDB.name, group = HMDB.name)) +
  labs(x = '', y = 'Intensity') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 8))

w <- 8 + 0.2 * len
ggsave("plots/IS_line_neg.png", plot = IS_neg_plot, height = w/2.5, width = w, units = "in")
ggsave("plots/IS_line_pos.png", plot = IS_pos_plot, height = w/2.5, width = w, units = "in")
ggsave("plots/IS_line_sum.png", plot = IS_sum_plot, height = w/2.5, width = w, units = "in")


# Barplot voor Leucine voor alle data
IS_now<-'2H3-Leucine (IS)'
p1<-ggplot(subset(IS_neg, HMDB.name %in% IS_now), aes(Sample,Intensity)) +
  ggtitle(paste0(IS_now, " (Neg)")) +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(title='Negative mode',x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=10),
        legend.position='none')
p2<-ggplot(subset(IS_pos, HMDB.name %in% IS_now), aes(Sample,Intensity)) +
  ggtitle(paste0(IS_now, " (Pos)")) +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(title='Positive mode',x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=10),
        legend.position='none')
p3<-ggplot(subset(IS_summed, HMDB.name %in% IS_now), aes(Sample,Intensity)) +
  ggtitle(paste0(IS_now, " (Sum)")) +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(title='Adduct sums',x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=10),
        legend.position='none')

w <- 3 + 0.2 * len

ggsave("plots/Leucine_neg.png", plot = p1, height = w/2.5, width = w, units = "in")
ggsave("plots/Leucine_pos.png", plot = p2, height = w/2.5, width = w, units = "in")
ggsave("plots/Leucine_sum.png", plot = p3, height = w/2.5, width = w, units = "in")


if (z_score == 1) {
  ### POSITIVE CONTROLS
  #HMDB codes
  PA_codes <- c('HMDB00824', 'HMDB00783', 'HMDB00123')
  PKU_codes <- c('HMDB00159')
  LPI_codes <- c('HMDB00904', 'HMDB00641', 'HMDB00182')
  
  PA_data <- outlist[PA_codes, c('HMDB_code','name','P1002.1_Zscore')]
  PA_data <- melt(PA_data, id.vars = c('HMDB_code','name'))
  colnames(PA_data) <- c('HMDB.code','HMDB.name','Sample','Zscore')
  
  PKU_data <- outlist[PKU_codes, c('HMDB_code','name','P1003.1_Zscore')]
  PKU_data <- melt(PKU_data, id.vars = c('HMDB_code','name'))
  colnames(PKU_data) <- c('HMDB.code','HMDB.name','Sample','Zscore')
  
  LPI_data <- outlist[LPI_codes, c('HMDB_code','name','P1005.1_Zscore')]
  LPI_data <- melt(LPI_data, id.vars = c('HMDB_code','name'))
  colnames(LPI_data) <- c('HMDB.code','HMDB.name','Sample','Zscore')
  
  Pos_Contr <- rbind(PA_data, PKU_data, LPI_data)
  
  Pos_Contr <- rbind(PA_data)
  
  
  Pos_Contr$Zscore <- as.numeric(Pos_Contr$Zscore)
  Pos_Contr$Matrix <- matrix
  Pos_Contr$Rundate <- rundate
  Pos_Contr$Project <- project
  
  #Save results
  save(Pos_Contr,file='Pos_Contr_test.RData')
}


cat("Ready excelExport.R")
