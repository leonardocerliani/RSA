#!/bin/bash

# Usage message function
usage() {
    echo
    echo "Usage: $0 results_dir mask_name nperms"
    echo "  results_dir : path, e.g., pwd/rsa_results/N14_GM_clean_bilat"
    echo "  mask_name   : any of the files inside /data00/leonardo/RSA/analyses/rsa/masks without the .nii.gz extension"
    echo "  nperms      : a number, typically between 1000-5000"
    echo
    echo "Example: ./03_do_randomise____EMOTION__SPECIAL.sh N14_GM_clean_bilat GM_clean 5000"
    echo
    exit 1
}

# Check if correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo
    echo "Error: Incorrect number of arguments."
    usage
fi

# Input arguments
results_dir=$1
mask_name=$2
nperms=$3


# Define the paths
results_path="rsa_results/${results_dir}"
mask_path="/data00/leonardo/RSA/analyses/rsa/masks/${mask_name}.nii.gz"

# Copy the model files (.mat and .con) to the results_dir 
# to be able to use them in randomise
nsubs=$(echo ${results_dir} | awk -F_ '{print $1}')
mat_file=${nsubs}_covariates.mat
con_file=${nsubs}_covariates.con
cp randomise_models/${mat_file} ${results_path}/
cp randomise_models/${con_file} ${results_path}/

echo ${mat_file}
echo ${con_file}


# Check if results directory exists
if [ ! -d "${results_path}" ]; then
    echo
    echo "Error: Results directory '${results_path}' does not exist."
    usage
fi

# Check if mask file exists
if [ ! -f "${mask_path}" ]; then
    echo
    echo "Error: Mask file '${mask_path}' does not exist."
    usage
fi

# Check if nperms is a number
if ! [[ "${nperms}" =~ ^[0-9]+$ ]]; then
    echo
    echo "Error: The number of permutations 'nperms' is not a valid number."
    usage
fi





# Change to the results directory
cd "${results_path}"

# FSL merge operations
fslmerge -t Emotion $(ls sub*emotion.nii.gz)
fslmerge -t Emotion_MEDIAN $(ls sub*emotion_MEDIAN.nii.gz)
fslmerge -t Emotion_RUNE $(ls sub*emotion_RUNE.nii.gz)
fslmerge -t Emotion_IDEAL $(ls sub*emotion_IDEAL.nii.gz)



# Running randomise in background
# NB: template syntax for 1 sample t-test with no confounds:
# nohup randomise -i arousal -o stats_arousal -m "${mask_path}" -1 -T -n "${nperms}" &

# Running randomise with covariates in background
for contrast in \
    Emotion  Emotion_MEDIAN  Emotion_RUNE  Emotion_IDEAL; do

    # with variance smoothing and covariates
    nohup randomise -i ${contrast} -o stats_${contrast} -d ${mat_file} -t ${con_file} -m ${mask_path} -n ${nperms} -v 5 -T &
    
    # # NO COVARIATES
    # nohup randomise -i ${contrast} -o stats_${contrast} -m ${mask_path} -n ${nperms} -v 5 -1 -T &

done



