#!/bin/bash

sub_list=/data00/leonardo/RSA/sub_list.txt

nohup cat ${sub_list} | xargs -P 7 -I{} ./do_reorient2std.sh {} &

#EOF
