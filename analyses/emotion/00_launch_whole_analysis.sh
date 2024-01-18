#!/bin/bash

${model} = "emotion"

# build the .mat files for the 1st level analysis from the onset.csv files
Rscript 01_do_prepare_mat_${model}.R

# launch 1st level analysis with feat (~ 4hrs)
nohup ./02_launch_first_level_stats.sh > nohup_${model}.out &

# run 2nd and group level analyses
./03_do_higher_levels_modified_for_emotions.sh

#EOF