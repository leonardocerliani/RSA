#!/bin/bash


###################################################################
#
#       NB: THIS SCRIPT IS OUTDATED.
#       THE STORAGE LOCATION IN /data01  IS NOW
#
#	/data01/7T_Emotion_Insula/Data_analysis/RSA/prep_data     
#
####################################################################





# launch with
# nohup cat sub_list.txt | xargs -P 8 -I{} ./do_storage_data01.sh {} &

# after copying, get a list of the orig dist to remove using e.g.
# find ./prep_data/ -type d -name allMovies

sub=$(printf "%02d" $1)

echo ${sub}

orig=/data00/leonardo/RSA/prep_data/sub-${sub}/fmri

dest=/data01/leonardo/RSA/prep_data/sub-${sub}/fmri

mkdir -p ${dest}

# put here a list of all the dirs you want to cp
for this_dir in emotion_high_low_predictors_minus_neutral; do

    time cp -r ${orig}/${this_dir}  ${dest}/${this_dir} 
    echo fatto ${sub} ${arousal}

done


