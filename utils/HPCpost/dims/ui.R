library(shinythemes)

fluidPage(
  theme = shinytheme("paper"),
  singleton(tags$head(tags$script(src = "message-handler.js"))), 
  #shinythemes::themeSelector(), 
  
  fluidRow(
    column(6, # left 
           titlePanel("DIMS pipeline"),
           
           br(), br(),
           fluidRow(
             column(8, p(tags$b("1) Choose raw file location..."))),
             column(4, shinyDirButton("raw_file_location", "Browse...", "1) Choose raw file location..."))
           ),
           
           br(), 
           fluidRow(
             column(8, p(tags$b("2) Upload experimental design..."))),
             column(4, shinyFilesButton("experimental_design", "Browse...", "2) Upload experimental design...", multiple=FALSE))
           ),
           
           br(),
           p(tags$b("4) Select parameters...")),
           
           fluidRow(
             column(6,  
                    textInput("email", label = "UMC Email", value = mail),
                    numericInput("nrepl", "Technical replicates", 3),
                    selectInput("normalization", "Normalization", list("none", "total_IS", "total_ident", "total")),
                    numericInput("trim", "Trim", 0.1),
                    numericInput("resol", "Resolution", 140000),
                    numericInput("dims_thresh", "Threshold DIMS", 100)
             ),
             column(6,
                    textInput("run_name", label = "Run Name", value = ""),
                    selectInput("data_type", "Data Type", list("Plasma", "Blood Spots", "Research")),
                    #selectInput("thresh2remove", "Threshold to remove", list("1e+09 (plasma)", "5e+08 (blood spots)", "1e+08 (research (Mia))")),
                    numericInput("thresh2remove", "Threshold Remove", 500000000),
                    numericInput("thresh_pos", "Threshold positive", 2000),
                    numericInput("thresh_neg", "Threshold negative", 2000)
             )
           ),
           fluidRow(
             column(8, p(tags$b("5) Start the pipeline..."))),
             column(4, actionButton("run", "Run", class = "btn-success")))
    ),
    column(6, # right
           br(),
           wellPanel(style = "overflow-y:scroll; max-height: 700px",
                     useShinyjs(),
                     fluidPage(
                       br(),   
                       fluidRow(
                         column(8, p(tags$b("3) Select samples to be processed..."))),
                         column(4, actionButton("check_all", "Select All"))
                       ),
                       
                       br(),
                       fluidRow(
                         column(4, checkboxGroupInput("inCheckboxGroup", tags$b("Sample Name"))),
                         column(8, tags$b("File Name"), br(), tableOutput("contents"))
                       )
                     )
           )
    )
  )
)