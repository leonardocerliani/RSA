#!/bin/bash

Nperms=5000

for subs_set in N14 N26; do
    
    for gm_mask in GM_clean HO_subcortical insula_HO_GM; do

        results_dir=${subs_set}_${gm_mask}_EER

        if [ -d rsa_results/${results_dir} ]; then

            nohup ./do_randomise_simple.sh ${results_dir}  ${gm_mask} ${Nperms} > \
                randomise_${results_dir} &

        fi

    done
done 

