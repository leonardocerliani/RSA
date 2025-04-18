#!/bin/bash

sub=$(printf "%02d" $1)
export sub

export bd="/data00/leonardo/RSA/prep_data/sub-${sub}/fmri"
export dest="/data00/leonardo/RSA/prep_scripts/06_TSNR_calculation/tmp_results"

export FSLDIR="/data00/leonardo/warez/fsl"
export MNI="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"

# Function to calculate TSNR for a given run
calculate_tsnr() {
    local run=$1
    echo "Processing run-${run} for subject-${sub}"

    # Calculate mean, std, and TSNR
    fslmaths ${bd}/sub-${sub}_run-${run}_fmri_topup -Tmean ${dest}/mean_sub-${sub}_run-${run}
    fslmaths ${bd}/sub-${sub}_run-${run}_fmri_topup -Tstd ${dest}/std_sub-${sub}_run-${run}
    fslmaths ${dest}/mean_sub-${sub}_run-${run} -div ${dest}/std_sub-${sub}_run-${run} ${dest}/tsnr_sub-${sub}_run-${run}

    imrm ${dest}/mean_sub-${sub}_run-${run}
    imrm ${dest}/std_sub-${sub}_run-${run}

    # transform to MNI
    bd_reg=${bd}/sub-${sub}_run-${run}_preproc_reg.feat/reg

    applywarp \
        --ref=${MNI} \
        --in=${dest}/tsnr_sub-${sub}_run-${run} \
        --warp=${bd_reg}/highres2standard_warp \
        --premat=${bd_reg}/example_func2highres.mat \
        --out=${dest}/tsnr_sub-${sub}_run-${run}_MNI

}

export -f calculate_tsnr  # Export the function for parallel use

# Create an array of runs
runs=(1 2 3 4 5 6 7 8)

# Use xargs to process each run in parallel
printf "%s\n" "${runs[@]}" | xargs -n 1 -P 8 bash -c 'calculate_tsnr "$@"' _


# Now create one mean tsnr image per sub in MNI space
fslmerge -t ${dest}/4D_tsnr_sub-${sub} $(ls ${dest}/tsnr_sub-${sub}*MNI.nii.gz)
fslmaths ${dest}/4D_tsnr_sub-${sub}.nii.gz -Tmean ${dest}/mean_tsnr_sub-${sub}.nii.gz 
imrm ${dest}/tsnr_sub-${sub}*
imrm ${dest}/4D_tsnr_sub-${sub}.nii.gz


