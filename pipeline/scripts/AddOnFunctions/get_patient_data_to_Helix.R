get_patient_data_to_Helix <- function(metab_interest_sorted, metab_list_all){
  # Combine Z-scores of metab groups together
  df_all_metabs_zscores <- bind_rows(metab_interest_sorted)
  # Change columnnames 
  colnames(df_all_metabs_zscores) <- c("HMDB_name", "Patient", "Z_score")
  # Change Patient column to character instead of factor
  df_all_metabs_zscores$Patient <- as.character(df_all_metabs_zscores$Patient)
  
  # Delete whitespaces HMDB_name 
  df_all_metabs_zscores$HMDB_name <- str_trim(df_all_metabs_zscores$HMDB_name, "right")
  # Split HMDB_name column on "nitine;" for match DIMS_Helix_table
  df_all_metabs_zscores$HMDB_name_split <- str_split_fixed(df_all_metabs_zscores$HMDB_name, "nitine;", 2)[,1]
  
  # Combine stofgroepen
  DIMS_Helix_table <- bind_rows(metab_list_all)
  # Filter table for metabolites for Helix
  DIMS_Helix_table <- DIMS_Helix_table %>% filter(Helix == "ja")
  # Split HMDB_name column on "nitine;" for match df_all_metabs_zscores
  DIMS_Helix_table$HMDB_name_split <- str_split_fixed(DIMS_Helix_table$HMDB_name, "nitine;", 2)[,1]
  DIMS_Helix_table <- DIMS_Helix_table %>% select(HMDB_name_split, Helix_naam, high_zscore, low_zscore)
  
  # Filter DIMS results for metabolites for Helix
  df_metabs_Helix <- df_all_metabs_zscores %>% filter(HMDB_name_split %in% DIMS_Helix_table$HMDB_name_split)
  # Combine DIMS_Helix_table and df_metabs_Helix, adding Helix codes etc.
  df_metabs_Helix <- df_metabs_Helix %>% left_join(DIMS_Helix_table, by = join_by(HMDB_name_split))
  # print(df_metabs_Helix %>% filter(HMDB_name_split %in% c("C16:1-OH-car","C18-OH-car")))
  
  df_metabs_Helix <- df_metabs_Helix %>% select(HMDB_name, Patient, Z_score, Helix_naam, high_zscore, low_zscore)
  
  return(df_metabs_Helix)
}