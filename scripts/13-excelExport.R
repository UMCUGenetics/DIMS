#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2_test")

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

library("ggplot2")
library('reshape2')

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


# INTERNE STANDAARDEN
load("logs/init.RData")
len <- length(repl.pattern)

IS <- outlist[grep("Internal standard", outlist[,"relevance"], fixed = TRUE),]
IS_codes <- rownames(IS)


# Retrieve IS summed adducts
IS_summed <- IS[,1:(len+1)]
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

#load(paste0(outdir, "/IS_results_test.RData"))


w <- 10 + 0.4 * len

# Barplot voor alle IS
IS_neg_plot <- ggplot(IS_neg, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Neg)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8), 
        legend.position='none')
ggsave("plots/IS_bar_neg.png", plot=IS_neg_plot, height=w/2.5, width=w, units="in")

IS_pos_plot <- ggplot(IS_pos, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Pos)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8), 
        legend.position='none')
ggsave("plots/IS_bar_pos.png", plot=IS_pos_plot, height=w/2.5, width=w, units="in")

IS_sum_plot <- ggplot(IS_summed, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Summed)") +
  geom_bar(aes(fill=HMDB.name),stat='identity')+
  labs(x='',y='Intensity')+
  facet_wrap(~HMDB.name, scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8), 
        legend.position='none')
ggsave("plots/IS_bar_sum.png", plot=IS_sum_plot, height=w/2.5, width=w, units="in")




# Lineplot voor alle IS
IS_neg_plot <- ggplot(IS_neg, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Neg)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8))

IS_pos_plot <- ggplot(IS_pos, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Pos)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8))

IS_sum_plot <- ggplot(IS_summed, aes(Sample,Intensity))+
  ggtitle("Interne Standaard (Sum)") +
  geom_point(aes(col=HMDB.name))+
  geom_line(aes(col=HMDB.name, group=HMDB.name))+
  labs(x='',y='Intensity')+
  theme(axis.text.x=element_text(angle = 90, hjust = 1, vjust = 0.5, size=8))

w <- 8 + 0.2 * len
ggsave("plots/IS_line_neg.png", plot=IS_neg_plot, height=w/2.5, width=w, units="in")
ggsave("plots/IS_line_pos.png", plot=IS_pos_plot, height=w/2.5, width=w, units="in")
ggsave("plots/IS_line_sum.png", plot=IS_sum_plot, height=w/2.5, width=w, units="in")


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
#p4<-plot_grid(p1,p2,p3,ncol=1,axis='rlbt',rel_heights=c(1,1,1))
#ggsave("plots/Leucine.png", plot=p4, height=6, width=w, units="in")

ggsave("plots/Leucine_neg.png", plot=p1, height=w/2.5, width=w, units="in")
ggsave("plots/Leucine_pos.png", plot=p2, height=w/2.5, width=w, units="in")
ggsave("plots/Leucine_sum.png", plot=p3, height=w/2.5, width=w, units="in")




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



cat("Ready excelExport.R")
