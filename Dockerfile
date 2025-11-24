# R:v4.1.0

# parent image tidyverse (v4.1.0), uses rocker/rstudio, which uses rocker/r-ver
FROM --platform=linux/amd64 bioconductor/bioconductor_docker:RELEASE_3_21

# Metadata
LABEL DIMS_VERSION=1.4
LABEL DESCRIPTION="This container provides R and R packages for running the DIMS pipeline with gridExtra."
LABEL GITHUB_REPOSITORY="https://github.com/UMCUGenetics/DIMS"
LABEL STATUS="ACTIVE"
LABEL CREATION_DATE="2023-05-04"
LABEL BASE_IMAGE="rocker/tidyverse:4.5.1"
LABEL EXTRA_PACKAGES="argparse, dplyr, ggplot2, gridExtra, openxlsx, Rcpp, reshape2, R.utils, stringr, xcms"

# install bioconductor packages; their versions according to bioconductor version (v3.14)
RUN R -e "BiocManager::install('xcms')"

# install devtools in order to install specific versions of packages
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/remotes/remotes_2.4.2.tar.gz', repos = NULL, type = 'source'); \
    remotes::install_version('argparse', '2.2.5'); \
    remotes::install_version('devtools', '2.4.5'); \
    remotes::install_version('dplyr', '1.1.4'); \
    remotes::install_version('ggplot2', '3.5.2'); \
    remotes::install_version('gridExtra', '2.3'); \
    remotes::install_version('openxlsx', '4.2.8'); \
    remotes::install_version('Rcpp', '1.1.0'); \
    remotes::install_version('reshape2', '1.4.4'); \
    remotes::install_version('R.utils', '2.13.0'); \
    remotes::install_version('stringr', '1.5.1')"
