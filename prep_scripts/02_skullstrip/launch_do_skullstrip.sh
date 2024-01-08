#!/bin/bash

# NB: skullstrip is carried out using antsBrainExtraction.
# In the do_skullstrip.sh we limited the number of cores to 1
# for each process, so we can run all subs (26) at once.
# With 1 core, it takes ± 90' to complete

sub_list=/data00/leonardo/RSA/sub_list.txt

nohup cat ${sub_list} | xargs -P 26 -I{} ./do_skullstrip.sh {} &

#EOF
