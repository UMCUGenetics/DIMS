function(input, output, session) {
  observe({
    
    shinyDirChoose(input, "raw_file_location", roots = c(home=root))
    shinyFileChoose(input, "experimental_design", roots = c(home=root2))
    
    ### Start Select Raw File Location
    observeEvent(input$raw_file_location, {
      inputDirName <<- paste(as.vector(unlist(input$raw_file_location['path']))[-1], collapse = "/", sep="")
      updateTextInput(session, "run_name", value = inputDirName)
    })
    ### End Select Raw File Location
    
    ### Start Select Experimental Design
    observeEvent(input$experimental_design, {
      
      if (!is.na(input$experimental_design['files'])) {
        file <- paste(as.vector(unlist(input$experimental_design['files'])), collapse = "/", sep="")
        df <<- read.csv(paste0(root2, file),
                        header = TRUE,
                        sep = "\t",
                        quote = "")
        
        x=1:dim(df)[1]
        names(x)=df$Sample_Name
        updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x), selected = as.list(x))
      }
    })
    ### End Select Experimental Design
    
    ### Start select all
    observeEvent(input$check_all, {
      if (length(df) > 0) {
        x=1:dim(df)[1]
        names(x)=df$Sample_Name
        if (length(input$inCheckboxGroup) > 0) {
          updateCheckboxGroupInput(session, "inCheckboxGroup", choices = as.list(x), selected = NULL)
        } else {
          updateCheckboxGroupInput(session, "inCheckboxGroup", choices = as.list(x), selected = as.list(x))
        }
      }
    })
    ### End select all
    
    ### Start check individual
    observeEvent(input$inCheckboxGroup, {
      output$contents = renderTable(df[input$inCheckboxGroup,][1], 
                                    striped = TRUE, 
                                    hover = TRUE, 
                                    colnames = FALSE)
      if (is.null(input$inCheckboxGroup)) {
        updateActionButton(session, "check_all", label = "Select All")
      } else {
        updateActionButton(session, "check_all", label = "Deselect All")
      }
    }, ignoreNULL = FALSE)
    ### End check individual 
    
    ### Start run
    observeEvent(input$run, {
      ### Check if there is input
      if (is.na(input$raw_file_location['path'])) {
        session$sendCustomMessage(type = "testmessage", message = "Choose a file location!")
      } else if (is.na(input$experimental_design['files'])) {
        session$sendCustomMessage(type = "testmessage", message = "Choose an experimental design!")
      } else if (input$email == '') {
        session$sendCustomMessage(type = "testmessage", message = "Enter your email!")
      } else if (input$run_name == '') {
        session$sendCustomMessage(type = "testmessage", message = "Enter a name for the run!")
      } else {
        ### Make init.RData (repl.pattern)
        sampleNames=as.vector(unlist(df$File_Name))
        nsampgrps = length(sampleNames)/input$nrepl # number of individual biological samples
        repl.pattern = NULL
        if (input$nrepl == 3){
          for (x in 1:nsampgrps) { repl.pattern <- c(repl.pattern, list(c(sampleNames[x*(input$nrepl)-2],sampleNames[x*input$nrepl-1],sampleNames[x*input$nrepl])))}
        } else if (input$nrepl == 5){
          for (x in 1:nsampgrps) { repl.pattern <- c(repl.pattern, list(c(sampleNames[x*(input$nrepl)-4],sampleNames[x*input$nrepl-3],sampleNames[x*input$nrepl-2],sampleNames[x*input$nrepl-1],sampleNames[x*input$nrepl])))}
        }
        
        groupNames=unique(as.vector(unlist(df$Sample_Name)))
        names(repl.pattern) = groupNames
        
        save(repl.pattern, file=paste(tmpDir, "init.RData", sep="/")) 
        
        ### Save sample sheet
        write.table(df[input$inCheckboxGroup,], file=paste(tmpDir, "sampleNames_out.txt", sep="/"), quote = FALSE, sep="\t",row.names = FALSE)
        files=paste(root, inputDirName, paste(as.vector(unlist(df[input$inCheckboxGroup, 1])),"raw", sep="."), sep="/")
        
        output$samples = renderTable({ as.data.frame(files) })
      
        selectedSamples = df[input$inCheckboxGroup,]
        save(selectedSamples, file=paste(tmpDir, "selectedSamples.RData", sep="/"))
        remove = which(sampleNames %in% selectedSamples$File_Name)
        rval = NULL
        if (length(remove)>0) rval = removeFromRepl.pat(sampleNames[-remove], repl.pattern, groupNames, input$nrepl)
        
        repl.pattern=rval$pattern
        save(repl.pattern, file=paste(tmpDir, "init.RData", sep="/"))
        
        # Check samples with design
        samplesDesign = paste(as.vector(unlist(df[input$inCheckboxGroup, 1])), "raw", sep=".")
        raw = list.files(path = paste(root, inputDirName, sep="/"), pattern = "raw")
        index = which(samplesDesign %in% raw)
        
        
        if (length(samplesDesign) != length(index)){
          session$sendCustomMessage(type = "testmessage",
                                    message = "Design and mzXML files differ!")
        } else {
          
          fileConn = file(paste(tmpDir, "settings.config", sep = "/"))
          parameters <- c(paste0("thresh_pos=", input$thresh_pos),
                          paste0("thresh_neg=", input$thresh_neg),
                          paste0("dims_thresh=", input$dims_thresh),
                          paste0("trim=", input$trim),
                          paste0("nrepl=", input$nrepl),
                          paste0("normalization=", input$normalization),
                          paste0("thresh2remove=", input$thresh2remove),
                          paste0("resol=", input$resol),
                          paste0("email=", input$email)
          )
          
          writeLines(parameters, fileConn, sep = "\n")
          close(fileConn)
          
          base = "/hpc/dbg_mz"
          hpcInputDir = paste(base, "raw_data", input$run_name, sep="/")
          message(paste0("Files uploaded to: ", hpcInputDir))
          
          ### Create directory on HPC
          ssh_exec_wait(ssh, paste0("mkdir ", hpcInputDir))
          
          ### Copy over RAW data
          inputDir = paste(root, inputDirName, sep="/")
          scp_upload(ssh, list.files(inputDir, full.names = TRUE), to = hpcInputDir)
          
          ### Copy over other required files (init.RData, settings.config)
          scp_upload(ssh, list.files(tmpDir, full.names = TRUE), to = hpcInputDir)
          
          #ssh_exec_wait(ssh, paste0("sh ",base,"/development/DEV_Dx_metabolomics/run.sh -n ", inputDirName), std_out = "test.txt", std_err="test.txt")
          
          session$sendCustomMessage(type = "testmessage",
                                    message = "Samples will be processed @HPC cluster. This will take several hours! You will recieve an email when finished.")
        }
      }
    })
    ### End run
  })
}