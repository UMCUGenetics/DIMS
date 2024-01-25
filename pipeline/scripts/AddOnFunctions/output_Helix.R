output_for_Helix <- function(protocol_name, df_metabs_Helix){
    
  # Remove positive controls
  df_metabs_Helix <- df_metabs_Helix %>% filter(grepl("M",Patient))
  
  # Add 'Vial' column, each patient has unique ID
  df_metabs_Helix <- df_metabs_Helix %>% 
    group_by(Patient) %>% 
    mutate(Vial = cur_group_id()) %>% 
    ungroup()
  
  # Split patient code into labnummer and Onderzoeksnummer
  for (row in 1:nrow(df_metabs_Helix)) {
    df_metabs_Helix[row,"labnummer"] <- gsub("^P|\\.[0-9]*", "", df_metabs_Helix[row,"Patient"])
    labnummer_split <- strsplit(as.character(df_metabs_Helix[row, "labnummer"]), "M")[[1]]
    df_metabs_Helix[row, "Onderzoeksnummer"] <- paste0("MB",labnummer_split[1],"/",labnummer_split[2])
  }
  
  # Add column with protocol name
  df_metabs_Helix$Protocol <- protocol_name
  
  # Change name Z_score and Helix_naam columns to Amount and Name
  change_columns <- c(Amount = "Z_score", Name = "Helix_naam")
  df_metabs_Helix <- df_metabs_Helix %>% rename(all_of(change_columns))
  
  # Select only necessary columns and set them in correct order
  df_metabs_Helix <- df_metabs_Helix %>% 
    select(c(Vial, labnummer, Onderzoeksnummer, Protocol, Name, Amount))
  
  # Remove duplicate patient-metabolite combinations ("leucine + isoleucine + allo-isoleucin_Z-score" is added 3 times)
  df_metabs_Helix <- df_metabs_Helix %>% 
    group_by(Onderzoeksnummer, Name) %>% distinct() %>% ungroup()
  
  return(df_metabs_Helix)
}