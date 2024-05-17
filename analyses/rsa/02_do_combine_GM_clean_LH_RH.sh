#!/bin/bash

# NB: this script is made to allow a certain flexibility in the naming
# of the input directories, which must be in any case in 
# /data00/leonardo/RSA/analyses/rsa/rsa_results/GM_clean

bd="/data00/leonardo/RSA/analyses/rsa/rsa_results/GM_clean"

# The original name is N[14/26]_GM_clean_[LH/RH]_EER, but the destination dir 
# can be anything
#
# Please manually edit the names below

# nsub is either N14 or N26
nsub="N14"

LH=${nsub}_GM_clean_LH_EER
RH=${nsub}_GM_clean_RH_EER
dest=${bd}/${nsub}_GM_clean_bilat

subs=$(ls ${bd}/${LH}/sub*emotion*.nii.gz | xargs -n1 basename | awk -F _ '{print $2}')

[ -d  ${dest} ] && rm -rf ${dest} 
mkdir ${dest}

# join LH and RH
for sub in ${subs}; do
    for rating in emotion arousal valence; do

        echo Merging LH RH in sub-${sub}_RSA_${rating} 

        fslmaths ${bd}/${LH}/sub_${sub}_RSA_${rating}.nii.gz \
         -add ${bd}/${RH}/sub_${sub}_RSA_${rating}.nii.gz \
         ${dest}/sub_${sub}_RSA_${rating}.nii.gz


    done
done

# merge also the mean images
for rating in emotion arousal valence; do

    fslmaths ${bd}/${LH}_${rating} \
        -add ${bd}/${RH}_${rating} \
        ${dest}_${rating}

done



