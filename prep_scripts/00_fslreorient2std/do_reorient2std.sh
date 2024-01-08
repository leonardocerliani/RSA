#!/bin/bash

sub=$(printf "%02d" $1)

echo Starting sub-${sub}... 

orig="/data01/cas/EmotionInsula7T_project/Data_Collection/sub-${sub}/ses-01"
dest="/data00/leonardo/RSA/raw_data/sub-${sub}"


[ -d "$dest" ] && rm -rf "$dest"
mkdir -p ${dest}  ${dest}/anat  ${dest}/func  ${dest}/fmap


if [ -d ${dest} ]; then
  rm -rf ${dest}
  mkdir -p ${dest}  ${dest}/anat  ${dest}/func  ${dest}/fmap
else
  mkdir -p ${dest}  ${dest}/anat  ${dest}/func  ${dest}/fmap
fi


# anat
fslreorient2std \
  ${orig}/anat/sub-${sub}_ses-01_acq-MPRAGE_T1w.nii \
  ${dest}/anat/sub-${sub}_T1w


for ((run=1;run<=8;run++)); do

  # fmap
    fslreorient2std \
      ${orig}/fmap/sub-${sub}_ses-01_task-emofaces_run-${run}_fmap.nii \
      ${dest}/fmap/sub-${sub}_run-${run}_fmap

  # func
    fslreorient2std \
      ${orig}/func/sub-${sub}_ses-01_task-emofaces_run-${run}_bold.nii \
      ${dest}/func/sub-${sub}_run-${run}_fmri

done

echo Concluded sub-${sub}



#EOF
