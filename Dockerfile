# R:v4.1.0

# parent image tidyverse (v4.1.0), uses rocker/rstudio, which uses rocker/r-ver
FROM bioconductor/bioconductor_docker:RELEASE_3_14

# metadata
LABEL DIMS_VERSION=1.1
LABEL DESCRIPTION="This container provides R and R packages for running the DIMS pipeline with gridExtra."
LABEL GITHUB_REPOSITORY="https://github.com/UMCUGenetics/DIMS"
LABEL STATUS="ACTIVE"
LABEL CREATION_DATE="2023-05-04"
LABEL BASE_IMAGE="rocker/tidyverse:4.1.0"
LABEL EXTRA_PACKAGES="xcms, stringr, dplyr, Rcpp, openxlsx, reshape2, loder, ggplot2, gridExtra"

# install bioconductor packages; their versions according to bioconductor version (v3.14)
RUN R -e 'BiocManager::install(c("Rcpp", "xcms", "stringr", "dplyr"))'
# install devtools in order to install specific versions of packages
RUN R -e 'install.packages(c("devtools"))'
RUN R -e 'devtools::install_cran("openxlsx", version = "4.2.5")'
RUN R -e 'devtools::install_cran("reshape2", version = "1.4.4")'
RUN R -e 'devtools::install_cran("loder", version = "0.2.0")'
RUN R -e 'devtools::install_cran("ggplot2", version = "3.3.5")'
RUN R -e 'devtools::install_cran("gridExtra", version = "2.2.1")'
