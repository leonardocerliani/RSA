#!/bin/bash

sub_list=/data00/leonardo/RSA/sub_list.txt

cat ${sub_list} | xargs -P 26 -I{} ./do_reorient2std.sh {}

#EOF
