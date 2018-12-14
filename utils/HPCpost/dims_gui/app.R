library("shiny")
library("shinyjs")
library("shinyFiles")
library("xcms")
library("Cairo")

# ################################## user settings ####################################################################
#user = "hhaijes-siepel"
user = "melferink"

#home = "hanneke"
home = "Martin"

#mail_address = "\"a.m.willemsen-8@umcutrecht.nl\""
mail_address = "m.elferink@umcutrecht.nl"
msconvert = "\"C:/ProteoWizard/ProteoWizard 3.0.11748/msconvert.exe\"" 

# Command Martin
pscp = "\"C:/PuTTY/pscp.exe\" -pw ***REMOVED*** -r -p "
putty = "\"C:/PuTTY/putty.exe\" -ssh melferink@hpcsubmit.op.umcutrecht.nl -pw ***REMOVED*** -m "

# Command Hanneke
# pscp = "\"C:/PuTTY/pscp.exe\" -pw ***REMOVED*** -r -p "
# putty = "\"C:/PuTTY/putty.exe\" -ssh hhaijes-siepel@hpcsubmit.op.umcutrecht.nl -pw ***REMOVED*** -m "
# \\ds.umcutrecht.nl\data\BG\metab

# raw data
#root = "Z:/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2018"
root = "Z:/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2018/Project 2018_006 Diagnosis_2017_DBS"

# experimental design (ME)
#root2 = "C:/R_workspace_ME/Experimental_design"   C-drive storage is too low!
root2="Z:/Metabolomics/DIMS_pipeline/R_workspace_ME/Experimental_design"

dims_dir = paste0("/hpc/shared/dbg_mz/", home, "/Direct-Infusion-Pipeline_2.1")
hpc_pipeline = paste0(user, "@hpct02.op.umcutrecht.nl:", dims_dir)
#hpc_pipeline = paste0(user, "@hpcs03.op.umcutrecht.nl:", dims_dir)
#####################################################################################################################

source("./HPCPostFunctions.R")
nrepl=3 # 5
width=512 #1024
height=384 #768
df = NULL

ui <- fluidPage(theme = "style.css",

  singleton( tags$head(tags$script(src = "message-handler.js")) ),
  
  # App title ----
  titlePanel(tags$b("DIMS pipeline")),
  
  tags$br(),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(

        p(tags$b("1) Choose raw file location...")),
        shinyDirButton("raw_file_location", "Browse...", "1) Choose raw file location..."),
        tags$br(),tags$br(),

        p(tags$b("2) Upload experimental design...")),
        shinyFilesButton("experimental_design", "Browse...", "2) Upload experimental design...", multiple=FALSE),
        tags$br(),tags$br(),
        # 
        # p(tags$b("4) Plot TICs")),
        # actionButton("plot_tics", "Plot"),
        # tags$br(),tags$br(),
        # 
        p(tags$b("4) Run")),
        actionButton("run", "Run")
        
      ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      useShinyjs(),
      tabsetPanel(id ="main_tabs", type = "tabs",
        tabPanel("Selection", fluidPage(tags$br(),
                        verbatimTextOutput("location"),
                        tags$br(),
                           
                        fluidRow(
                          column(6, p(tags$b("3) Select samples to be processed..."))),
                          column(3, actionButton("check_all", "Select / Deselect all"))
                        ),
                        tags$br(),
                        fluidRow(
                          column(3, checkboxGroupInput("inCheckboxGroup", "")),
                          column(6, tableOutput("contents"))
                        )
              )),
        # tabPanel("TICs", fluidPage(tags$br(),
        #                            div(id = "myapp",
        #                                uiOutput('images')
        #                            )
        # )),
        tabPanel("Exported files", fluidPage(tags$br(),
                        # tags$h5('Samples will be copied to HPC cluster and processed. This will take several hours! You will recieve an email when finished.'),
                        # downloadButton("downloadData", "Download"),
                        # tags$br(),
                        tableOutput("samples")
                        ))
      )
    )
  )
)

