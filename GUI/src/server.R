function(input, output, session) {
  shinyDirChoose(input, "input_folder", roots = c(home = config$root), filetypes=c('raw'))
  
  sampleSheet <- reactiveVal() # allows usage throughout entire app as sampleSheet()
  
  getSampleSheet <- function() {
    inFile <- input$samplesheet
    if (is.null(inFile))
      return(NULL)
    samples <- read.csv(inFile$datapath,
                        header = TRUE,
                        sep = "\t",
                        quote = "")
    return(samples)
  }
  
  ### Start Select Input Folder
  observeEvent(input$input_folder, {
    input_folder_name <- paste(as.vector(unlist(input$input_folder['path']))[-1], collapse = "/", sep="")
    
    if (input_folder_name != '') {
      df <- getSampleSheet()
      
      if (!is.null(df)) {
        
        # Check files with sample sheet, set true if the file from sample sheet was
        # found in the selected folder
        files <- list.files(path = paste(config$root, input_folder_name, sep = "/"), pattern = ".raw$")
        files <- gsub(files, pattern=".raw$", replacement = "")
        df$File_Found <- df[,1] %in% files
        sampleSheet(df) # set sampleSheet equal to df
        
        # Show data table
        output$table = DT::renderDataTable(df, 
                                           server = TRUE,
                                           selection = list(mode = 'multiple', 
                                                            selected = rownames(df)))
        # Set Run Name parameter
        updateTextInput(session, "run_name", value = gsub(" ", "_", input_folder_name))
        
        # Create (de)select all button
        output$select <- renderUI({
          column(3, actionButton("select_button", label = "De(select) All"))
        })
      }
    }
  })
  ### End Select Input Folder
  
  ### Triggers everytime a row is (de)selected
  observeEvent(input$table_rows_selected, {
    output$count <- renderText({ paste("Total selected: ", length(input$table_rows_selected)) })
  })
  
  ### Triggers when the (de)select button is pressed
  observeEvent(input$select_button, {
    df <- dataTableProxy("table", session)
    if (input$select_button %% 2 == 0) {
      DT::selectRows(df, input$table_rows_all)
    } else {
      DT::selectRows(df, NULL)
    }
  })
  
  ### Triggers when the matrix drop-down button in settings is pressed
  observeEvent(input$matrix, {
    if (!is.na(input$matrix)) {
      updateSelectInput(session, "thresh2remove", selected = config$thresh2remove[[input$matrix]])
    }
  })
  
  output$hide_panel <- eventReactive(input$check_button, TRUE, ignoreInit = TRUE)
  outputOptions(output, "hide_panel", suspendWhenHidden = FALSE)
  
  observeEvent(input$check_button, {
    passed = TRUE
    
    # check 1 : Selected samplesheet.
    if (is.null(input$samplesheet)) {
      output$check1 <- renderText({"No"})
      passed = FALSE
    } else {
      output$check1 <- renderText({"Yes"})
    }
    
    # check 2 : Selected data folder.
    if (is.na(input$input_folder['path'])) {
      output$check2 <- renderText({"No"})
      passed = FALSE
    } else {
      output$check2 <- renderText({"Yes"})
    }
    
    # check 3 : All selected samples were found in data folder.
    selected_samples <- sampleSheet()[input$table_rows_selected,]
    if (is.null(sampleSheet()) || FALSE %in% selected_samples$File_Found) {
      output$check3 <- renderText({"No"})
      passed = FALSE
    } else {
      output$check3 <- renderText({"Yes"})
    }
    
    # check 4 : Every sample has the correct amount of technical replicates.
    t_reps <- trimws(selected_samples[,1]) # technical replicates / samples, usually 3 per biological replicate
    b_reps <- trimws(selected_samples[,2]) # biological replicates / patients
    wrong_t_rep_count = FALSE
    for (b_rep in unique(b_reps)) {
      if (sum(b_reps == b_rep) != input$nrepl) {
        wrong_t_rep_count = TRUE
      }
    }
    if (length(t_reps) == 0 || wrong_t_rep_count || length(t_reps) / input$nrepl != length(unique(b_reps))) {
      output$check4 <- renderText({"No"})
      passed = FALSE
    } else {
      output$check4 <- renderText({"Yes"})
    }
    
    # check 5 : Parameters 
    if (input$login == '' ||
        input$password == '' ||
        input$email == '' ||
        input$run_name == '') {
      output$check5 <- renderText({"No"})
      passed = FALSE
    } else {
      output$check5 <- renderText({"Yes"})
    }
    
    # check 6 : HPC submit node
    tryCatch({
      cat("Connecting to:", config$ssh_submit, "...\n")
      ssh_submit <- ssh_connect(paste0(input$login,"@",config$ssh_submit), passwd = input$password)
      output$check6 <- renderText({"Yes"})
    }, error = function(e) {
      output$check6 <- renderText({"No"})
      passed = FALSE
    })
    
    # check 7 : HPC transfer node
    tryCatch({
      cat("Connecting to:", config$ssh_transfer, "...\n")
      ssh_transfer <- ssh_connect(paste0(input$login,"@",config$ssh_transfer), passwd = input$password)
      cat("Disconnecting from:", config$ssh_transfer, "...\n\n")
      ssh_disconnect(ssh_transfer)
      output$check7 <- renderText({"Yes"})
    }, error = function(e) {
      output$check7 <- renderText({"No"})
      passed = FALSE
    })
    
    
    if (exists("ssh_submit")) {
      # fail = 0 if dir doesn't exist or is empty, 1 if exists and not empty
      hpc_input_dir = paste(config$base, "raw_data", input$run_name, sep="/")
      hpc_output_dir = paste(config$base, "processed", input$run_name, sep="/")
      
      # check 8 : raw data folder
      fail <- ssh_exec_wait(ssh_submit, paste0("if [ -d ", hpc_input_dir," ]; then rmdir ", hpc_input_dir,"; fi"))
      if (fail > 0) {
        output$check8 <- renderText({"No"})
        passed = FALSE
      } else {
        output$check8 <- renderText({"Yes"})
      }
      
      # check 9 : processed data folder
      fail <- ssh_exec_wait(ssh_submit, paste0("if [ -d ", hpc_output_dir," ]; then rmdir ", hpc_output_dir,"; fi"))
      if (fail > 0) {
        output$check9 <- renderText({"No"})
        passed = FALSE
      } else {
        output$check9 <- renderText({"Yes"})
      }
      
      cat("Disconnecting from:", config$ssh_submit, "...\n\n")
      ssh_disconnect(ssh_submit)
    } else {
      output$check8 <- renderText({"No"})
      output$check9 <- renderText({"No"})
      passed = FALSE
    }
    
    if (passed) {
      output$run_button <- renderUI({
        div(
          column(8, p(tags$b("5) Start the pipeline..."))),
          column(4, actionButton("run_button", "Run"))
        )
      })
    }
  })
  
  ### Start run
  observeEvent(input$run_button, {
    
    ### Create all the paths 
    hpc_input_dir = paste(config$base, "raw_data", input$run_name, sep="/")
    hpc_output_dir = paste(config$base, "processed", input$run_name, sep="/")
    hpc_log_dir = paste(config$base, "processed", input$run_name, "logs", "queue", sep="/")
    
    ### Make init.RData (repl.pattern)
    selected_samples <- sampleSheet()[input$table_rows_selected,]
    t_reps <- trimws(selected_samples[,1]) # technical replicates / samples, usually 3 per biological replicate
    b_reps <- trimws(selected_samples[,2]) # biological replicates / patient
    b_reps <- gsub('[^-.[:alnum:]]', '_', b_reps)
    
    repl.pattern = c()
    for (a in 1:length(unique(b_reps))) {  # number of individual biological samples
      tmp = c()
      for (b in input$nrepl:1) {
        i = ((a*input$nrepl)-b)+1
        tmp <- c(tmp, t_reps[i])
      }
      repl.pattern <- c(repl.pattern, list(tmp))
    }
    names(repl.pattern) = unique(b_reps)
    save(repl.pattern, file = paste(tmp_dir, "init.RData", sep = "/"), version = 2)
    
    ### Save sample sheet
    write.table(selected_samples, file = paste(tmp_dir, "sampleNames_out.txt", sep = "/"), quote = FALSE, sep= "\t", row.names = FALSE)
    
    ### Create settings.config
    file_con = file(paste(tmp_dir, "settings.config", sep = "/"))
    parameters <- c(
      paste("# Created by", config$commit, "on", format(Sys.time(), "%b %d %Y %X")),
      paste0("thresh_pos=", input$thresh_pos),
      paste0("thresh_neg=", input$thresh_neg),
      paste0("dims_thresh=", input$dims_thresh),
      paste0("trim=", input$trim),
      paste0("nrepl=", input$nrepl),
      #paste0("normalization=", input$normalization),
      paste0("normalization=", "disabled"), # temporary
      paste0("thresh2remove=", input$thresh2remove),
      paste0("resol=", input$resol),
      paste0("email=", input$email),
      paste0("matrix=", input$matrix),
      paste0("z_score=", input$z_score),
      paste0("proteowizard=", config$proteowizard),
      paste0("db=", config$db),
      paste0("db2=", config$db2)
    )
    
    writeLines(parameters, file_con, sep = "\n")
    close(file_con)
    
    ### Connect to submit server and make the raw data folder
    cat("Connecting to:", config$ssh_submit, "...\n")
    ssh_submit <- ssh_connect(paste0(input$login,"@",config$ssh_submit), passwd = input$password)
    cat("Making folder", hpc_input_dir, "...\n")
    ssh_exec_wait(ssh_submit, paste("mkdir", hpc_input_dir))
    cat("Disconnecting from:", config$ssh_submit, "...\n\n")
    ssh_disconnect(ssh_submit)
    
    ### Connect to transfer server
    cat("Connecting to:", config$ssh_transfer, "...\n")
    ssh_transfer <- ssh_connect(paste0(input$login,"@",config$ssh_transfer), passwd = input$password)
    
    ### Transfer over RAW data
    input_folder_name <- paste(as.vector(unlist(input$input_folder['path']))[-1], collapse = "/", sep="")
    input_dir = paste(config$root, input_folder_name, sep = "/")
    cat("Copying files from", input_dir, "to:", hpc_input_dir, "... (ignore the %)\n")
    
    scp_upload(ssh_transfer, 
               list.files(path = input_dir, pattern = ".raw$", full.names = TRUE), 
               to = hpc_input_dir)
    
    ### Transfer over the tmp files to raw data folder (init.RData, settings.config)
    cat("Copying files from", tmp_dir, "to:", hpc_input_dir, "...\n")
    scp_upload(ssh_transfer, 
               list.files(tmp_dir, full.names = TRUE), 
               to = hpc_input_dir)
    
    ### Disconnect transfer server
    cat("Disconnecting from:", config$ssh_transfer, "...\n\n")
    ssh_disconnect(ssh_transfer)
    
    if (config$run_pipeline) {
      ### Start the pipeline
      cat("Connecting to:", config$ssh_submit, "...\n")
      ssh_submit <- ssh_connect(paste0(input$login,"@",config$ssh_submit), passwd = input$password)
      cmd = paste("cd", config$script_dir, "&& sh run.sh -i", hpc_input_dir, "-o", hpc_output_dir)
      cat("Starting the pipeline with:", cmd, "...\n")
      ssh_exec_wait(ssh_submit, 
                    cmd, 
                    std_out = paste(tmp_dir, "0-queueConversion", sep="/"), 
                    std_err = paste(tmp_dir, "0-queueConversion", sep="/"))
      cat("Disconnecting from:", config$ssh_submit, "...\n\n")
      ssh_disconnect(ssh_submit)
      
      
      ### Copy over the log file that was created when starting the pipeline
      cat("Connecting to:", config$ssh_transfer, "...\n")
      ssh_transfer <- ssh_connect(paste0(input$login,"@",config$ssh_transfer), passwd = input$password)
      cat("Copying over log file to:", hpc_log_dir, "...\n")
      scp_upload(ssh_transfer, 
                 paste(tmp_dir, "0-queueConversion", sep="/"), 
                 to = hpc_log_dir)
      cat("Disconnecting from:", config$ssh_transfer, "...\n\n")
      ssh_disconnect(ssh_transfer)
    }
    
    ### Done
    stopApp(returnValue = invisible())
  })
  ### End run
  
}