#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2_test")

cat("Start excelExport.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

outdir <- cmd_args[1]
scripts <- cmd_args[2]

setwd(outdir)

source(paste(scripts, "AddOnFunctions/sourceDir.R", sep="/"))
sourceDir(paste(scripts, "AddOnFunctions", sep="/"))

options(digits = 16)
plotdir <- "plots/adducts"
sub <- 20000
subName <- c("", "_box")
fileName <- paste("xls", basename(outdir), sep = "/")
adducts <- TRUE
control_label <- "C"
case_label <- "P"
adducts <- TRUE
imageNum <- 1
#plotdir = file.path(plotdir)

# Load pos and neg adduct sums
load("adductSums_negative.RData")
adducts_neg1 <- outlist.tot
load("adductSums_positive.RData")
adducts_pos1 <- outlist.tot
rm(outlist.tot)

# Only continue with patients (columns) that are in both pos and neg
common_patients = intersect(colnames(adducts_neg1), colnames(adducts_pos1))
adducts_neg2 = adducts_neg1[, common_patients]
adducts_pos2 = adducts_pos1[, common_patients]

# Find indexes of neg hmdb code that are also found in pos and vice versa
common_rows_neg = which(rownames(adducts_neg2) %in% rownames(adducts_pos2))
common_rows_pos = which(rownames(adducts_pos2) %in% rownames(adducts_neg2))

# Get number of columns
columns_pos <- (dim(adducts_pos2)[2])
columns_neg <- (dim(adducts_neg2)[2])

# Only continue with HMDB codes (rows) that were found in both pos and neg mode and remove last column
new_rows_neg <- rownames(adducts_neg2)[common_rows_neg]
adducts_neg3 <- adducts_neg2[new_rows_neg, 1:(columns_neg - 1)]
adducts_neg3_left <- adducts_neg2[-common_rows_neg, ]

new_rows_pos <- rownames(adducts_pos2)[common_rows_pos]
adducts_pos3 <- adducts_pos2[new_rows_pos, 1:(columns_pos - 1)]
adducts_pos3_left <- adducts_pos2[-common_rows_pos, ]
adducts_hmdb <- adducts_pos2[new_rows_pos, columns_pos]

# Combine positive and negative numbers and paste back HMDB column
adducts_sum <- apply(adducts_neg3, 2, as.numeric) + apply(adducts_pos3, 2, as.numeric)
rownames(adducts_sum) <- rownames(adducts_pos3)
adducts_sum2 <- cbind(adducts_sum, "HMDB_name" = adducts_hmdb)
adducts_sum3 <- rbind(adducts_sum2, adducts_neg3_left, adducts_pos3_left)

# Create new matrix
dummy_rows = rep(NA, dim(adducts_sum3)[1])
outlist_adducts_HMDB = cbind(
  "mzmed.pgrp" = dummy_rows,
  "fq.best" = dummy_rows,
  "fq.worst" = dummy_rows,
  "nrsamples" = dummy_rows,
  "mzmin.pgrp" = dummy_rows,
  "mzmax.pgrp" = dummy_rows,
  adducts_sum3
)

# Add assi_HMDB column with all the HMDB IDs
outlist_adducts_HMDB = cbind(outlist_adducts_HMDB, "assi_HMDB" = rownames(outlist_adducts_HMDB))
###################################################################

# ToDo: If 2 P's in sample names!!!!!!!!!!!!!
# Get all patient IDs
tmp = colnames(outlist_adducts_HMDB)[7:length(colnames(outlist_adducts_HMDB))]
patients = tmp[grep("P", tmp, fixed = TRUE)]
# Remove the .1 after patient IDs (P128.1 -> P128)
patients = unique(as.vector(unlist(lapply(strsplit(patients, ".", fixed = TRUE), function(x)
  x[1]))))
# Sort on patient ID (128, 135 ...)
patients = sort(as.numeric(unique(as.vector(unlist(
  lapply(strsplit(patients, "P", fixed = TRUE), function(x)
    x[2])
)))))

# Add Z-scores and create plots
outlist_adducts_stats = statistics_z(
  as.data.frame(outlist_adducts_HMDB),
  #as.data.frame(adducts_neg_pos),
  "plots/adducts",
  "allpgrps_stats.txt",
  control_label,
  case_label,
  sortCol = "mzmed.pgrp",
  patients,
  plot = FALSE,
  adducts = TRUE
)

# Remove the empty columns that were added earlier ..
outlist_adducts_stats = outlist_adducts_stats[, -c(1:6)]
###################################################################

hmdb_name_index = which(colnames(outlist_adducts_stats) == "HMDB_name")
order_index_int_adduct = order(colnames(outlist_adducts_stats)[1:(hmdb_name_index - 1)])
outlist_adducts_stats_sorted = cbind(outlist_adducts_stats[, order_index_int_adduct], outlist_adducts_stats[, hmdb_name_index:(dim(outlist_adducts_stats)[2])])

tmp_index = grep("_Zscore", colnames(outlist_adducts_stats_sorted), fixed = TRUE)
tmp_index_order = order(colnames(outlist_adducts_stats_sorted[, tmp_index]))
tmp = outlist_adducts_stats_sorted[, tmp_index[tmp_index_order]]
outlist_adducts_stats_sorted = outlist_adducts_stats_sorted[, -tmp_index]
outlist_adducts_stats_sorted = cbind(outlist_adducts_stats_sorted, tmp)

outlist_adducts_stats = outlist_adducts_stats_sorted
rm(outlist_adducts_stats_sorted)
###################################################################

load("/hpc/dbg_mz/tools/db/HMDB_with_info_relevance.RData")

outlist_adducts_stats = cbind("HMDB_code" = rownames(outlist_adducts_stats), outlist_adducts_stats)

outlist_adducts = outlist_adducts_stats
PeaksInList = which(rownames(outlist_adducts) %in% rownames(rlvnc))
outlist_adducts = cbind(outlist_adducts[PeaksInList, ], as.data.frame(rlvnc[rownames(outlist_adducts)[PeaksInList], ]))

load("outlist_identified_negative.RData")
outlist_neg_ident = outlist.ident
outlist_neg_not_ident = outlist.not.ident
rm(outlist.ident, outlist.not.ident)

load("outlist_identified_positive.RData")
outlist_pos_ident = outlist.ident
outlist_pos_not_ident = outlist.not.ident
rm(outlist.ident, outlist.not.ident)

#save(outlist_neg.not.ident, outlist_pos.not.ident, outlist_neg.ident, outlist_pos.ident, outlist_adducts, file=rdataFile)
save(outlist_adducts, outlist_neg_ident, outlist_pos_ident, file = "ViewInShiny.RData")

outlist <-
  list("adducts" = outlist_adducts,
       "negative" = outlist_neg_ident,
       "positive" = outlist_pos_ident)

outlist <- outlist$adducts

# filtering
outlist = outlist[-grep("Exogenous", outlist[, "relevance"], fixed = TRUE), ]
outlist = outlist[-grep("exogenous", outlist[, "relevance"], fixed = TRUE), ]
outlist = outlist[-grep("Drug", outlist[, "relevance"], fixed = TRUE), ]
outlist = statistics_z_4export(
  as.data.frame(outlist),
  plotdir,
  getPatients(outlist),
  adducts,
  control_label,
  case_label
)


# Generate Excel File(s)
unlink("xls", recursive = TRUE)
dir.create("xls", showWarnings = F)

peaklist = as.data.frame(outlist)

end = 0
i = 0

if (dim(peaklist)[1] >= sub & (sub > 0)) {
  for (i in 1:floor(dim(peaklist)[1] / sub)) {
    start = -(sub - 1) + i * sub
    end = i * sub
    message(paste0(start, ":", end))

    genExcelFileV3(peaklist[c(start:end), ],
                   imageNum,
                   paste(fileName, i, sep = "_"),
                   plotdir,
                   subName,
                   adducts)
  }
}

start = end + 1
end = dim(peaklist)[1]
message(start)
message(end)
genExcelFileV3(peaklist[c(start:end), ],
               imageNum,
               paste(fileName, i + 1, sep = "_"),
               plotdir,
               subName,
               adducts)
