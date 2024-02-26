#!/bin/bash

# launch with
# for i in `cat /data00/leonardo/RSA/sub_list.txt`; do ./do_cp_onsets_files.sh ${i}; done

sub=$(printf "%02d" $1)

# initial copying of the onsets from cas directory
orig="/data00/CasfMRI/Master_logfiles/Master_log_allmovies"
dest_raw="/data00/leonardo/RSA/raw_data/sub-${sub}/onsets"

[ -d ${dest_raw} ] && rm -rf ${dest_raw}
mkdir ${dest_raw}
cp ${orig}/sub-${sub}*.csv ${dest_raw}/


# also prepare an onset dir in prep_data where the .mat and .con will go
dest_prep_data="/data00/leonardo/RSA/prep_data/sub-${sub}/fmri_EVs"
mkdir ${dest_prep_data}

#EOF
