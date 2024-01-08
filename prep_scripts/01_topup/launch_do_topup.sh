#!/bin/bash

sub_list=/data00/leonardo/RSA/sub_list.txt

nohup cat ${sub_list} | xargs -P 10 -I{} ./do_topup.sh {} &

#EOF
