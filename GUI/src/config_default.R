### Settings

# Root for raw data file selector
root <- "C:/Xcalibur/data/Research"

# Root for experimental design file selector (sample sheet)
root2 <- "Y:/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects"

# Locations on HPC
base <- "/hpc/dbg_mz"
script_dir <- paste0(base, "/production/DIMS/pipeline")
proteowizard <- paste0(base, "/tools/proteowizard_3.0.19252-aa45583de")
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

thresh2remove <- vector(mode = "list", length = 3)
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


# TODO Default job times
