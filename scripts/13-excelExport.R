#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

cat("Start excelExport.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

outdir <- cmd_args[1] #"/Users/nunen/Documents/Metab/test_set"
project <- cmd_args[2] #"test"
matrix <- cmd_args[3] #"DBS"
hmdb <- cmd_args[4] #HMDB_with_info_relevance_IS_C5OH.RData
scripts <- cmd_args[5] #"/Users/nunen/Documents/Metab/DIMS/scripts"

rundate <- Sys.Date()

setwd(scripts)
source("AddOnFunctions/sourceDir.R")
sourceDir("AddOnFunctions")

setwd(outdir)


plotdir <- "plots/adducts"
sub <- 20000
adducts <- TRUE
control_label <- "C"
case_label <- "P"

# sum positive and negative adductsums
outlist <- initialize(outdir, hmdb)
outlist_save_point <- outlist
outlist <- outlist_save_point
outlist <- outlist$adducts
outlist <- outlist[-grep("Exogenous", outlist[,"relevance"], fixed = TRUE),]
outlist <- outlist[-grep("exogenous", outlist[,"relevance"], fixed = TRUE),]
outlist <- outlist[-grep("Drug", outlist[,"relevance"], fixed = TRUE),]
#colnames(outlist) <- gsub('PLRD_','',colnames(outlist))
outlist <- statistics_z_4export(peaklist = as.data.frame(outlist),
                                plotdir = plotdir,
                                patients = getPatients(outlist),
                                adducts = adducts,
                                control_label = control_label,
                                case_label = case_label)

unlink("xls", recursive = T)
dir.create("xls", showWarnings = F)

generateExcelFile(peaklist = outlist,
                  plotdir = file.path(plotdir),
                  imageNum = 1,
                  fileName = paste("xls", "test", sep="/"),
                  subName = "_box",
                  sub = sub,
                  adducts = adducts)

cat("Excel created")

# windows only:
#source("../../R/runVBAMacro.R")
#script <- paste("Wscript.exe E:\\Metabolomics\\projects\\", dims_dir ,"\\src\\run.vbs",sep="")
#runVBAMacro(dir=paste("E:\\Metabolomics\\projects\\", dims_dir ,"\\xls\\",sep=""),
#            dir2=paste("E:\\Metabolomics\\projects\\", dims_dir ,"\\results\\",sep=""), script)

# INTERNE STANDAARDEN
library('reshape2')
load("logs/init.RData")
IS <- outlist[grep("Internal standard", outlist[,"relevance"], fixed = TRUE),]
IS_codes <- rownames(IS)

# Retrieve IS summed adducts
IS_summed <- IS[,1:(length(repl.pattern)+1)]
IS_summed$HMDB.name <- IS$name
IS_summed <- melt(IS_summed, id.vars=c('HMDB_code','HMDB.name'))
colnames(IS_summed) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_summed$Intensity <- as.numeric(IS_summed$Intensity)
IS_summed$Matrix <- matrix
IS_summed$Rundate <- rundate
IS_summed$Project <- project

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

# Save results
save(IS_pos,IS_neg,IS_summed, file='IS_results_test.RData')

### POSITIVE CONTROLS
#HMDB codes
PA_codes <- c('HMDB00824','HMDB00783','HMDB00123')
PKU_codes <- c('HMDB00159')
LPI_codes <- c('HMDB00904','HMDB00641','HMDB00182')

PA_data<-outlist[PA_codes,c('HMDB_code','name','P1002.1_Zscore')]
PA_data<-melt(PA_data, id.vars=c('HMDB_code','name'))
colnames(PA_data)<-c('HMDB.code','HMDB.name','Sample','Zscore')

PKU_data<-outlist[PKU_codes,c('HMDB_code','name','P1003.1_Zscore')]
PKU_data<-melt(PKU_data, id.vars=c('HMDB_code','name'))
colnames(PKU_data)<-c('HMDB.code','HMDB.name','Sample','Zscore')

LPI_data<-outlist[LPI_codes,c('HMDB_code','name','P1005.1_Zscore')]
LPI_data<-melt(LPI_data, id.vars=c('HMDB_code','name'))
colnames(LPI_data)<-c('HMDB.code','HMDB.name','Sample','Zscore')

Pos_Contr<-rbind(PA_data, PKU_data, LPI_data)

Pos_Contr<-rbind(PA_data)


Pos_Contr$Zscore<-as.numeric(Pos_Contr$Zscore)
Pos_Contr$Matrix<-matrix
Pos_Contr$Rundate<-rundate
Pos_Contr$Project<-project

#Save results
save(Pos_Contr,file='Pos_Contr_test.RData')

library(xlsx)
library(ggplot2)
library(cowplot)
library(lubridate) #used for creating dates
library(gridExtra)
library(grid) # for textgrob

# Barplot voor alle IS
IS_neg_plot <- ggplot(IS_neg, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Neg)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), 
        legend.position='none')

IS_pos_plot <- ggplot(IS_pos, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Pos)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), 
        legend.position='none')

IS_sum_plot <- ggplot(IS_summed, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Summed)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), 
        legend.position='none')

w <- 8 + 0.5 * length(repl.pattern)
ggsave("plots/IS_bar_neg.png", plot=IS_neg_plot, height=6, width=w, units="in")
ggsave("plots/IS_bar_pos.png", plot=IS_pos_plot, height=6, width=w, units="in")
ggsave("plots/IS_bar_sum.png", plot=IS_sum_plot, height=6, width=w, units="in")



# Lineplot voor alle IS
IS_neg_plot <- ggplot(IS_neg, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Neg)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10))

IS_pos_plot <- ggplot(IS_pos, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Pos)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10))

IS_sum_plot <- ggplot(IS_summed, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Sum)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10))

w <- 8 + 0.2 * length(repl.pattern)
ggsave("plots/IS_line_neg.png", plot=IS_neg_plot, height=6, width=w, units="in")
ggsave("plots/IS_line_pos.png", plot=IS_pos_plot, height=6, width=w, units="in")
ggsave("plots/IS_line_sum.png", plot=IS_sum_plot, height=6, width=w, units="in")


# Barplot voor Leucine voor alle data
IS_now<-'2H3-Leucine (IS)' 
p1<-ggplot(subset(IS_pos, HMDB.name %in% IS), aes(Sample,Intensity))+
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(title='Positive mode',x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), 
        legend.position='none')
p2<-ggplot(subset(IS_neg, HMDB.name %in% IS), aes(Sample,Intensity))+
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(title='Negative mode',x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), 
        legend.position='none')
p3<-ggplot(subset(IS_summed, HMDB.name %in% IS), aes(Sample,Intensity))+
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(title='Adduct sums',x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), 
        legend.position='none')

w <- 3 + 0.2 * length(repl.pattern)
p4<-plot_grid(p1,p2,p3,ncol=1,axis='rlbt',rel_heights=c(1,1,1))
ggsave("plots/Leucine.png", plot=p4, height=6, width=w, units="in")


cat("Ready excelExport.R")
