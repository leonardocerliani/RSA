#!/bin/bash

# launch with nohup ... &

# Preprocessing of fmri data + registration to the T1w_brain
# and to MNI152_T1_2mm_brain (nonlinear)

# NB: for each sub, the 8 runs are run in parallel inside
# do_preproc_reg_parallel.sh
# Therefore we run only 4 subs at a time (4x8=32 processes)
# in order not to overwhelm the server,

sub_list=/data00/leonardo/RSA/sub_list.txt

cat ${sub_list} | xargs -P 4 -I{} ./do_preproc_reg_parallel.sh {}

#EOF
