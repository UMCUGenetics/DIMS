# AANPASSEN VOOR RUNNEN
matrix  <- "DBS"
project <- "2015_011_SPXIX"
rundate <- "18-7-2019"

this_dir <- "E:/Metabolomics/projects/DIMS2_SinglePatients_DEV"

setwd(this_dir)
source("src/export.R")
source("src/generateExcelFile.R")
source("src/genExcelFileV3.R")
source("src/getPatients.R")
source("src/initialize.R")
source("src/PlotBoxPlot.R")
source("src/plotZscorePlot.R")
source("src/statistics_z.R")
source("src/statistics_z_4export.R")
source("src/runVBAMacro.R")

plotdir <- "output/plots"
dims_dir <- "DIMS2_SinglePatients_DEV"
sub <- 20000
adducts <- TRUE
control_label <- "C"
case_label <- "P"

unlink("output", recursive = TRUE)
dir.create("output", showWarnings = FALSE)
dir.create("output/plots", showWarnings = FALSE)

# sum positive and negative adductsums
outlist = initialize()
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

generateExcelFile(outlist, file.path(plotdir), imageNum=1, fileName=paste("output", project, sep="/"), subName=c("","_box"), sub, adducts)

#script <- paste("Wscript.exe E:\\Metabolomics\\projects\\", dims_dir ,"\\src\\run.vbs",sep="")
#runVBAMacro(dir=paste("E:\\Metabolomics\\projects\\", dims_dir ,"\\output\\",sep=""),
#            dir2=paste("E:\\Metabolomics\\projects\\", dims_dir ,"\\output\\",sep=""), 
#            script)

# INTERNE STANDAARDEN
library('reshape2')
load("input/init.RData")
IS <- outlist[grep("Internal standard", outlist[,"relevance"], fixed = TRUE),]
IS_codes <- rownames(IS)

# Retrieve IS summed adducts
IS_summed <- IS[,1:length(repl.pattern)]
IS_summed$HMDB.name <- IS$name
IS_summed <- melt(IS_summed, id.vars=c('HMDB_code','HMDB.name'))
colnames(IS_summed) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_summed$Intensity <- as.numeric(IS_summed$Intensity)
IS_summed$Matrix <- matrix
IS_summed$Rundate <- rundate
IS_summed$Project <- project

# Retrieve IS positive mode
load("input/adductSums_positive.RData")
IS_pos <- as.data.frame(subset(outlist.tot,rownames(outlist.tot) %in% IS_codes))
IS_pos$HMDB_name <- IS[match(row.names(IS_pos),IS$HMDB_code,nomatch=NA),'name']
IS_pos$HMDB.code <- row.names(IS_pos)
IS_pos <- melt(IS_pos, id.vars=c('HMDB.code','HMDB_name'))
colnames(IS_pos) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_pos$Matrix <- matrix
IS_pos$Rundate <- rundate
IS_pos$Project <- project

# Retrieve IS negative mode
load("input/adductSums_negative.RData")
IS_neg <- as.data.frame(subset(outlist.tot,rownames(outlist.tot) %in% IS_codes))
IS_neg$HMDB_name <- IS[match(row.names(IS_neg),IS$HMDB_code,nomatch=NA),'name']
IS_neg$HMDB.code <- row.names(IS_neg)
IS_neg <- melt(IS_neg, id.vars=c('HMDB.code','HMDB_name'))
colnames(IS_neg) <- c('HMDB.code','HMDB.name','Sample','Intensity')
IS_neg$Matrix <- matrix
IS_neg$Rundate <- Sys.Date()
IS_neg$Project <- project

# Save results
save(IS_pos,IS_neg,IS_summed,file=paste('output/','IS_results_',project,'.RData',sep=''))

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

Pos_Contr$Zscore<-as.numeric(Pos_Contr$Zscore)
Pos_Contr$Matrix<-matrix
Pos_Contr$Rundate<-rundate
Pos_Contr$Project<-project

#Save results
save(Pos_Contr,file=paste('output/','Pos_Contr_',project,'.RData',sep=''))

