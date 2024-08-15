#!/bin/bash

# launch with :
# nohup ./00_launch_whole_analysis.sh > nohup_one_ev_per_movie_minus_neutral.out &

model="one_ev_per_movie_minus_neutral"

# build the .mat files for the 1st level analysis from the onset.csv files
Rscript 01_do_prepare_mat_${model}.R


# first-level feat - i.e. single sub each run (~ 4 hrs)

# NB: for each sub, the 8 runs are run in parallel inside
# Therefore we run only 4 subs at a time (4x8=32 processes)
# in order not to overwhelm the server


# # ------------ TESTING ------------------------------------------
# mini_sub_list=/data00/leonardo/RSA/mini_sub_list.txt
# cat ${mini_sub_list} | xargs -P 4 -I{} ./02_do_first_level_stats.sh {}



# ------------ REAL DEAL ----------------------------------------
sub_list=/data00/leonardo/RSA/sub_list.txt
cat ${sub_list} | xargs -P 3 -I{} ./02_do_first_level_stats.sh {}


# # run 2nd level analyses
# ./03_do_second_level.sh

# # run group-level analyses
# ./04_do_group_level.sh



#EOF
