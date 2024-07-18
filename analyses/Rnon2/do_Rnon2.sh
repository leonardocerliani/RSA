#!/bin/bash


# this expects a cat with sub_list.txt
sub=$(printf "%02d" $1)

# # just for testing on one subject
# sub="02"

python_path="/data00/leonardo/RSA/analyses/Rnon2/venv/bin/python"

MNI_2mm="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm.nii.gz"

source_drive="/data01"
source_bd="${source_drive}/leonardo/RSA/prep_data"

bd="/data00/leonardo/RSA/analyses/Rnon2"
dest_bd="${bd}/Rnon2_imgs"

[ ! -d ${dest_bd} ] && mkdir ${dest_bd}

# for model in allMovies emotion arousal valence; do
for model in allMovies emotion arousal valence; do

    [ ! -d ${dest_bd}/${model} ] && mkdir ${dest_bd}/${model}

    for run in $(seq 8); do

        # input
        Y=${source_bd}/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_preproc_reg.feat/filtered_func_data.nii.gz
        res=${source_bd}/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_preproc_reg.feat/stats/res4d.nii.gz
        mask=${source_bd}/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_preproc_reg.feat/mask.nii.gz
        
        # output
        CC_native_space=${dest_bd}/${model}/sub-${sub}_run-${run}_CC_native_space.nii.gz
        CC_MNI_space=${dest_bd}/${model}/sub-${sub}_run-${run}_CC_MNI.nii.gz

        echo ${Y} $(fslinfo ${Y} | grep ^dim4)
        echo ${res} $(fslinfo ${res} | grep ^dim4)
        echo ${mask} $(fslinfo ${mask} | grep ^dim4)
        echo

        # launch python script
        ${python_path} create_Rnon2_single_sub_V2.py ${source_bd} ${dest_bd} ${model} ${sub} ${run}

        # Bring in MNI space
        # NB: the --premat should *not* be used (check the Feat logs)
        regdir=${source_bd}/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_preproc_reg.feat/reg
        applywarp --ref=${MNI_2mm} \
                  --in=${CC_native_space} \
                  --warp=${regdir}/example_func2standard_warp.nii.gz \
                  --out=${CC_MNI_space}

    done

    # take the average of the 8 files in MNI:
    fslmerge -t \
        ${dest_bd}/${model}/sub-${sub}_${model}_MNI_allruns.nii.gz \
        $(ls ${dest_bd}/${model}/sub-${sub}*MNI.nii.gz)
    
    fslmaths ${dest_bd}/${model}/sub-${sub}_${model}_MNI_allruns.nii.gz -Tmean \
             ${dest_bd}/${model}/sub-${sub}_${model}_MNI_avg.nii.gz

    # delete temporary files
    rm ${dest_bd}/${model}/sub-${sub}_run*
done




