# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Session info ------------------------------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

cat(
  "Script to create boxplots of the metabolite values accross the 2015-runs.
  These boxplots can be used to create excel files for individual patients.
  
  Code addapted from DIMS_2.1_excel_export.R
  
  Created:  Marten Kerkhofs, 18-03-2019
  Modified: Marten Kerkhofs, 22-03-2019
  Modified: Marten Kerkhofs, 28-05-2019
  
  OS: macOS 10.14.5
  R version 3.6.0 (2019-04-26)
  
  package versions:
  -
  "
)



# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# MAC COMPATIBLE, load in functions to be used ----------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

setwd("/Users/mkerkho7/DIMS2_repo/Dx_metabolomics/DIMS2_SinglePatients/")
source("Supportive scripts/getPatients.R")
source("Supportive scripts/initialize_Marten.R")
source("Supportive scripts/plotBoxPlot_Marten.R")
source("Supportive scripts/statistics_z_Marten.R")
source("Supportive scripts/statistics_z_4export.R")




# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Get to correct working directories --------------------------------------
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# matrix  <-"DBS"
args <- commandArgs(TRUE)
project_numbers <- args[1:length(args)]
all_projects <- NULL
for(num in 1:length(project_numbers)){
  all_projects[num] <- paste0(project_numbers[num], " SinglePatients_", as.roman(project_numbers[num]))
}

cat("\n\nStart script, \nchoosen runs:",all_projects,"\n")

# all_projects <- "18 SinglePatients_XVIII"

# all_projects <- c("02 SinglePatients_II", "03 SinglePatients_III", "03 SinglePatients_IIIb",
#                   "04 SinglePatients_IV", "05 SinglePatients_V", "06 SinglePatients_VI",
#                   "07 SinglePatients_VII", "08 SinglePatients_VIII", "09 SinglePatients_IX",
#                   "10 SinglePatients_X", "11 SinglePatients_XI", "12 SinglePatients_XII",
#                   "13 SinglePatients_XIII", "14 SinglePatients_XIV", "15 SinglePatients_XV",
#                   "16 SinglePatients_XVI", "17 SinglePatients_XVII", "18 SinglePatients_XVIII")

working_directory <- "/Volumes/Metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2015/Project 2015_011_SinglePatients/"

dims_dir <- "DIMS2_SinglePatients"
adducts <- TRUE
control_label <- "C"
case_label <- "P"
outputfolder <- "/Volumes/Metab/Untargeted Metabolomics/Marten/Individual_SinglePatients/Boxplots_SinglePatients/"

# Get bioinformatics folder in all projects. The early ones contain 2, some contain none in 
# which the content of the bioinformatics folder is present in the project folder itself
for(project in all_projects){
  if(dir.exists(paste0(working_directory, project))) {
    setwd(paste0(working_directory, project))
  } else stop("project '", project, "' does not exist (yet) in this directory: ", working_directory)
  try(setwd("Bioinformatics"), silent = TRUE)
  try(setwd("Bioinformatics_20180824"), silent = TRUE)
  try(setwd("Bioinformatics_new_controls"), silent = TRUE)
  # Where the plots should be placed
  # plotdir <- paste0("/Users/mkerkho7/DIMS2_repo/Results_DIMS2/", project, "/plots/adducts")
  



  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Initialise function, create data for plots ------------------------------
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # sum positive and negative adductsums
  # outlist <- initialize("/Users/mkerkho7/DIMS2_repo/Results_DIMS2/")
  outlist <- initialize(outputfolder = outputfolder)
  outlist <- outlist$adducts
  outlist <- outlist[-grep("Exogenous", outlist[,"relevance"], fixed = TRUE),]
  outlist <- outlist[-grep("exogenous", outlist[,"relevance"], fixed = TRUE),]
  outlist <- outlist[-grep("Drug", outlist[,"relevance"], fixed = TRUE),]




  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Boxplots as they appear in the excel files ------------------------------
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  # This function will create the boxplots via the scripts 'statistics_z_4export' and 'plotBoxPlot'/'plotBoxPlot_Marten
  cat("start boxplots for",project,"\n")
  outlist <- statistics_z_4export(peaklist = as.data.frame(outlist), 
                                  plotdir = paste0(outputfolder, project, "/plots/adducts"), 
                                  patients = getPatients(outlist), 
                                  adducts = adducts, 
                                  control_label = control_label, 
                                  case_label = case_label)
}
