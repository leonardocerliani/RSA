#!/bin/bash

#   Processes an atlas NIfTI image by extracting regions that 
#   overlap with a specified root region (Yeo7_VA_ROI4.nii.gz). 
#   It then identifies unique region values, extracts them as separate images, 
#   and generates a sorted list of these values.
#
#   Usage: do_filter_subregions.sh <yeo7_region> <atlas_filename (without .nii.gz)>
#   Example: do_filter_subregions.sh Yeo7_VA_ROI4.nii.gz Yeo17

# Ensure the script is called with two arguments
if [ $# -lt 2 ]; then
    echo 
    echo "Error: Two arguments required"
    echo "Usage: $0 <yeo7_region> <atlas_filename (without .nii.gz)>"   
    echo
    exit 1
fi

# Assign command-line arguments
yeo7_region="$1"

# Ensure the root region file exists
if [ ! -f "$yeo7_region" ]; then
    echo "Error: Root region file '$yeo7_region' not found!"
    exit 1
fi

# Remove .nii.gz extension from the atlas filename if provided
atlas=${2%.nii.gz}

# Check if the atlas file exists
if [ ! -f "${atlas}.nii.gz" ]; then
    echo "Error: File '${atlas}.nii.gz' not found!"
    exit 1
fi



bd_results=${PWD}/${atlas}_in_Yeo7_region

# create output directory if it does not exist
[ ! -d ${bd_results} ] && mkdir ${bd_results}

# ensure that root region is binary
fslmaths $yeo7_region -bin $yeo7_region

# atlas in root region
fslmaths $atlas -mul $yeo7_region ${atlas}_in_Yeo7_region.nii.gz

# transform the image to ascii and read what are the unique nonzero values
fsl2ascii ${atlas}_in_Yeo7_region.nii.gz tmp

# extract all the subregions of the atlas in the root region, and binarize them
for i in $(cat tmp00000 | tr ' ' '\n' | grep -v '^0$' | sort | uniq); do

    echo ${i} >> ${bd_results}/list_${atlas}_in_Yeo7_region.txt
    fslmaths ${atlas}_in_Yeo7_region.nii.gz \
        -thr ${i} -uthr ${i} \
        -bin \
        ${bd_results}/${atlas}_${i}.nii.gz

done

# sort in ascending order
sort -n ${bd_results}/list_${atlas}_in_Yeo7_region.txt -o ${bd_results}/list_${atlas}_in_Yeo7_region.txt

# housekeeping
rm tmp00000
rm ${atlas}_in_Yeo7_region.nii.gz

#EOF