server <- function(input, output, session) {
  observe({

    shinyDirChoose(input, "raw_file_location", roots = c(home=root))
    shinyFileChoose(input, "experimental_design", roots = c(home=root2))
    
    # message(length(input$image1))
    # shinyjs::onclick("image1",  updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x)))
    shinyjs::onclick("image1",  session$sendCustomMessage(type = "testmessage", message = "Bingo!"))
    
    # shinyjs::alert("Thank you!")
    # shinyjs::reset()
    
    # shinyjs::onclick("image1",  output[["image1"]] <- renderImage({
    #   list(src = paste(getwd(),"remove.jpg", sep = "/"),
    #        alt = "Image failed to render")
    # }, deleteFile = FALSE))
    
    # observe({
    #     local({
    #       shinyjs::onclick("image1",  output$image1 <- renderImage({
    #         message(paste(getwd(),"remove.jpg", sep = "/"))
    #         list(src = paste(getwd(),"remove.jpg", sep = "/"),
    #              alt = "Image failed to render")
    #       }, deleteFile = FALSE))
    #       
    #     })
    # })

    observeEvent(input$raw_file_location, {

      path <<- paste(as.vector(unlist(input$raw_file_location$path))[-1], collapse = "/", sep="")
      message(path)
      output$location = renderPrint(path)

    })
    
    observeEvent(input$experimental_design, {

      df <<- read.csv(paste0(root2, paste(as.vector(unlist(input$experimental_design$files)), collapse = "/", sep="")),
                     header = TRUE,
                     sep = "\t",
                     quote = "")

      x=1:dim(df)[1]
      names(x)=df$Sample_Name
      updateTabsetPanel(session, "main_tabs", selected = "Selection")
      updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x)) # , selected = as.list(x)
      
      ###############################################################################################
      ####################### experimental design ###################################################
      ###############################################################################################
      file.remove(paste0(getwd(), "/output/init.RData"))

      sampleNames=as.vector(unlist(df$File_Name))
      groupNames=unique(as.vector(unlist(df$Sample_Name)))
      # groupNames=unique(unlist(lapply(strsplit(as.vector(unlist(tbl$Sample_Name)), ".", fixed = TRUE), function(x) x[1])))

      # nsampgrps = number of individual biological samples
      # nrepl = number of technical replicates per sample
      nsampgrps = length(sampleNames)/nrepl
      repl.pattern = NULL
      if (nrepl == 3){
        for (x in 1:nsampgrps) { repl.pattern <- c(repl.pattern, list(c(sampleNames[x*nrepl-2],sampleNames[x*nrepl-1],sampleNames[x*nrepl])))}
      } else if (nrepl == 5){
        for (x in 1:nsampgrps) { repl.pattern <- c(repl.pattern, list(c(sampleNames[x*nrepl-4],sampleNames[x*nrepl-3],sampleNames[x*nrepl-2],sampleNames[x*nrepl-1],sampleNames[x*nrepl])))}
      }
      
      names(repl.pattern) = groupNames
      
      save(repl.pattern, file=paste(getwd(), "output/init.RData", sep="/")) 
      ###############################################################################################
      ###############################################################################################
      ###############################################################################################
    })

    observeEvent(input$check_all, {
      x=1:dim(df)[1]
      names(x)=df$Sample_Name
      if (length(input$inCheckboxGroup)>0){
        updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x), selected = NULL)
      } else {
        updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x), selected = as.list(x))
      }
        output$contents = renderTable({  df[input$inCheckboxGroup,] })
    })
    
    observeEvent(input$inCheckboxGroup, {
      output$contents = renderTable({  df[input$inCheckboxGroup,] })
    })

    # observeEvent(input$plot_tics, {
    # 
    #   # path = "Z:/Metabolomics/Metabolomics Projects/Projects 2015/Research Metabolic/Project 2015_011_SinglePatients/RES_DBS_20180115_SPXI"
    # 
    #   if (is.null(path)){
    #     session$sendCustomMessage(type = "testmessage",
    #                               message = "Choose a file location first!")
    #   } else {
    # 
    #     dir.create("output", showWarnings = FALSE)
    #     dir.create("output/data", showWarnings = FALSE)
    # 
    #     # files = df[input$inCheckboxGroup,]
    #     # save(files, file="files.RData")
    # 
    #     outputDir = paste(getwd(), "output/data", sep="/")
    #     # message(outputDir)
    # 
    #     # write.table(files, file=paste(paste(getwd(), "output", sep="/"), "sampleNames.txt", sep="/"), quote = FALSE, sep="\t",row.names = FALSE)
    #     # df[input$inCheckboxGroup,]
    # 
    #     # write.table(df[input$inCheckboxGroup,], file=paste(paste(getwd(), "output", sep="/"), "sampleNames.txt", sep="/"), quote = FALSE, sep="\t",row.names = FALSE)
    #     # # files=paste(root, path, paste(as.vector(unlist(files[, 1])),"raw", sep="."), sep="/")
    #     files=paste(root, path, paste(as.vector(unlist(df[input$inCheckboxGroup, 1])),"raw", sep="."), sep="/")
    #     # output$samples = renderTable({ as.data.frame(files) })
    # 
    #     # unlink(paste(getwd(), "output/data", list.files(path = paste(getwd(), "output/data", sep="/")), sep="/"))
    #     # unlink(paste(getwd(), "output/TIC", list.files(path = paste(getwd(), "output/TIC", sep="/")), sep="/"))
    #     # 
    #     # # Conversie naar mzXML
    #     # for (i in 1:length(files)){
    #     #         #   # file = paste(files, collapse = " ")
    #     #   file = files[i]
    #     #   system("cmd.exe",
    #     #   input = paste(msconvert,  paste("\"", file, "\"", sep="" ), "-o", paste("\"", outputDir, "\"", sep="" ), "--mzXML"),
    #     #   ignore.stderr=FALSE)
    #     # }
    #     # 
    #     # plot TICS
    #     xmlfiles = list.files(paste(getwd(),"output/data", sep = "/"))
    #     outdir = paste(getwd(), "output/TIC", sep="/")
    #     dir.create(outdir, showWarnings = FALSE)
    #     
    #     for (i in 1:length(xmlfiles)) {
    #        rawCtrl = xcmsRaw(paste(getwd(),"output/data", xmlfiles[i], sep = "/"), profstep=0.01)
    #        if (class(rawCtrl) == "try-error") {
    #        message(paste("Bad file:", xmlfiles[i]))
    #        next
    #       }
    #       
    #       # extract sample name
    #       sample=unlist(strsplit(xmlfiles[i], ".",fixed = T))[1]
    #       CairoPNG(filename=paste(outdir, paste(sample, "png", sep="."), sep="/"), width, height)
    #          plotTIC(rawCtrl, ident=TRUE, msident=TRUE) # waits for mouse input; hit Esc
    #       dev.off()
    #     }
    #   
    #     # tics = list.files(paste(getwd(),"output/TIC", sep = "/"))
    #     # # output$files = tics
    #     # tics = paste(getwd(),"output/TIC", files, sep = "/")
    #     
    #     files = list.files(paste(getwd(),"output/TIC", sep = "/"))
    #     files_path = paste(getwd(),"output/TIC", files, sep = "/")
    #     
    #     output$images <- renderUI({
    #       if(is.null(files_path)) return(NULL)
    #       image_output_list <- 
    #         lapply(1:length(files_path),
    #                function(i)
    #                {
    #                  imagename = paste0("image", i)
    #                  imageOutput(imagename) # ,  click = clickOpts(id = imagename, clip = FALSE)
    #                })
    #       
    #       # print(image_output_list)
    #       do.call(tagList, image_output_list)
    #     })
    #     
    #     observe({
    #       if(is.null(files_path)) return(NULL)
    #       for (i in 1:length(files_path))
    #       {
    #         # print(i)
    #         local({
    #           my_i <- i
    #           imagename = paste0("image", my_i)
    #           # print(imagename)
    #           output[[imagename]] <- 
    #             renderImage({
    #               list(src = files_path[my_i],
    #                    alt = "Image failed to render")
    #             }, deleteFile = FALSE)
    #         })
    #       }
    #     })
    #     
    #     updateTabsetPanel(session, "main_tabs", selected = "TICs")
    # 
    #   }
    # })
    
    observeEvent(input$run, {
      
      # path = "Z:/Metabolomics/Metabolomics Projects/Projects 2015/Research Metabolic/Project 2015_011_SinglePatients/RES_DBS_20180115_SPXI"
      
      if (is.null(path)){
        session$sendCustomMessage(type = "testmessage",
                                  message = "Choose a file location first!")
      } else {
        
        dir.create("output", showWarnings = FALSE)
        dir.create("output/data", showWarnings = FALSE)
        outputDir = paste(getwd(), "output/data", sep="/")
        
        message(paste(paste(getwd(), "output", sep="/"), "sampleNames_out.txt", sep="/"))

        write.table(df[input$inCheckboxGroup,], file=paste(paste(getwd(), "output", sep="/"), "sampleNames_out.txt", sep="/"), quote = FALSE, sep="\t",row.names = FALSE)
        files=paste(root, path, paste(as.vector(unlist(df[input$inCheckboxGroup, 1])),"raw", sep="."), sep="/")
        
        message(files)
        
        output$samples = renderTable({ as.data.frame(files) })
        
        unlink(paste(getwd(), "output/data", list.files(path = paste(getwd(), "output/data", sep="/")), sep="/"))
        unlink(paste(getwd(), "output/TIC", list.files(path = paste(getwd(), "output/TIC", sep="/")), sep="/"))

        ###############################################################################################
        ####################### adjust replication pattern ############################################
        #################################################s##############################################
        # files = df[input$inCheckboxGroup,]
        # save(files, file="files.RData")
        # save(nsampgrps, repl.pattern, groupNames, sampleNames, file=paste(getwd(), "output/init.RData", sep="/"))
        # load("files.RData")

        selectedSamples = df[input$inCheckboxGroup,]
        save(selectedSamples, file="selectedSamples.RData")
        load(paste(getwd(), "output/init.RData", sep="/"))
        sampleNames = as.vector(unlist(repl.pattern))
        groupNames = names(repl.pattern)
        remove = which(sampleNames %in% selectedSamples$File_Name)
        rval = NULL
        if (length(remove)>0) rval = removeFromRepl.pat(sampleNames[-remove], repl.pattern, groupNames, nrepl)

        # nsampgrps=length(rval$pattern)
        repl.pattern=rval$pattern
        # groupNames=rval$groupNames
        # sampleNames=as.vector(unlist(selectedSamples$File_Name))
        
        message(paste(getwd(), "output/init.RData", sep="/"))
        
        save(repl.pattern, file=paste(getwd(), "output/init.RData", sep="/"))
        ###############################################################################################

        # Conversie naar mzXML ########################################################################
        for (i in 1:length(files)){

         # file = paste(files, collapse = " ")
         file = files[i]

         system("cmd.exe",
                 input = paste(msconvert,  paste("\"", file, "\"", sep="" ), "-o", paste("\"", outputDir, "\"", sep="" ), "--mzXML"),
                 ignore.stderr=FALSE)
        }
        ################################################################################################

        # Check samples with design
        samplesDesign = paste(print(as.vector(unlist(df[input$inCheckboxGroup, 1]))), "mzXML", sep=".")
        mzXML = list.files(path = paste(getwd(), "output/data", sep="/"), pattern = "mzXML")
        index = which(samplesDesign %in% mzXML)

        message(paste("Length selected:", length(samplesDesign)))
        message(paste("Length mzXML files:", length(mzXML)))
        message(paste("First name selcted:", samplesDesign[1]))
        message(paste("First file name:", mzXML[1]))
        message(paste("Length found:", length(index)))

        if (length(samplesDesign) != length(index)){
        # if (TRUE){
          session$sendCustomMessage(type = "testmessage",
                                    message = "Design and mzXML files differ!")
        } else {
          message("Gaan!")

          # create results dir ################################################
          script = paste0("#!/bin/bash\ncd ", dims_dir, "\nmkdir ./results")
          message(script)

          fileConn = file(paste(getwd(), "output/putty_cmds_1.txt", sep = "/"))
          writeLines(script, fileConn)
          close(fileConn)

          system("cmd.exe",
                 input = paste0(putty, paste(getwd(), "output/putty_cmds_1.txt", sep="/")),
                 ignore.stderr=FALSE)
          #####################################################################

          # copy init.RData ###################################################
          system("cmd.exe",
                 input = paste(pscp, paste(getwd(), "output/init.RData", sep="/"), paste(hpc_pipeline, "results", sep="/")),
                 ignore.stderr=FALSE)
          #####################################################################

          # copy data files ###################################################
          system("cmd.exe",
                 # input = paste(pscp, paste(getwd(), "output\\data", sep="\\"), hpc_pipeline),
                 input = paste(pscp, paste(getwd(), "output/data", sep="/"), hpc_pipeline),
                 ignore.stderr=FALSE)
          #####################################################################

          # # qsub -M your@email.address -m e ...
          #
          # # copy mail sh ####################################################
          # script = paste0("#!/bin/bash\nscanmode=$1\necho \"To do!\" | mail -s \"DIMS data processing in $scanmode scanmode has finished!\" -c ", mail_address)
          # message(script)
          #
          # fileConn = file(paste(getwd(), "output/mail.sh", sep = "/"))
          # writeLines(script, fileConn)
          # close(fileConn)
          #
          # system("cmd.exe",
          #        # input = paste(pscp, paste(getwd(), "output\\mail.sh", sep="\\"), paste(hpc_pipeline, "scripts", sep="/")),
          #        input = paste(pscp, paste(getwd(), "output/mail.sh", sep="/"), paste(hpc_pipeline, "scripts", sep="/")),
          #        ignore.stderr=FALSE)
          # ###################################################################

          # start pipeline ####################################################
          # script = paste0("#!/bin/bash\ncd ", dims_dir, "\nsh ./run_DIMS_pipeline_guixr.sh\nsleep 10s\nqstat -u ", user, "\nsleep 10s")
          script = paste0("#!/bin/bash\ncd ", dims_dir, "\nsh ./run.sh\nsleep 10s\nqstat -u ", user, "\nsleep 10s")
          message(script)

          fileConn = file(paste(getwd(), "output/putty_cmds_2.txt", sep = "/"))
          writeLines(script, fileConn)
          close(fileConn)

          system("cmd.exe",
                 input = paste0(putty, paste(getwd(), "output/putty_cmds_2.txt", sep="/")),
                 ignore.stderr=FALSE)
          #####################################################################

          updateTabsetPanel(session, "main_tabs", selected = "Exported files")

          #####################################################################
          # plot TICS
          xmlfiles = list.files(paste(getwd(),"output/data", sep = "/"))
          outdir = paste(getwd(), "output/TIC", sep="/")
          dir.create(outdir, showWarnings = FALSE)

          for (i in 1:length(xmlfiles)) {
            rawCtrl = xcmsRaw(paste(getwd(),"output/data", xmlfiles[i], sep = "/"), profstep=0.01)
            if (class(rawCtrl) == "try-error") {
              message(paste("Bad file:", xmlfiles[i]))
              next
            }

            # extract sample name
            sample=unlist(strsplit(xmlfiles[i], ".",fixed = T))[1]
            CairoPNG(filename=paste(outdir, paste(sample, "png", sep="."), sep="/"), width, height)
            plotTIC(rawCtrl, ident=TRUE, msident=TRUE) # waits for mouse input; hit Esc
            dev.off()
          }
          #####################################################################

          session$sendCustomMessage(type = "testmessage",
                                    message = "Samples will be processed @HPC cluster. This will take several hours! You will recieve an email when finished.")
        }
      }
    })
  })
}

shinyApp(ui, server)
