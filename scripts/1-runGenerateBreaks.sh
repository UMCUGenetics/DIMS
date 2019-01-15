#!/bin/bash
echo "pwd"
echo $PWD

Rscript ${@: -1}/R/generateBreaksFwhm.HPC.R "$@"
