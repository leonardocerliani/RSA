#!/bin/bash

# Define the root directory
root=/data00/leonardo/RSA/analyses

# Function to display usage information
usage() {
    echo "Usage: $0 <atlas_filename.nii.gz> <remove_neutrals: YES/NO> <minus_neutral: YES/NO> <subs_set: N14/N26>"
    echo ""
    echo "<atlas_filename> should be a file ending with .nii.gz and present in $root/ROIS_REPO"
    echo "<remove_neutrals> should be either YES or NO"
    echo "<minus_neutral> should be either YES or NO"
    echo "<subs_set should be either N14 or N26>"
    echo
    echo e.g. ./do_RSA_ROI.sh Yeo7.nii.gz "YES" "NO" "N14"
    echo 
    exit 1
}

# If no parameters are provided, display usage information
if [ $# -eq 0 ]; then
    usage
fi

# Capture the parameters
atlas_filename=$1
remove_neutrals=$2
minus_neutral=$3
subs_set=$4

# Check that $1 ends with nii.gz and is present in ${root}/ROIS_REPO
if [[ ! $atlas_filename =~ \.nii\.gz$ ]] || [ ! -f "${root}/ROIS_REPO/$atlas_filename" ]; then
    echo "Error: $atlas_filename should be a file ending with .nii.gz and must be present in ${root}/ROIS_REPO."
    exit 1
fi

# Check that $2 and $3 are either YES or NO
if [[ "$remove_neutrals" != "YES" && "$remove_neutrals" != "NO" ]]; then
    echo "Error: $remove_neutrals should be either YES or NO."
    usage
fi

if [[ "$minus_neutral" != "YES" && "$minus_neutral" != "NO" ]]; then
    echo "Error: $minus_neutral should be either YES or NO."
    usage
fi

if [[ "$subs_set" != "N14" && "$subs_set" != "N26" ]]; then
    echo "Error: $subs_set should be either N14 or N26."
    usage
fi


# Run the RMarkdown files in parallel

# One ev per movie (48+8)
Rscript -e "rmarkdown::render(
    '$root/rsa_ROI/do_RSA_V13_ROIs_OEPM.Rmd',
    params = list(
        atlas_filename = '$atlas_filename',
        remove_neutrals = '$remove_neutrals',
        minus_neutral = '$minus_neutral',
        subs_set = '$subs_set'
    )
)" &
pid1=$!

# Emotion predictors (6+1)
Rscript -e "rmarkdown::render(
    '$root/rsa_emotion_predictors_ROI/do_RSA_V13_ROIs_EP.Rmd',
    params = list(
        atlas_filename = '$atlas_filename',
        remove_neutrals = '$remove_neutrals',
        minus_neutral = '$minus_neutral',
        subs_set = '$subs_set'
    )
)" &
pid2=$!

# Emotion high_low predictors (12+2)
Rscript -e "rmarkdown::render(
    '$root/rsa_emotion_high_low_predictors_ROI/do_RSA_V13_ROIs_EHLP.Rmd',
    params = list(
        atlas_filename = '$atlas_filename',
        remove_neutrals = '$remove_neutrals',
        minus_neutral = '$minus_neutral',
        subs_set = '$subs_set'
    )
)" &
pid3=$!


# Emotion high only (6+1)
Rscript -e "rmarkdown::render(
    '$root/rsa_emotion_high_predictors_ROI/do_RSA_V13_ROIs_EH.Rmd',
    params = list(
        atlas_filename = '$atlas_filename',
        remove_neutrals = '$remove_neutrals',
        minus_neutral = '$minus_neutral',
        subs_set = '$subs_set'
    )
)" &
pid4=$!




# Wait for all background processes to finish
wait $pid1 $pid2 $pid3

# Remove the html's
rm ${root}/rsa_ROI/do_RSA_V13_ROIs_OEPM.html
rm ${root}/rsa_emotion_predictors_ROI/do_RSA_V13_ROIs_EP.html
rm ${root}/rsa_emotion_high_low_predictors_ROI/do_RSA_V13_ROIs_EHLP.html


echo -e "\nAll RMarkdown files have been processed."
