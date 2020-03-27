

dashboardPage(
  dashboardHeader(title = "DIMS Pipeline"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Step 1: Select Samples", tabName = "step1", icon = icon("vial")),
      menuItem("Step 2: Set Settings", tabName = "step2", icon = icon("sliders-h")),
      menuItem("Step 3: Set Advanced Settings", tabName = "step3", icon = icon("cogs")),
      menuItem("Step 4: Run Pipeline", tabName = "step4", icon = icon("upload"))
    )),
  dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "step1",
              fluidRow(
                column(12, 
                       fluidRow(column(12,
                                       fileInput("samplesheet", "1) Select sample sheet ...",
                                                 multiple = FALSE,
                                                 accept = c("text/csv",
                                                            "text/comma-separated-values,text/plain",
                                                            ".csv"))
                                       
                       )),
                       p(tags$b("2) Select folder containing .raw files ...")),
                       shinyDirButton("input_folder", "Browse...", "Select raw file location..."),
                       
                       br(), br(),
                       fluidRow(
                         column(12, p(tags$b("3) Select samples to be processed...")))
                       ),
                       
                       br(),
                       fluidRow(
                         column(4, uiOutput("select")),
                         column(8, textOutput('count'))
                       ),
                       
                       br(),
                       fluidRow(
                         column(12, DT::dataTableOutput('table'))
                       ),
                       br(),
                       br()
                )
              )
      ),
      
      # Second tab content
      tabItem(tabName = "step2",
              fluidRow( 
                column(12,
                       textInput("login", "HPC username", config$login),
                       passwordInput("password", "HPC password", ""),
                       textInput("email", "UMC e-mail", config$email),
                       textInput("run_name", "Run name (will be folder name on HPC)", config$run_name)
                )
              )
      ),
      tabItem(tabName = "step3",
              fluidRow(
                column(12,
                       selectInput("matrix", "Matrix", config$matrix),
                       numericInput("nrepl", "Technical replicates per sample", config$nrepl),
                       selectInput("resol", "Mass spec resolution", config$resol, selected = config$resol[[config$default_resol]]),
                       numericInput("trim", "Trim", config$trim),
                       #selectInput("normalization", "Normalization", config$normalization),
                       numericInput("dims_thresh", "Minimum intensity threshold per m/z", config$dims_thresh),
                       numericInput("thresh2remove", "Minimum total intensity per scan", config$thresh2remove[[1]]),
                       numericInput("thresh_pos", "Minimum intensity per positive peak", config$thresh_pos),
                       numericInput("thresh_neg", "Minimum intensity per negative peak", config$thresh_neg),
                       selectInput("z_score", "Calculate Z score", c("Yes" = 1, "No" = 0))
                )
              )
      ),
      tabItem(tabName = "step4",
              fluidRow(
                column(12, actionButton("check_button", label = "Check")),
                br(),br(),br(),
                column(1, textOutput("check1")),
                column(11, p(tags$b("Selected a samplesheet."))),
                br(),br(),
                column(1, textOutput("check2")),
                column(11, p(tags$b("Selected a data folder."))),
                br(),br(),
                column(1, textOutput("check3")),
                column(11, p(tags$b("All selected samples were found in the data folder."))),
                br(),br(),
                column(1, textOutput("check4")),
                column(11, p(tags$b("Every biological sample has the correct amount of technical replicates."))),
                br(),br(),
                column(1, textOutput("check5")),
                column(11, p(tags$b("All parameters have been filled in and selected."))),
                br(),br(),
                column(1, textOutput("check6")),
                column(11, p(tags$b("Can connect to the HPC submit node (and HPC credentials are correct)."))),
                br(),br(),
                column(1, textOutput("check7")),
                column(11, p(tags$b("Can connect to the HPC transfer node (and HPC credentials are correct)."))),
                br(),br(),
                column(1, textOutput("check8")),
                column(11, p(tags$b("There is no raw data folder with the specified run name yet."))),
                br(),br(),
                column(1, textOutput("check9")),
                column(11, p(tags$b("There is no processed folder with the specified run name yet."))),
                
                br(),br(),br(),
                uiOutput("run_button")
              )
      )
    )
  )
)