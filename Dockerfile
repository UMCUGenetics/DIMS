
# R:v4.1.0

# parent image tidyverse (v4.1.0), uses rocker/rstudio, which uses rocker/r-ver
FROM rocker/tidyverse:4.1.0

FROM bioconductor/bioconductor_docker:RELEASE_3_14 

# metadata
LABEL DIMS_R_PACK_VERSION=1.0
LABEL STATUS="ACTIVE"
LABEL DESCRIPTION="This container provides R and R packages for running the DIMS pipeline."
LABEL GITHUB_REPOSITORY="https://github.com/UMCUGenetics/DIMS"

# install bioconductor packages; their versions according to bioconductor version (v3.14)
RUN R -e 'BiocManager::install(c("xcms", "stringr", "dplyr", "Rcpp"))'
# install devtools in order to install specific versions of packages
RUN R -e 'install.packages(c("devtools"))'
RUN R -e 'devtools::install_cran("openxlsx", version = "4.2.5")'
RUN R -e 'devtools::install_cran("reshape2", version = "1.4.4")'
RUN R -e 'devtools::install_cran("loder", version = "0.2.0")'
RUN R -e 'devtools::install_cran("ggplot2", version = "3.3.5")'

