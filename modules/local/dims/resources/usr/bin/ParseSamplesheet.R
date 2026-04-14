# define parameters
library("argparse")
# library("DIMS-R")
# as soon as the R package is created, it will be included in the docker image. For now, source file:
source("../../../../../development/DIMS-R_init/R/parse_samplesheet_functions.R")

parser <- ArgumentParser(description = "ParseSamplesheet")

parser$add_argument("--samplesheet", dest = "sample_sheet",
                    help = "Samplesheet txt file", required = TRUE)

args <- parser$parse_args()

sample_sheet <- read.csv(args$sample_sheet, sep = "\t")

# generate the replication pattern
repl_pattern <- generate_repl_pattern(sample_sheet)

# save replication pattern to file
save(repl_pattern, file = "replication_pattern.RData")

# write the replication pattern to text file for troubleshooting purposes
sink("replication_pattern.txt")
print(repl_pattern)
sink()

