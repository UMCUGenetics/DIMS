ui <- shinyUI(fluidPage(
  titlePanel("Uploading Files"),
  # uiOutput('images')
  sidebarLayout(
    sidebarPanel(
      fileInput(inputId = 'files',
                label = 'Select an Image',
                multiple = TRUE,
                accept=c('image/png', 'image/jpeg'))
    ),
    mainPanel(
      # tableOutput('files'),
      uiOutput('images')
    )
  )
))

server <- shinyServer(function(input, output) {
  # output$files <- renderTable(input$files)
  
  files = list.files(paste(getwd(),"output/TIC", sep = "/"))
  files_path = paste(getwd(),"output/TIC", files, sep = "/")

  # files <- reactive({
  #   files <- input$files
  #   files$datapath <- gsub("\\\\", "/", files$datapath)
  #   files
  # })
  
  output$images <- renderUI({
    if(is.null(files_path)) return(NULL)
    image_output_list <- 
      lapply(1:length(files_path),
             function(i)
             {
               imagename = paste0("image", i)
               imageOutput(imagename)
             })
    
    do.call(tagList, image_output_list)
  })
  
  observe({
    if(is.null(files_path)) return(NULL)
    for (i in 1:length(files_path))
    {
      print(i)
      local({
        my_i <- i
        imagename = paste0("image", my_i)
        print(imagename)
        output[[imagename]] <- 
          renderImage({
            list(src = files_path[my_i],
                 alt = "Image failed to render")
          }, deleteFile = FALSE)
      })
    }
  })
  
  
  
  # output$images <- renderUI({
  #   if(is.null(input$files)) return(NULL)
  #   image_output_list <- 
  #     lapply(1:nrow(files()),
  #            function(i)
  #            {
  #              imagename = paste0("image", i)
  #              imageOutput(imagename)
  #            })
  #   
  #   do.call(tagList, image_output_list)
  # })
  # 
  # observe({
  #   if(is.null(input$files)) return(NULL)
  #   for (i in 1:nrow(files()))
  #   {
  #     print(i)
  #     local({
  #       my_i <- i
  #       imagename = paste0("image", my_i)
  #       print(imagename)
  #       output[[imagename]] <- 
  #         renderImage({
  #           list(src = files()$datapath[my_i],
  #                alt = "Image failed to render")
  #         }, deleteFile = FALSE)
  #     })
  #   }
  # })
  
})

shinyApp(ui, server)


