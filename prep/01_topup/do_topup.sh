#!/bin/bash

sub=$(printf "%02d" $1)

orig="/data00/leonardo/RSA/raw_data/sub-${sub}"
dest="/data00/leonardo/RSA/prep_data/sub-${sub}"

# If the dest dir exists, remove it and create a new one
[ -d "$dest" ] && rm -rf "$dest"
mkdir -p ${dest}/fmri

# Use only the first volume of both fmap and fmri to speed up the process

nruns=8

# NB both fmri and func are sent to the fmri destination dir
# since in the end we need them both in the same dir to do topup
# and we will not need the fmap anymore afterwards
for run in $(seq ${nruns}); do

  # fmap
  fslroi \
    ${orig}/fmap/sub-${sub}_run-${run}_fmap \
    ${dest}/fmri/sub-${sub}_run-${run}_fmap \
    0 1

  echo extracted vol 1 from ${orig}/fmap/sub-${sub}_run-${run}_fmap

  # fmri
  fslroi \
    ${orig}/func/sub-${sub}_run-${run}_fmri \
    ${dest}/fmri/sub-${sub}_run-${run}_fmri \
    0 1

  echo extracted vol 1 from ${orig}/fmap/sub-${sub}_run-${run}_fmri

done

# cd into the sub/fmri dir to make the commands shorter
cd ${dest}/fmri/

# Create the acqparams.txt file (the same for all sub/run)
echo 0 -1 0 0.05 >> acqparams.txt
echo 0  1 0 0.05 >> acqparams.txt


# Do topup
for run in $(seq ${nruns}); do

  # Merge fmri and fmap volume in this order
  fslmerge -t \
    sub-${sub}_run-${run}_fmri_fmap \
    sub-${sub}_run-${run}_fmri \
    sub-${sub}_run-${run}_fmap

  # Remove the single fmri and fmap volume (we don't need them anymore)
  imrm sub-${sub}_run-${run}_fmri
  imrm sub-${sub}_run-${run}_fmap

  # topup command
  time topup \
    --imain=sub-${sub}_run-${run}_fmri_fmap \
    --datain=acqparams.txt \
    --config=b02b0.cnf \
    --out=topup_sub-${sub}_run-${run}

done


# Applytopup
for run in $(seq ${nruns}); do

  applytopup \
  --imain=${orig}/func/sub-${sub}_run-${run}_fmri \
	--inindex=1 \
	--datain=acqparams.txt \
	--topup=topup_sub-${sub}_run-${run} \
  --method=jac  \
	--out=${dest}/fmri/sub-${sub}_run-${run}_fmri_topup


  # The fmri_topup is huge since there are many values outside the brain.
  # Create a mean fmri image, extract a mask and multiply fmri_topup by this mask
  fslmaths \
    sub-${sub}_run-${run}_fmri_topup -Tmean \
    sub-${sub}_run-${run}_fmri_topup_avg

  bet2 \
    sub-${sub}_run-${run}_fmri_topup_avg \
    sub-${sub}_run-${run}_fmri_topup_avg_brain \
    -m -f 0.2

  fslmaths \
    sub-${sub}_run-${run}_fmri_topup \
    -mul \
    sub-${sub}_run-${run}_fmri_topup_avg_brain_mask \
    sub-${sub}_run-${run}_fmri_topup

done



# Housekeeping
mkdir topup_log

for run in $(seq ${nruns}); do
  mv topup_sub-${sub}_run-${run}* topup_log/
  mv sub-${sub}_run-${run}_fmri_fmap.topup_log topup_log/

  # images that can be used to verify the output of bet2
  mv sub-${sub}_run-${run}_fmri_topup_avg.nii.gz topup_log/
  mv sub-${sub}_run-${run}_fmri_topup_avg_brain_mask.nii.gz topup_log/


  imrm sub-${sub}_run-${run}_fmri_fmap.nii.gz
  imrm sub-${sub}_run-${run}_fmri_topup_avg_brain.nii.gz

  rm acqparams.txt

done



#EOF
