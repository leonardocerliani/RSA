#!/bin/bash

# Usage message function
usage() {
    echo
    echo "Usage: $0 results_dir mask_name nperms"
    echo "  results_dir : path, e.g., pwd/rsa_results/N14_test_mask_EER"
    echo "  mask_name   : any of the files inside /data00/leonardo/RSA/analyses/rsa/masks without the .nii.gz extension"
    echo "  nperms      : a number, typically between 1000-5000"
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
fslmerge -t emotion $(ls sub*emotion*)
fslmerge -t arousal $(ls sub*arousal*)

# FSL math operations
fslmaths emotion -sub arousal emotion_vs_arousal
fslmaths arousal -sub emotion arousal_vs_emotion

# Running randomise in background
nohup randomise -i arousal -o stats_arousal -m "${mask_path}" -1 -T -n "${nperms}" &
nohup randomise -i emotion -o stats_emotion -m "${mask_path}" -1 -T -n "${nperms}" &
nohup randomise -i arousal_vs_emotion -o stats_arousal_vs_emotion -m "${mask_path}" -1 -T -n "${nperms}" &
nohup randomise -i emotion_vs_arousal -o stats_emotion_vs_arousal -m "${mask_path}" -1 -T -n "${nperms}" &
