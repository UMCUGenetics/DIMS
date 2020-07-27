# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Session info ------------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cat(
  "
  Created by:   Hanneke Haijes
  Modified by:  Marten Kerkhofs, 2019-03-01
                Nienke van Unen, 2019-09-02
  
  OS
  Windows 7 x64 build 7601 Service Pack 1
  
  Package versions:
  R version   3.4.3 (2017-11-30)
  
  lubridate   1.7.4
  cowplot     0.9.4
  ggplot2     3.1.0
  xlsx        0.6.1
  gridExtra   2.3
  
  ")




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Libraries ---------------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library(xlsx)
library(ggplot2)
library(cowplot)
library(lubridate) #used for creating dates
library(gridExtra)
library(grid) # for textgrob




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Things to change manually before running code ---------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

this_dir <- "E:/Metabolomics/projects/DIMS2_SinglePatients_DEV"

# Prefix to the network drive; Generally Y:/ or T:/metab
prefix <- "Y:/"

# cat("What matrix to use? (Comment in & out via ctrl+shift+c)(POSSIBILITIES: DBS)")
matrix<-"DBS"

# INTER-RUN PLOTTING
# cat("Do you want to plot specific IS (type TRUE or FALSE)")
# type FALSE voor alle IS, type TRUE voor alle andere opties
plot_specific_IS <- FALSE

# If yes, which one(s)? (type between quotation marks: ' ' or " ")
# For possibilities, copy and paste from the list below

# Een IS:
# IS<-'2H4_13C5-Arginine (IS)'

# Meerdere IS:
IS<-c('13C6-Phenylalanine (IS)','13C6-Tyrosine (IS)')


# INTRA-RUN PLOTTING
# ASSESS INTRA-RUN STABILITY (type TRUE or FALSE)
perform_intra_run_stability <- TRUE

# cat("What do you want to plot? (Comment in & out via ctrl+shift+c)(POSSIBILITIES: IS_pos_merge, IS_neg_merge, IS_summed_merge)")
# what_to_plot <- "IS_pos_merge"
# what_to_plot <- "IS_neg_merge"
what_to_plot <- "IS_summed_merge"

# if TRUE, what project to assess?
if(perform_intra_run_stability){project_intra_run<-'2015_011_SPXIX'}


#Gekozen IS
Neg<-as.factor(c('2H2-Ornithine (IS)','2H2-Citrulline (IS)','2H3-Glutamate (IS)','2H4_13C5-Arginine (IS)','13C6-Tyrosine (IS)'))
Pos<-as.factor(c('2H3-Propionylcarnitine (IS)','2H9-Isovalerylcarnitine (IS)','2H4-Alanine (IS)','2H4_13C5-Arginine (IS)','13C6-Phenylalanine (IS)'))
Sum<-as.factor(c('2H3-Glutamate (IS)','2H3-Leucine (IS)','2H4_13C5-Arginine (IS)','13C6-Tyrosine (IS)','2H8-Valine (IS)'))

#'15N_2-13C-Glycine (IS)'
#'2H2-Citrulline (IS)'
#'2H2-Ornithine (IS)'
#'2H3-Leucine (IS)'
#'2H3-Methionine (IS)'
#'2H3-Glutamate (IS)'
#'2H3-Aspartate (IS)'  
#'2H4_13C5-Arginine (IS)' 
#'2H4-Alanine (IS)'
#'2H8-Valine (IS)' 
#'13C6-Phenylalanine (IS)'
#'13C6-Tyrosine (IS)'
#'2H9-Carnitine (IS)' 
#'2H3-Acetylcarnitine (IS)'
#'2H3-Propionylcarnitine (IS)'
#'2H3-Butyrylcarnitine (IS)'
#'2H9-Isovalerylcarnitine (IS)'
#'2H3-Octanoylcarnitine (IS)'
#'2H9-Myristoylcarnitine (IS)'
#'2H3-Palmitoylcarnitine (IS)'




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Future: supply variables via terminal -----------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# cat("What matrix to use? (POSSIBILITIES: DBS)")
# matrix <- readline(prompt="Enter matrix: ")

# Control whether valid things have been filled in
# Check for matrix

