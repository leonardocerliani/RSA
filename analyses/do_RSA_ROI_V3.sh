#!/bin/bash

# IMPORTANT! THIS VERSION RUNS RSA_VERSION >= 15!

root=/data00/leonardo/RSA/analyses
RSA_version="V15"

# Fixed parameters
remove_neutrals="YES"
minus_neutral="NO"
subs_set="N26"
RSA_on_residuals="FALSE"
filter_RDMs="FALSE"

# -------------------------------
# Check for mandatory argument
# -------------------------------
if [ $# -lt 1 ]; then
    echo
    echo "IMPORTANT! THIS VERSION RUNS RSA_VERSION >= 15!"
    echo
    echo "You are using RSA_version : ${RSA_version}"
    echo
    echo "Usage: $0 <atlas_filename.nii.gz>"
    echo
    echo "<atlas_filename> should be a file ending with .nii.gz and present in ${root}/ROIS_REPO"
    echo
    echo "Fixed parameters:"
    echo "Remove neutrals       : ${remove_neutrals}"
    echo "Minus neutral         : ${minus_neutral}"
    echo "Subject set           : ${subs_set}"
    echo "RSA on residuals      : ${RSA_on_residuals}"
    echo "Filter RDMs           : ${filter_RDMs}"
    echo
    echo "Example: $0 Yeo7.nii.gz"
    exit 1
fi

atlas_filename=$1

# Check that atlas file exists
if [[ ! $atlas_filename =~ \.nii\.gz$ ]] || [ ! -f "${root}/ROIS_REPO/$atlas_filename" ]; then
    echo "Error: $atlas_filename should be a file ending with .nii.gz and must be present in ${root}/ROIS_REPO."
    exit 1
fi

# -------------------------------
# Print configuration
# -------------------------------
echo
echo "Using RSA_version     : ${RSA_version}"
echo "Atlas file            : ${atlas_filename}"
echo "Remove neutrals       : ${remove_neutrals}"
echo "Minus neutral         : ${minus_neutral}"
echo "Subject set           : ${subs_set}"
echo "RSA on residuals      : ${RSA_on_residuals}"
echo "Filter RDMs           : ${filter_RDMs}"

# -------------------------------
# Run RMarkdown analysis
# -------------------------------
Rscript -e "rmarkdown::render(
    '$root/rsa_emotion_high_low_predictors_ROI/do_RSA_${RSA_version}_ROIs_EHLP.Rmd',
    params = list(
        atlas_filename = '$atlas_filename',
        remove_neutrals = '$remove_neutrals',
        minus_neutral = '$minus_neutral',
        subs_set = '$subs_set',
        RSA_on_residuals = '$RSA_on_residuals',
        filter_RDMs = '$filter_RDMs'
    ),
    quiet = TRUE
)" &
pid1=$!




# # Run the RMarkdown file for EHLP : using ratings RDMs _after_ regressing motion_energy
# Rscript -e "rmarkdown::render(
#     '$root/rsa_emotion_high_low_predictors_ROI/do_RSA_${RSA_version}_ROIs_EHLP_regress_motion_energy.Rmd',
#     params = list(
#         atlas_filename = '$atlas_filename',
#         remove_neutrals = '$remove_neutrals',
#         minus_neutral = '$minus_neutral',
#         subs_set = '$subs_set'
#     )
# )" &
# pid2=$!


# # Run the RMarkdown file for EHLP : using ratings RDMs _after_ regressing motion_energy SUBSAMP
# Rscript -e "rmarkdown::render(
#     '$root/rsa_emotion_high_low_predictors_ROI/do_RSA_${RSA_version}_ROIs_EHLP_regress_motion_energy_SUBSAMP.Rmd',
#     params = list(
#         atlas_filename = '$atlas_filename',
#         remove_neutrals = '$remove_neutrals',
#         minus_neutral = '$minus_neutral',
#         subs_set = '$subs_set'
#     )
# )" &
# pid3=$!




# Wait for background processes to finish
wait $pid1 $pid2 $pid3

# Remove the html's
rm ${root}/rsa_emotion_high_low_predictors_ROI/do_RSA_${RSA_version}_ROIs_EHLP.html


# echo -e "\nAll RMarkdown files have been processed."
