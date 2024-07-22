#!/bin/bash

rsa_flavour="rsa_emotion_predictors"

bd="/data00/leonardo/RSA/analyses/${rsa_flavour}/rsa_results"


# choose nsub : either N14 or N26
nsub="N26"

# The original name is N[14/26]_GM_clean_[LH/RH]_EER, but the destination dir 
# can be anything
#
# Please manually edit the names below

LH=${nsub}_GM_clean_LH_EER
RH=${nsub}_GM_clean_RH_EER
dest=${bd}/${nsub}_GM_clean_bilat
originals_storage=${bd}/single_hemispheres


# ----------- DO NOT MODIFY ANYTHING BELOW HERE -----------------

# Create - if not existing - the folders to store the bilat
# and the folder to store the single hemispheres
[ ! -d ${dest} ] && mkdir ${dest}
[ ! -d ${originals_storage} ] && mkdir ${originals_storage}


subs=$(ls ${bd}/${LH}/sub*emotion*.nii.gz | xargs -n1 basename | awk -F _ '{print $2}')


# join LH and RH
for sub in ${subs}; do
    for rating in emotion arousal valence aroval; do

        echo Merging LH RH in sub-${sub}_RSA_${rating} 

        fslmaths ${bd}/${LH}/sub_${sub}_RSA_${rating}.nii.gz \
            -add ${bd}/${RH}/sub_${sub}_RSA_${rating}.nii.gz \
            ${dest}/sub_${sub}_RSA_${rating}.nii.gz


    done
done

# merge also the mean images
for rating in emotion arousal valence aroval; do

    fslmaths ${bd}/${LH}_${rating} \
        -add ${bd}/${RH}_${rating} \
        ${dest}_${rating}

done

# move the original single-hemispheres dirs to the 
# storage directory
mv ${bd}/${LH}* ${originals_storage}
mv ${bd}/${RH}* ${originals_storage}



# EOF
