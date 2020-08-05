### Settings

# Root for raw data file selector
root <- "C:/Xcalibur/data/Research"

# Root for experimental design file selector (sample sheet)
root2 <- "Y:/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects"

# Locations on HPC
base <- "/hpc/dbg_mz"
script_dir <- paste0(base, "/production/DIMS/pipeline")
db <- paste0(base, "/tools/db/HMDB_add_iso_corrNaCl_withIS_withC5OH.RData")
db2 <- paste0(base, "/tools/db/HMDB_with_info_relevance_IS_C5OH.RData")

### Default parameters - for lists it defaults to the first one
run_pipeline <- TRUE  # put on FALSE if you solely want to upload data

# Everything below here doesn't need to be edited for every run, 
# as the parameters in the GUI override these
login <- ""
email <- ""
run_name <- ""
nrepl <- 3
normalization <- list("disabled", "total_IS", "total_ident", "total")
matrix <- list("DBS", "Plasma", "CSF", "Research")
trim <- 0.1
resol <- list(17500, 35000, 70000, 140000, 280000)
default_resol <- 4  # in the list above
dims_thresh <- 100

thresh2remove <- vector(mode = "list", length = 4)
names(thresh2remove) <- matrix
thresh2remove$DBS <- 500000000
thresh2remove$Plasma <- 1000000000
thresh2remove$CSF <- 1000000000
thresh2remove$Research <- 100000000

thresh_pos <- 2000
thresh_neg <- 2000
z_score <- 1

### Connect to HPC
ssh_submit <- "hpcsubmit.op.umcutrecht.nl"
ssh_transfer <- "hpct01.op.umcutrecht.nl"


### Log git branch and commit ID
commit <- paste(system("git name-rev HEAD", intern = TRUE), 
                system("git rev-parse HEAD", intern = TRUE))

### Max allowed time and memory per queued job 
jobs <- list(
  job_0 = list(time = "00:05:00", mem = "2G"),
  job_1 = list(time = "00:05:00", mem = "2G"), 
  job_2 = list(time = "00:10:00", mem = "4G"), 
  job_3 = list(time = "01:30:00", mem = "5G"), 
  job_4 = list(time = "01:00:00", mem = "8G"), 
  job_5 = list(time = "02:00:00", mem = "8G"), 
  job_6 = list(time = "02:30:00", mem = "4G"), 
  job_7 = list(time = "01:00:00", mem = "8G"), 
  job_8 = list(time = "01:00:00", mem = "8G"), 
  job_9a = list(time = "00:30:00", mem = "4G"), 
  job_9b = list(time = "00:30:00", mem = "4G"), 
  job_10 = list(time = "01:00:00", mem = "8G"), 
  job_11 = list(time = "03:00:00", mem = "8G"), 
  job_12 = list(time = "00:30:00", mem = "8G"), 
  job_13 = list(time = "01:00:00", mem = "8G"), 
  job_14 = list(time = "00:05:00", mem = "500M"),
  job_hmdb1 = list(time = "03:00:00", mem = "8G"),
  job_hmdb2 = list(time = "03:00:00", mem = "8G"),
  
  queue_0 = list(time = "00:05:00", mem = "1G"), 
  queue_1 = list(time = "00:05:00", mem = "1G"), 
  queue_2 = list(time = "00:05:00", mem = "500M"), 
  queue_3 = list(time = "00:05:00", mem = "500M"), 
  queue_4 = list(time = "00:05:00", mem = "500M"), 
  queue_5 = list(time = "00:05:00", mem = "500M"), 
  queue_6 = list(time = "00:05:00", mem = "500M")
)