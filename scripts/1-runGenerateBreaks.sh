#!/bin/bash
echo $PWD

Rscript ${@: -1}/R/generateBreaksFwhm.HPC.R "$@"
