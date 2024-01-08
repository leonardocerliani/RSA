#!/bin/bash

sub=$(printf "%02d" $1)

bd="/data00/leonardo/RSA/prep_data"
script_dir=$PWD
fsf_template="${script_dir}/template_preproc_reg.fsf"

orig="${bd}/sub-${sub}/fmri"

t1w_brain="${bd}/sub-${sub}/anat/sub-${sub}_T1w_brain"
mni_template="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm_brain"

# smoothing kernel in mm
smoothing_mm=5

for run in $(seq 8); do

  fsf_path=${orig}/sub-${sub}_run-${run}_preproc_reg.fsf
  # fsf_path=${script_dir}/sub-${sub}_run-${run}_preproc_reg.fsf

  nii4d=${orig}/sub-${sub}_run-${run}_fmri_topup.nii.gz
  nii4d=`remove_ext ${nii4d}`

  feat_outputdir="${orig}/sub-${sub}_run-${run}_preproc_reg"

  # remove previous fsf and feat dirs
  rm -rf ${feat_outputdir}.*

  dim1=`fslinfo ${nii4d} | grep ^dim1 | awk '{print $2}'`
  dim2=`fslinfo ${nii4d} | grep ^dim2 | awk '{print $2}'`
  dim3=`fslinfo ${nii4d} | grep ^dim3 | awk '{print $2}'`
  dim4=`fslinfo ${nii4d} | grep ^dim4 | awk '{print $2}'`

  totalVoxels=$((dim1*dim2*dim3*dim4))

  totalVolumes=${dim4}

  trnii4d=`fslinfo ${nii4d} | grep pixdim4 | awk '{print $2}'`

  # Prepare fsf using the template and sed
  sed -e "s@FEATOUTPUTDIR@${feat_outputdir}@g"  \
      -e "s@TRNII4D@${trnii4d}@g"               \
      -e "s@TOTALVOLUMES@${totalVolumes}@g"     \
      -e "s@SMOOTHINGKERNEL@${smoothing_mm}@g"  \
      -e "s@MNITEMPLATE@${mni_template}@g"      \
      -e "s@TOTALNUMBAVOXELS@${totalVoxels}@g"  \
      -e "s@NIFTI4D@${nii4d}@g"                 \
      -e "s@T1WBRAIN@${t1w_brain}@g"            \
        ${fsf_template} > ${fsf_path}

  echo sub-${sub}_run-${run}_preproc_reg.fsf created in
  echo ${orig}

done

# create a bash array with all the 8 fsf and then run it in parallel
fsf_paths=("${orig}/sub-${sub}_run-"{1..8}"_preproc_reg.fsf")

printf "%s\n" "${fsf_paths[@]}" | xargs -P 8 -I{} feat {}

# rm the fsf file, since they are copied to the feat/design.fsf file
rm ${orig}/*.fsf

#EOF