# cat("What to plot? (POSSIBILITIES: IS_pos_merge, IS_neg_merge, IS_summed_merge)")
# matrix <- readline(prompt="Enter what to plot: ")

# cat("Do you want to plot specific IS (type TRUE or FALSE)")
# plot_specific_IS <- readline(prompt="Enter TRUE or FALSE: ")




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Check for correct inputs ------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Control whether valid things have been filled in
# Check for matrix
if(matrix != "DBS"){
  stop("\nThe value given to \"matrix\" is not valid, select one of these: DBS\n 
          De waarde ingevuld bij \"matrix\" is niet een geldige waarde, kies een van de volgende: DBS")
}
# Check for plot possibilities
plot_possibilities <- c("IS_pos_merge", "IS_neg_merge", "IS_summed_merge")
if(!(what_to_plot %in% plot_possibilities)) {
  stop("\nThe value given to \"what_to_plot\" is not valid, select one of these: IS_pos_merge, IS_neg_merge, IS_summed_merge\n 
          De waarde ingevuld bij \"what_to_plot\" is niet een geldige waarde, kies een van de volgende: IS_pos_merge, IS_neg_merge, IS_summed_merge")
}




# Run script --------------------------------------------------------------



# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Load data & prepare -----------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Read in project list
setwd(paste(prefix, "Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects", sep="/"))
Overview<-read.xlsx(file="DIMS_Project_Overview.xlsx",sheetIndex=1,stringsAsFactors=F)
Overview<-subset(Overview, Overview$Matrix %in% matrix & Overview$IS.Analyse %in% 'Ja')

IS_pos_merge<-as.data.frame(matrix(ncol=7,nrow=0))
colnames(IS_pos_merge)<-c("HMDB.code","HMDB.name","Sample","Intensity","Matrix","Rundate","Project")

IS_neg_merge<-IS_pos_merge
IS_summed_merge<-IS_pos_merge


# Delete the first project in overview (because not in folder)
# Overview <- Overview[2:nrow(Overview),]


# Read in IS data
for (i in 1:length(Overview$Project.Naam)) {
  project<-Overview[i,'Project.Naam']
  load(paste0(prefix, "/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Kwaliteit_Validatie/IS_results/",
              matrix,'/IS_results_',project,".RData"))
  
  IS_pos_merge<-rbind(IS_pos_merge,IS_pos)
  IS_neg_merge<-rbind(IS_neg_merge,IS_neg)
  IS_summed_merge<-rbind(IS_summed_merge,IS_summed)
  
  IS_pos<-NULL
  IS_neg<-NULL
  IS_summed<-NULL
  project<-NULL
}

# Add column "Date" and make factors in such a way that all current plot functions are sorted on the basis of the date
df.list <- list(IS_pos_merge,IS_neg_merge,IS_summed_merge)
for( i in 1:3){
  df.list[[i]]$Project <- as.factor(df.list[[i]]$Project)
  df.list[[i]]$Sample <- as.factor(df.list[[i]]$Sample)
  df.list[[i]]$Date <- lubridate::parse_date_time(df.list[[i]]$Rundate, order = "dmy")
  df.list[[i]] <- df.list[[i]][order(df.list[[i]]$Date),]
  df.list[[i]]$Project <- as.factor(df.list[[i]]$Project)
  df.list[[i]]$Project <- factor(df.list[[i]]$Project, levels=unique(df.list[[i]]$Project))
  df.list[[i]]$Sample <- factor(df.list[[i]]$Sample, levels=unique(df.list[[i]]$Sample))
}



# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Select which data to plot and prepare plot names ------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

IS_pos_merge <- df.list[[1]]
IS_neg_merge <- df.list[[2]]
IS_summed_merge <- df.list[[3]]

if(what_to_plot == "IS_pos_merge"){
  # IS_pos_merge <- df.list[[1]]
  data<-IS_pos_merge
  SumPosNeg_plot_title <- "Positive"
} else if (what_to_plot == "IS_neg_merge"){
  # IS_neg_merge <- df.list[[2]]
  data<-IS_neg_merge
  SumPosNeg_plot_title <- "Negative"
} else {
  # IS_summed_merge <- df.list[[3]]
  data<-IS_summed_merge
  SumPosNeg_plot_title <- "Summed"
} 

