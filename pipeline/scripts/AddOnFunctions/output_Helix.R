output_for_Helix <- function(protocol_name, metab_all, metab_interest_sorted){
  # Combine Z-scores of metab groups together
  df_all_metabs_zscores <- bind_rows(metab_interest_sorted)
  colnames(df_all_metabs_zscores) <- c("HMDB_name", "Patient", "Z_score")
  df_all_metabs_zscores$Patient <- as.character(df_all_metabs_zscores$Patient)
  
  # Delete whitespaces HMDB_name 
  df_all_metabs_zscores$HMDB_name <- str_trim(df_all_metabs_zscores$HMDB_name, "right")
  # Split HMDB_name column on "nitine;" for match DIMS_Helix_table
  # df_all_metabs_zscores <- df_all_metabs_zscores %>% separate_wider_delim(HMDB_name, "nitine;", names = c("HMDB_name", NA), too_few = "align_start")
  df_all_metabs_zscores$HMDB_name <- str_split_fixed(df_all_metabs_zscores$HMDB_name, "nitine;", 2)[,1]
  
  # Combine stofgroepen
  DIMS_Helix_table <- bind_rows(metab_all)
  # Filter table for metabolites for Helix
  DIMS_Helix_table <- DIMS_Helix_table %>% filter(Helix == "ja")
  # Split HMDB_name column on "nitine;" for match df_all_metabs_zscores
  # DIMS_Helix_table <- DIMS_Helix_table %>% separate_wider_delim(HMDB_name, "nitine;", names = c("HMDB_name", NA), too_few = "align_start")
  DIMS_Helix_table$HMDB_name <- str_split_fixed(DIMS_Helix_table$HMDB_name, "nitine;", 2)[,1]
  DIMS_Helix_table$HMDB_name <- gsub("\"", "", DIMS_Helix_table$HMDB_name)
  
  # Filter DIMS results for metabolites for Helix
  df_metabs_Helix <- df_all_metabs_zscores %>% filter(HMDB_name %in% DIMS_Helix_table$HMDB_name)
  
  # Remove positive controls
  df_metabs_Helix <- df_metabs_Helix %>% filter(grepl("M",Patient))
  
  # Add 'Vial' column, each patient has unique ID
  df_metabs_Helix <- df_metabs_Helix %>% group_by(Patient) %>% mutate(Vial = cur_group_id()) %>% ungroup()
  
  # Combine DIMS_Helix_table and df_metabs_Helix, adding Helix codes etc.
  df_metabs_Helix <- df_metabs_Helix %>% left_join(DIMS_Helix_table, by = join_by(HMDB_name))
  
  # Split patient code into labnummer and Onderzoeksnummer
  for (row in 1:nrow(df_metabs_Helix)) {
    df_metabs_Helix[row,"labnummer"] <- gsub("^P|\\.[0-9]*", "", df_metabs_Helix[row,"Patient"])
    labnummer_split <- strsplit(as.character(df_metabs_Helix[row, "labnummer"]), "M")[[1]]
    df_metabs_Helix[row, "Onderzoeksnummer"] <- paste0("MB",labnummer_split[1],"/",labnummer_split[2])
  }
  
  # Add column with protocol name
  df_metabs_Helix$Protocol <- protocol_name
  
  # Remove unnecessary columns
  df_metabs_Helix <- df_metabs_Helix %>% select(-c(HMDB_name, Patient, Helix, HMDB_code))
  
  # Change name Z_score and Helix_naam columns to Amount and Name
  change_columns <- c(Amount = "Z_score", Name = "Helix_naam")
  df_metabs_Helix <- df_metabs_Helix %>% rename(all_of(change_columns))
  
  # Select only necessary columns and set them in correct order
  df_metabs_Helix <- df_metabs_Helix %>% select(c(Vial, labnummer, Onderzoeksnummer, Protocol, Name, Amount))
  
  # Remove duplicate patient-metabolite combinations ("leucine + isoleucine + allo-isoleucin_Z-score" is added 3 times)
  df_metabs_Helix <- df_metabs_Helix %>% group_by(Onderzoeksnummer, Name) %>% distinct() %>% ungroup()
  
  return(df_metabs_Helix)
}