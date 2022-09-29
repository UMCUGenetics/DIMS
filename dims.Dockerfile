# FROM rocker/tidyverse:3.6.2
# FROM rocker/tidyverse:3.2.2


FROM rocker/tidyverse:4.1.0

FROM bioconductor/bioconductor_docker:RELEASE_3_14 
# v3.14


# RUN install2.r openxlsx reshape2 loder ggplot2 
# R:v4.1.0
RUN R -e 'BiocManager::install(c("xcms", "stringr", "dplyr", "Rcpp"))'
RUN R -e 'install.packages(c("devtools", "DT", "ssh", "shinyFiles", "shinydashboard", "shiny"))'
RUN R -e 'devtools::install_cran("openxlsx", version = "4.2.5")'
RUN R -e 'devtools::install_cran("reshape2", version = "1.4.4")'
RUN R -e 'devtools::install_cran("loder", version = "0.2.0")'
RUN R -e 'devtools::install_cran("ggplot2", version = "3.3.5")'



# RUN R -e 'devtools::install("stringr", version = "1.4.0")'
# RUN R -e 'devtools::install("dplyr", version = "1.0.8")'