# title for all or specific IS
if(!plot_specific_IS){
  IS_plot_title <- "All IS"
  IS_file_name <- "Alle_IS"
} else {
  if(length(IS) == 1){
    IS_plot_title <- IS
    IS_file_name <- IS
  } else {
    IS_plot_title <- "Selected IS"
    IS_file_name <- "Selected_IS"
  }
}

# Get current date
current_date <- lubridate::today()

# Set plot title with date, summed/positive/negative & a specific, multiple or all IS
plot_title <- paste(current_date, SumPosNeg_plot_title, IS_plot_title)
plot_file_name <- paste(current_date, SumPosNeg_plot_title, "Boxplots", IS_file_name, "alle_runs",sep = "_")


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Visualise data ----------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# NOTE ON WIDTH AND HEIGHT OF PDFs
# 
# WIDTH:
# The width of a single plot is set to \"the number of projects\" * 0.1, plus 1 for it's y-axis text
# This is then multiplied by the number of plots that go next to each other, being in between 1 and 5
# 
# HEIGHT:
# The height of a pdf is set to 3 per individual plot + 2 for the shared x-axis text. To check for the number of 
# plots on top of each other, the following function is performed: 
# 'square root of the number of plots', rounded down to the nearest integer.


# Set width of pdf to be proportional to the number of projects present in the data.
number_of_projects <- length(unique(data$Project))
# (3 plots next to each other, every project needs space + axis titles)
single_pdf_width <- number_of_projects*0.1+1

# ASSESS INTER-RUN STABILITY
# Boxplot voor alle IS
if(plot_specific_IS == FALSE){
  try(dev.off(), silent = TRUE)
  pdf(paste0(prefix, "Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Kwaliteit_Validatie/IS_results/",matrix,"/PDFs resultaten/", plot_file_name,".pdf"), width = single_pdf_width*5, height = 14)
  p <- ggplot(data, aes(Project,Intensity))+
    geom_boxplot(aes(fill=Project))+
    labs(x='',y='Intensity')+
    ggtitle(plot_title) +
    facet_wrap(~HMDB.name, scales='free_y')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=8), legend.position='none')
  print(p)
  dev.off()
} else {
  # Boxplot 1 IS
  p <- ggplot(subset(data, HMDB.name %in% IS), aes(Project,Intensity)) +
    geom_boxplot(aes(fill=Project)) +
    labs(x='',y='Intensity') +
    ggtitle(plot_title) +
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=8), legend.position='none')
  try(dev.off(), silent = TRUE)
  if(length(IS) > 1){
    # Boxplot > 1 IS
    if(length(IS) == 3){
      # Because of different layouts of facet_wrap, it is easiest to handle 3 IS as different to other numbers (3 puts them in a row, not stacked, like higher numbers)
      pdf(paste0(plot_file_name,".pdf"), width = single_pdf_width*3, height = 2 + 3)
    } else {
      pdf(paste0(plot_file_name,".pdf"), width = single_pdf_width*ceiling(sqrt(length(IS))), height = 2 + 3*floor(sqrt(length(IS))))
    }
    print(p+facet_wrap(~HMDB.name, scales='free_y'))
  } else {
    pdf(paste0(prefix, "Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Kwaliteit_Validatie/IS_results/",matrix,"/PDFs resultaten/", plot_file_name,".pdf"), width = single_pdf_width*1.5, height = 7.5)
    print(p)
  }
  dev.off()
}



