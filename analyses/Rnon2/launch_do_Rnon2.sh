#!/bin/bash

# launch with nohup ./launch_do_Rnon2.sh > output_do_Rnon2.log 2>&1 &

sub_list=/data00/leonardo/RSA/sub_list.txt

cat ${sub_list} | xargs -P 4 -I{} ./do_Rnon2.sh {}

