# load required package
suppressPackageStartupMessages(library("xcms"))
library("argparse")
# library("DIMS-R")
# as soon as the R package is created, it will be included in the docker image. For now, source file:
source("../../../../../development/DIMS-R_init/R/create_bins_functions.R")

# define parameters
parser <- ArgumentParser(description = "CreateBins")

parser$add_argument("--mzML_filepath", dest = "mzML_filepath",
                    help = "File path to the mzML file used", required = TRUE)
parser$add_argument("--trim_param", dest = "trim_param",
                    help = "Initial value of trim parameter (typically 0.1)", required = TRUE)
parser$add_argument("--resolution", dest = "resolution",
                    help = "Value for resolution (typically 140000)", required = TRUE)

args <- parser$parse_args()

trim <- as.numeric(args$trim_param)
resol <- as.numeric(args$resolution)

# read in mzML file
raw_data <- suppressMessages(xcms::xcmsRaw(args$mzML_filepath))

# set trim parameters and save to file
get_trim_parameters(trim, raw_data)

# Determine mass-over-charge range (m/z)
low_mz  <- raw_data@mzrange[1]
high_mz <- raw_data@mzrange[2]

# create bins and save to file
create_empty_bins(low_mz, high_mz)

# save highest mz to file
save(high_mz, file = "highest_mz.RData")
