#!/bin/bash

sub_list=/data00/leonardo/RSA/sub_list.txt

cat ${sub_list} | xargs -P 6 -I{} ./do_TSNR.sh {}

#EOF