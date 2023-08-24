# function to test whether intensity and Z-score columns match
same_samplename <- function(int_col_name, zscore_col_name) {
  paste0(int_col_name, "_Zscore") == zscore_col_name
}
