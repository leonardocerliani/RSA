#!/bin/bash

# launch with nohup ... &

# first-level feat - i.e. single sub each run

# NB: for each sub, the 8 runs are run in parallel inside
# Therefore we run only 4 subs at a time (4x8=32 processes)
# in order not to overwhelm the server,

sub_list=/data00/leonardo/RSA/sub_list.txt

cat ${sub_list} | xargs -P 4 -I{} ./do_first_level_stats.sh {}

#EOF
