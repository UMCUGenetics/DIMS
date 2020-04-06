### Settings

# Root for raw data file selector
root <- "/Volumes/DATA/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects"

# Root for experimental design file selector (sample sheet)
root2 <- root

# Locations on HPC
base <- "/hpc/dbg_mz"
script_dir <- paste0(base, "/development/pipeline/DIMS")
proteowizard <- paste0(base, "/tools/proteowizard_3.0.19252-aa45583de")
db <- paste0(base, "/tools/db/HMDB_add_iso_corrNaCl_withIS_withC5OH.RData")
db2 <- paste0(base, "/tools/db/HMDB_with_info_relevance_IS_C5OH.RData")

### Default parameters - for lists it defaults to the first one
run_pipeline <- TRUE  # put on FALSE if you solely want to upload data
login <- "nvanunen"
email <- "n.vanunen@umcutrecht.nl"
run_name <- ""
nrepl <- 3
normalization <- list("disabled", "total_IS", "total_ident", "total")
matrix <- list("DBS", "Plasma", "Research")
trim <- 0.1
resol <- list(17500, 35000, 70000, 140000, 280000)
default_resol <- 4  # in the list above
dims_thresh <- 100

thresh2remove <- vector(mode = "list", length = 3)
names(thresh2remove) <- c("DBS", "Plasma", "Research")
thresh2remove$DBS <- 500000000
thresh2remove$Plasma <- 1000000000
thresh2remove$Research <- 100000000

thresh_pos <- 2000
thresh_neg <- 2000
z_score <- 1

### Connect to HPC
ssh_submit <- "hpcsubmit.op.umcutrecht.nl"
ssh_transfer <- "hpct01.op.umcutrecht.nl"
ssh_transfer <- ssh_submit


### Log git branch and commit ID
commit <- paste(system("git name-rev HEAD", intern = TRUE), 
                system("git rev-parse HEAD", intern = TRUE))


# TODO Default job times