# # Boxplot meerdere (maar niet alle) IS
# try(dev.off())
# pdf("C:/Users/mkerkho7/Documents/test.pdf", width = single_pdf_width*length(plot_specific_IS)%%5, height = 15)
# ggplot(subset(data, HMDB.name %in% IS), aes(Project,Intensity))+
#   geom_boxplot(aes(fill=Project))+
#   labs(x='',y='Intensity')+
#   facet_wrap(~HMDB.name, scales='free_y')+
#   theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Intra-run stability -----------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ASSESS INTRA-RUN STABILITY
if(perform_intra_run_stability){
  try(dev.off(), silent = TRUE)
  # Uncomment to override previous call to a project and fill in desired project
  # project_intra_run<-'2015_011_SPXVI'
  # To estimate the width of the plots:
  number_of_samples <- length(unique(IS_pos_merge$Sample[IS_pos_merge$Project == project_intra_run]))
  single_pdf_width_intra <- number_of_samples*0.11+1
  
  # Get filename:
  plot_intra_file_name <- paste(current_date, "Barplot_Selected_IS", project_intra_run, sep = "_")
  
  # Sometimes the intensities of IS_pos and IS_neg are seen as text instead of numbers
  IS_pos_merge$Intensity <- as.numeric(as.character(IS_pos_merge$Intensity))
  IS_neg_merge$Intensity <- as.numeric(as.character(IS_neg_merge$Intensity))
  
  # Barplot voor gekozen IS voor alle data
  p1<-ggplot(subset(IS_pos_merge, HMDB.name %in% Pos & Project %in% project_intra_run), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(title='Positive mode',x='',y='Intensity')+
    facet_wrap(~HMDB.name, scales='free_y',nrow=1)+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  p2<-ggplot(subset(IS_neg_merge, HMDB.name %in% Neg & Project %in% project_intra_run), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(title='Negative mode',x='',y='Intensity')+
    facet_wrap(~HMDB.name, scales='free_y',nrow=1)+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  p3<-ggplot(subset(IS_summed_merge, HMDB.name %in% Sum & Project %in% project_intra_run), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(title='Adduct sums',x='',y='Intensity')+
    facet_wrap(~HMDB.name, scales='free_y',nrow=1)+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  
  # plot_grid(p1,p2,p3,ncol=1,axis='rlbt',rel_heights=c(1,1,1)) #old
  grid.arrange(p1, p2, p3, ncol = 1, top = textGrob(paste("date:", current_date, "project:", project_intra_run),gp=gpar(fontsize=20,font=3)))
  p4 <- recordPlot()
  pdf(paste0(prefix, "Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Kwaliteit_Validatie/IS_results/",matrix,"/PDFs resultaten/", plot_intra_file_name, ".pdf"), width = single_pdf_width_intra*5, height = 15)
  print(p4)
  dev.off()
}




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Perform other, manual plots ---------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#To perform any of these plots, select the code and press "ctrl + enter"

if(FALSE){
  
  # Barplot voor Arginine voor alle data
  IS<-'2H4_13C5-Arginine (IS)' 
  p1<-ggplot(subset(IS_pos_merge, HMDB.name %in% IS & Project %in% project), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(title='Positive mode',x='',y='Intensity')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  p2<-ggplot(subset(IS_neg_merge, HMDB.name %in% IS & Project %in% project), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(title='Negative mode',x='',y='Intensity')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  p3<-ggplot(subset(IS_summed_merge, HMDB.name %in% IS & Project %in% project), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(title='Adduct sums',x='',y='Intensity')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  
  plot_grid(p1,p2,p3,ncol=1,axis='rlbt',rel_heights=c(1,1,1))
  
  # Barplot voor alle IS
  ggplot(subset(data, Project %in% project), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(x='',y='Intensity')+
    facet_wrap(~HMDB.name, scales='free_y')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')
  
  # Barplot ??n IS
  ggplot(subset(data, HMDB.name %in% IS & Project %in% project), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(x='',y='Intensity')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10))
  
  # Barplot meerdere (maar niet alle) IS
  ggplot(subset(data, HMDB.name %in% IS & Project %in% project), aes(Sample,Intensity))+
    geom_bar(aes(fill=HMDB.name),stat='identity')+
    labs(x='',y='Intensity')+
    facet_wrap(~HMDB.name, scales='free_y',ncol=1)+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10))
  
  # Lineplot
  ggplot(subset(data, HMDB.name %in% IS & Project %in% project), aes(Sample,Intensity))+
    geom_point(aes(col=HMDB.name))+
    geom_line(aes(col=HMDB.name, group=HMDB.name))+
    labs(x='',y='Intensity')+
    theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10))
  
}

