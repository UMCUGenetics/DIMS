removeFromRepl.pat <- function(bad_samples, repl.pattern, groupNames, nrepl) {
  # bad_samples=remove_pos
  
  tmp = repl.pattern
  
  removeFromGroup=NULL
  
  for (i in 1:length(tmp)){
    tmp2 = repl.pattern[[i]]
    
    remove=NULL
    
    for (j in 1:length(tmp2)){
      if (tmp2[j] %in% bad_samples){
        message(tmp2[j])
        message(paste("remove",tmp2[j]))
        message(paste("remove i",i))
        message(paste("remove j",j))
        
        remove = c(remove, j)
      }
    }
    
    if (length(remove)==nrepl) removeFromGroup=c(removeFromGroup,i) 
    if (!is.null(remove)) repl.pattern[[i]]=repl.pattern[[i]][-remove]
  }
  
  if (length(removeFromGroup)!=0) {
    groupNames=groupNames[-removeFromGroup]
    repl.pattern=repl.pattern[-removeFromGroup]
  }  
    
  return(list("pattern"=repl.pattern, "groupNames"=groupNames))
  
}
