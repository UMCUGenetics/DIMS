prepare_alarmvalues <- function(pt_name, metab_interest_sorted) {
  # extract data for patient of interest (pt_name)
  pt_list <- all_metab[which(all_metab$variable==pt_name), ]
  # remove column with patient name
  pt_list <- pt_list[ , -2]
  # round off Z-scores
  pt_list$value <- round(as.numeric(pt_list$value), 2)
  
  # Remove trailing white spaces
  pt_list$HMDB_name <- str_trim(pt_list$HMDB_name, "right")
  # Split HMDB_name column on "nitine;" for match DIMS_Helix_table, add to new column to keep HMDB names
  pt_list$HMDB_name_split <- str_split_fixed(pt_list$HMDB_name, "nitine;", 2)[,1]
  
  # Combine stofgroepen
  DIMS_Helix_table <- bind_rows(metab_all)
  # Filter table for metabolites for Helix
  DIMS_Helix_table <- DIMS_Helix_table %>% filter(Helix == "ja")
  # Split HMDB_name column on "nitine;" for match df_all_metabs_zscores
  DIMS_Helix_table$HMDB_name <- str_split_fixed(DIMS_Helix_table$HMDB_name, "nitine;", 2)[,1]
  
  # Filter DIMS results for metabolites for Helix
  pt_metabs_Helix <- pt_list %>% filter(HMDB_name_split %in% DIMS_Helix_table$HMDB_name)
  
  # Make empty dataframes for metabolites above or below alarmvalues
  pt_list_high <- data.frame(HMDB_name = character(), value = numeric())
  pt_list_low <- data.frame(HMDB_name = character(), value = numeric())
  
  # Loop over individual metabolites
  for (metab in unique(pt_metabs_Helix$HMDB_name_split)){
    # Get data for individual metabolite
    pt_metab <- pt_metabs_Helix %>% filter(HMDB_name_split == metab)
    
    # Check if zscore is positive of negative
    if(pt_metab$value > 0) {
      # Get specific alarmvalue for metabolite
      high_zscore_cutoff_metab <- DIMS_Helix_table %>% filter(HMDB_name == metab) %>% pull(high_zscore)
      
      # If zscore is above the alarmvalue, add to pt_list_high table
      if(pt_metab$value > high_zscore_cutoff_metab) {
        pt_metab_high <- pt_metab %>% select(HMDB_name, value)
        pt_list_high <- rbind(pt_list_high, pt_metab_high)
      }
    } else {
      # Get specific alarmvalue for metabolite
      low_zscore_cutoff_metab <- DIMS_Helix_table %>% filter(HMDB_name == metab) %>% pull(low_zscore)
      
      # If zscore is below the alarmvalue, add to pt_list_low table
      if(pt_metab$value < low_zscore_cutoff_metab) {
        pt_metab_low <- pt_metab %>% select(HMDB_name, value)
        pt_list_low <- rbind(pt_list_low, pt_metab_low)
      }
    }
  }
  
  # sort tables on zscore
  pt_list_high <- pt_list_high %>% arrange(desc(value))
  pt_list_low <- pt_list_low %>% arrange(value)
  # add lines for increased, decreased
  extra_line1 <- c("Increased", "") 
  extra_line2 <- c("Decreased", "")
  # combine the two lists
  top_metab_pt <- rbind(extra_line1, pt_list_high, extra_line2, pt_list_low)
  # remove row names
  rownames(top_metab_pt) <- NULL
  # change column names for display
  colnames(top_metab_pt) <- c("Metabolite", "Z-score")

  return(top_metab_pt)
}
