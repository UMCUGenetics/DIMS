#!/bin/bash

Rscript --verbose ${@: -1}/R/generateBreaksFwhm.HPC.R "$@"
