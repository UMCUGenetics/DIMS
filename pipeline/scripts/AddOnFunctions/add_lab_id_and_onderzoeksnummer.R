add_lab_id_and_onderzoeksnummer <- function(df_metabs_Helix){
  # Split patient number into labnummer and Onderzoeksnummer
  for (row in 1:nrow(df_metabs_Helix)) {
    df_metabs_Helix[row,"labnummer"] <- gsub("[P\\.1]", "", df_metabs_Helix[row,"Patient"])
    labnummer_split <- strsplit(as.character(df_metabs_Helix[row, "labnummer"]), "M")[[1]]
    df_metabs_Helix[row, "Onderzoeksnummer"] <- paste0("MB",labnummer_split[1],"/",labnummer_split[2])
  }
  
  return(df_metabs_Helix)
}
