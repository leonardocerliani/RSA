#!/bin/bash

# CROSSNOBIS VERSION - Uses leave-one-run-out Mahalanobis distance for fMRI RDMs
# Based on V15 but uses first-level run-wise copes instead of 2nd-level copes

root=/data00/leonardo/RSA/analyses
RSA_version="v15_CROSSNOBIS"

# Fixed parameters
remove_neutrals="YES"
minus_neutral="NO"
subs_set="N26"

# RSA_on_residuals and filter_RDMs will loop through all combinations

# -------------------------------
# Check for mandatory argument
# -------------------------------
if [ $# -lt 1 ]; then
    echo
    echo "CROSSNOBIS VERSION - Uses leave-one-run-out Mahalanobis distance"
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
    echo
    echo "AUTOMATIC PARAMETER SWEEP:"
    echo "  Will run 4 combinations of RSA_on_residuals (TRUE/FALSE) × filter_RDMs (TRUE/FALSE)"
    echo
    echo "IMPORTANT: This version processes 8 runs × 14 copes = 112 files per subject"
    echo "           Results will be saved with code 'EXR' (Euclidean-Crossnobis-Pearson)"
    echo "           Expected total time: ~9 hours for all 4 combinations"
    echo
    echo "Example: $0 test_ROI_crossnobis.nii.gz"
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
echo "=== CROSSNOBIS RSA ANALYSIS - PARAMETER SWEEP ==="
echo "Using RSA_version     : ${RSA_version}"
echo "Atlas file            : ${atlas_filename}"
echo "Remove neutrals       : ${remove_neutrals}"
echo "Minus neutral         : ${minus_neutral}"
echo "Subject set           : ${subs_set}"
echo
echo "Distance methods:"
echo "  Ratings RDM         : Euclidean (E)"
echo "  fMRI RDM            : Crossnobis (X)"
echo "  RSA correlation     : Pearson (R)"
echo
echo "Will run 4 parameter combinations:"
echo "  1. RSA_on_residuals=FALSE, filter_RDMs=FALSE"
echo "  2. RSA_on_residuals=FALSE, filter_RDMs=TRUE"
echo "  3. RSA_on_residuals=TRUE,  filter_RDMs=FALSE"
echo "  4. RSA_on_residuals=TRUE,  filter_RDMs=TRUE"
echo

# Track start time
start_time=$(date +%s)
combination=0

# -------------------------------
# Loop through all parameter combinations
# -------------------------------
for RSA_on_residuals in "FALSE" "TRUE"; do
  for filter_RDMs in "FALSE" "TRUE"; do
    
    combination=$((combination + 1))
    
    echo ""
    echo "============================================"
    echo "COMBINATION ${combination}/4"
    echo "RSA_on_residuals = ${RSA_on_residuals}"
    echo "filter_RDMs      = ${filter_RDMs}"
    echo "============================================"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    combo_start=$(date +%s)
    
    # Run RMarkdown analysis
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
    )"
    
    combo_end=$(date +%s)
    combo_elapsed=$((combo_end - combo_start))
    
    echo ""
    echo "✓ Combination ${combination}/4 completed in ${combo_elapsed} seconds ($(($combo_elapsed / 60)) minutes)"
    echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Remove the html
    rm ${root}/rsa_emotion_high_low_predictors_ROI/do_RSA_${RSA_version}_ROIs_EHLP.html 2>/dev/null
    
  done
done

# Calculate total time
end_time=$(date +%s)
total_elapsed=$((end_time - start_time))

echo ""
echo "============================================"
echo "ALL 4 COMBINATIONS COMPLETE!"
echo "============================================"
echo "Total time: ${total_elapsed} seconds ($(($total_elapsed / 60)) minutes, $(($total_elapsed / 3600)) hours)"
echo "Results saved to: ${root}/RSA_ROI_APP/results_RSA_ROI/"
echo ""
