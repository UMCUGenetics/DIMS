library("shiny")
library("shinyFiles")
library("xcms")
library("Cairo")

# ################################## user settings ####################################################################
# mail_address = "\"a.m.willemsen-8@umcutrecht.nl\""
# msconvert = "\"C:/Program Files/ProteoWizard/ProteoWizard 3.0.10738/msconvert.exe\""
# pscp = "\"C:/Program Files (x86)/Putty/pscp.exe\" -pw ***REMOVED*** -r -p "
# putty = "\"C:/Program Files (x86)/Putty/putty.exe\" -ssh mwillemsen@hpcsubmit.op.umcutrecht.nl -pw ***REMOVED*** -m "
# hpc_pipeline = "mwillemsen@hpct02.op.umcutrecht.nl:/hpc/shared/dbg_mz/marcel/Direct-Infusion-Pipeline_2.1"
# #root = "Z:/Metabolomics"
# root = "E:/Metabolomics/DIMS_interface"
# #####################################################################################################################

################################## user settings ####################################################################
mail_address = "\"a.m.willemsen-8@umcutrecht.nl\""
msconvert = "\"C:/Program Files/ProteoWizard/ProteoWizard 3.0.11748/msconvert.exe\""
pscp = "\"C:/Program Files/PuTTY/PSCP/pscp.exe\" -pw ***REMOVED*** -r -p "
putty = "\"C:/Program Files/PuTTY/putty.exe\" -ssh mwillemsen@hpcsubmit.op.umcutrecht.nl -pw ***REMOVED*** -m "
hpc_pipeline = "mwillemsen@hpct02.op.umcutrecht.nl:/hpc/shared/dbg_mz/marcel/DIMSinDiagnostics"
# \\ds.umcutrecht.nl\data\BG\metab
root = "Z:/Metabolomics/Metabolomics Projects/Projects 2015/Research Metabolic/Project 2015_011_SinglePatients"
#####################################################################################################################

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
        
        # p(tags$b("4) Plot TICs")),
        # actionButton("plot_tics", "Plot"),
        # tags$br(),tags$br(),

        p(tags$b("4) Run")),
        actionButton("run", "Run")
        
      ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      tabsetPanel(id ="main_tabs", type = "tabs",
        tabPanel("Selection", fluidPage(tags$br(),
                        verbatimTextOutput("location"),
                        tags$br(),
                           
                        fluidRow(
                          column(6, p(tags$b("3) Select samples to be processed..."))),
                          column(3, actionButton("check_all", "Select all"))
                        ),
                        tags$br(),
                        fluidRow(
                          column(3, checkboxGroupInput("inCheckboxGroup", "")),
                          column(6, tableOutput("contents"))
                        )
              )),
        # tabPanel("TICs", fluidPage(tags$br(),
        #                 fluidRow(
        #                   column(6, p(tags$b("4) Select bad TICs...")))#,
        #                   # column(3, actionButton("check_all", "Select all"))
        #                 ),
        #                 tags$br(),
        #                 fluidRow(
        #                   # column(3, checkboxGroupInput("inCheckboxGroup2", "")),
        #                   column(6, tags$div(id = "tic"))
        #                 )
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
    shinyFileChoose(input, "experimental_design", roots = c(home=root))

    observeEvent(input$raw_file_location, {

      path <<- paste(as.vector(unlist(input$raw_file_location$path))[-1], collapse = "/", sep="")
      message(path)
      output$location = renderPrint(path)

    })
    
    observeEvent(input$experimental_design, {

      df <<- read.csv(paste0(root, paste(as.vector(unlist(input$experimental_design$files)), collapse = "/", sep="")),
                     header = TRUE,
                     sep = "\t",
                     quote = "")

      x=1:dim(df)[1]
      names(x)=df$Sample_Name
      updateTabsetPanel(session, "main_tabs", selected = "Selection")
      updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x)) # , selected = as.list(x)
    })

    observeEvent(input$check_all, {
      x=1:dim(df)[1]
      names(x)=df$Sample_Name
      updateCheckboxGroupInput(session, inputId = "inCheckboxGroup", choices = as.list(x), selected = as.list(x))
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
    #     unlink(paste(getwd(), "output/data", list.files(path = paste(getwd(), "output/data", sep="/")), sep="/"))
    #     unlink(paste(getwd(), "output/TIC", list.files(path = paste(getwd(), "output/TIC", sep="/")), sep="/"))
    #     
    #     # Conversie naar mzXML
    #     for (i in 1:length(files)){
    # 
    #       # file = paste(files, collapse = " ")
    #       file = files[i]
    # 
    #       system("cmd.exe",
    #              input = paste(msconvert,  paste("\"", file, "\"", sep="" ), "-o", paste("\"", outputDir, "\"", sep="" ), "--mzXML"),
    #              ignore.stderr=FALSE)
    #     }
    #     
    #     # plot TICS
    #     xmlfiles = list.files(paste(getwd(),"output/data", sep = "/"))
    #     outdir = paste(getwd(), "output/TIC", sep="/")
    #     dir.create(outdir, showWarnings = FALSE)
    #     
    #     for (i in 1:length(xmlfiles)) {
    #       rawCtrl = xcmsRaw(paste(getwd(),"output/data", xmlfiles[i], sep = "/"), profstep=0.01)
    #       
    #       if (class(rawCtrl) == "try-error") {
    #         message(paste("Bad file:", xmlfiles[i]))
    #         next
    #       }
    #       
    #       # extract sample name
    #       sample=unlist(strsplit(xmlfiles[i], ".",fixed = T))[1]
    # 
    #       CairoPNG(filename=paste(outdir, paste(sample, "png", sep="."), sep="/"), width, height)
    #         plotTIC(rawCtrl, ident=TRUE, msident=TRUE) # waits for mouse input; hit Esc
    #       dev.off()
    #       
    #     }
    #     
    #     tics = list.files(paste(getwd(),"output/TIC", sep = "/"))
    #     
    #     for (i in 1:length(tics)){
    #       id = paste0("png", i)
    #       
    #       message(paste("=======>>>>>>", paste0(getwd(),"/output/TIC/", tics[i])))
    #       message(paste("=======>>>>>>", id))
    #       
    #       insertUI(
    #         selector = "#tic",
    #         
    #         ## wrap element in a div with id for ease of removal
    #         ui = tags$div(
    #           renderImage({
    #             return(list(
    #               src = paste0(getwd(),"/output/TIC/", tics[i]),
    #               contentType = "image/png",
    #               alt = "Face"
    #             ))
    #           }, deleteFile = FALSE), 
    #           id = id
    #         )
    #       )
    #     }  
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
        
        # files = df[input$inCheckboxGroup,]
        # save(files, file="files.RData")
        
        outputDir = paste(getwd(), "output/data", sep="/")

        write.table(df[input$inCheckboxGroup,], file=paste(paste(getwd(), "output", sep="/"), "sampleNames.txt", sep="/"), quote = FALSE, sep="\t",row.names = FALSE)
        files=paste(root, path, paste(as.vector(unlist(df[input$inCheckboxGroup, 1])),"raw", sep="."), sep="/")
        output$samples = renderTable({ as.data.frame(files) })
        
        unlink(paste(getwd(), "output/data", list.files(path = paste(getwd(), "output/data", sep="/")), sep="/"))
        unlink(paste(getwd(), "output/TIC", list.files(path = paste(getwd(), "output/TIC", sep="/")), sep="/"))
        
#################################################################################################################################################
        # #  unlink(paste(getwd(), "output/data", list.files(path = paste(getwd(), "output/data", sep="/")), sep="/"))
        # xml = list.files(path = paste(getwd(), "output/data", sep="/"))
        # 
        # # delete mzXML files not selected!
        # for (i in 1:length(xml)){
        #   message(file[i])
        #   message(xml[i])
        # }
#################################################################################################################################################

        # Conversie naar mzXML
        for (i in 1:length(files)){
          
          # file = paste(files, collapse = " ")
          file = files[i]
          
          system("cmd.exe",
                 input = paste(msconvert,  paste("\"", file, "\"", sep="" ), "-o", paste("\"", outputDir, "\"", sep="" ), "--mzXML"),
                 ignore.stderr=FALSE)
        }

        session$sendCustomMessage(type = "testmessage",
                                  message = "Samples will be exported to HPC cluster and processed. This will take several hours! You will recieve an email when finished.")

        # Check samples with design
        samplesDesign = paste(print(as.vector(unlist(df[input$inCheckboxGroup, 1]))), "mzXML", sep=".")
        mzXML = list.files(path = paste(getwd(), "output/data", sep="/"), pattern = "mzXML")
        index = which(samplesDesign %in% mzXML)

        message(length(samplesDesign))
        message(length(mzXML))
        message(samplesDesign[1])
        message(mzXML[1])
        message(length(index))

        if (length(samplesDesign) != length(index)){
          session$sendCustomMessage(type = "testmessage",
                                    message = "Design and mzXML files differ!")
        } else {
          message("Gaan!")

          system("cmd.exe",
                 input = paste(pscp, paste(getwd(), "output\\sampleNames.txt", sep="\\"), hpc_pipeline),
                 ignore.stderr=FALSE)

          system("cmd.exe",
                 input = paste(pscp, paste(getwd(), "output\\data", sep="\\"), hpc_pipeline),
                 ignore.stderr=FALSE)

          script = paste("#!/bin/bash
scanmode=$1
echo \"To do!\" | mail -s \">>>> DIMS data processing @HPC in $scanmode scanmode has finished! <<<<\"", mail_address, "\necho \"email send\"")
          message(script)

          fileConn = file(paste(getwd(), "output/mail.sh", sep = "/"))
          writeLines(script, fileConn)
          close(fileConn)

          system("cmd.exe",
                 input = paste(pscp, paste(getwd(), "output\\mail.sh", sep="\\"), paste(hpc_pipeline, "scripts", sep="/")),
                 ignore.stderr=FALSE)

          system("cmd.exe",
                 input = paste0(putty, paste(getwd(), "putty_cmds.txt", sep="/")),
                 ignore.stderr=FALSE)

          updateTabsetPanel(session, "main_tabs", selected = "Exported files")

       }
      }
    })
  })
}

shinyApp(ui, server)
