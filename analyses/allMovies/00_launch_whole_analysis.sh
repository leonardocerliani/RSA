#!/bin/bash

# run with
# nohup ./00_launch_whole_analysis.sh > nohup.out &

${model}="allMovies"

# build the .mat files for the 1st level analysis from the onset.csv files
Rscript 01_do_prepare_mat_${model}.R

# launch 1st level analysis with feat (~ 4hrs)
./02_launch_first_level_stats.sh

# run 2nd and group level analyses
./03_do_higher_levels.sh

#EOF
