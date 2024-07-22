#!/bin/bash

# run with ./do_first_level_stats.sh $sub
# where $sub is NOT zeropadded (see below)

sub=$(printf "%02d" $1)

model="emotion_high_low_predictors"

RSA_dir="/data00/leonardo/RSA"
sub_fmri_dir="${RSA_dir}/prep_data/sub-${sub}/fmri"

fsf_template="${RSA_dir}/analyses/${model}/first_level_template.fsf"



for run in $(seq 8); do

  echo "Processing sub-${sub}_run-${run}"

  # Create a copy of the preproc_reg.feat dir inside ${model}
  preproc_reg_orig="${sub_fmri_dir}/sub-${sub}_run-${run}_preproc_reg.feat"
  preproc_reg_dest="${sub_fmri_dir}/${model}"
  cp -r ${preproc_reg_orig} ${preproc_reg_dest}

  # fsf to be created for one sub/run
  fsf_sub_run="${sub_fmri_dir}/${model}/design_sub-${sub}_run-${run}.fsf"

  sub_mat="${sub_fmri_dir}/${model}/sub-${sub}_run-${run}.mat"
  sub_feat="${sub_fmri_dir}/${model}/sub-${sub}_run-${run}_preproc_reg.feat"

  for var in fsf_sub_run sub_mat sub_feat; do
    echo "${var} : ${!var}"
  done
  echo

  # variables for sed substitution from the fsf_template
  dim1=$(fslinfo ${sub_feat}/filtered_func_data.nii.gz | grep ^dim1 | awk '{print $2}')
  dim2=$(fslinfo ${sub_feat}/filtered_func_data.nii.gz | grep ^dim2 | awk '{print $2}')
  dim3=$(fslinfo ${sub_feat}/filtered_func_data.nii.gz | grep ^dim3 | awk '{print $2}')
  dim4=$(fslinfo ${sub_feat}/filtered_func_data.nii.gz | grep ^dim4 | awk '{print $2}')


  # __TR__
  tr=$(fslinfo ${sub_feat}/filtered_func_data.nii.gz | grep pixdim4 | awk '{print $2}')

  # __TOTALVOLUMES__
  total_volumes=${dim4}

  # __MNITEMPLATE__
  MNI_template="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm_brain"

  # __TOTALNUMBAVOXELS__
  total_voxels=$((dim1*dim2*dim3*dim4))

  # __FEATDIR__
  feat_dir=${sub_feat}

  # __ANATBRAINIMAGE__
  anat_brain_image="${RSA_dir}/prep_data/sub-${sub}/anat/sub-${sub}_T1w_brain"

  # __EV_1_ANGER_HIGH__
  ev_1_anger_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_anger_high.mat"
  # __EV_2_ANGER_LOW__
  ev_2_anger_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_anger_low.mat"


  # __EV_3_DISGUST_HIGH__
  ev_3_disgust_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_disgust_high.mat"
  # __EV_4_DISGUST_LOW__
  ev_4_disgust_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_disgust_low.mat"


  # __EV_5_FEAR_HIGH__
  ev_5_fear_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_fear_high.mat"
  # __EV_6_FEAR_LOW__
  ev_6_fear_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_fear_low.mat"


  # __EV_7_HAPPY_HIGH__
  ev_7_happy_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_happy_high.mat"
  # __EV_8_HAPPY_LOW__
  ev_8_happy_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_happy_low.mat"


  # __EV_9_NEUTRAL_HIGH__
  ev_9_neutral_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_neutral_high.mat"
  # __EV_10_NEUTRAL_LOW__
  ev_10_neutral_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_neutral_low.mat"


  # __EV_11_PAIN_HIGH__
  ev_11_pain_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_pain_high.mat"
  # __EV_12_PAIN_LOW__
  ev_12_pain_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_pain_low.mat"


  # __EV_13_SAD_HIGH__
  ev_13_sad_high="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_sad_high.mat"
  # __EV_14_SAD_LOW__
  ev_14_sad_low="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}/sub-${sub}_run-${run}_sad_low.mat"




  for var in tr total_volumes MNI_template total_voxels feat_dir anat_brain_image \
    ev_1_anger_high ev_2_anger_low \
    ev_3_disgust_high ev_4_disgust_low \
    ev_5_fear_high ev_6_fear_low \
    ev_7_happy_high ev_8_happy_low \
    ev_9_neutral_high ev_10_neutral_low \
    ev_11_pain_high ev_12_pain_low \
    ev_13_sad_high ev_14_sad_low ; do

        # indirect variable referencing, cool.
        echo "${var} : ${!var} "

  done

  # Replace using sed
  sed -e "s@__TR__@${tr}@g" \
      -e "s@__TOTALVOLUMES__@${total_volumes}@g" \
      -e "s@__MNITEMPLATE__@${MNI_template}@g" \
      -e "s@__TOTALNUMBAVOXELS__@${total_voxels}@g" \
      -e "s@__FEATDIR__@${feat_dir}@g" \
      -e "s@__ANATBRAINIMAGE__@${anat_brain_image}@g" \
      -e "s@__EV_1_ANGER_HIGH__@${ev_1_anger_high}@g" \
      -e "s@__EV_2_ANGER_LOW__@${ev_2_anger_low}@g" \
      -e "s@__EV_3_DISGUST_HIGH__@${ev_3_disgust_high}@g" \
      -e "s@__EV_4_DISGUST_LOW__@${ev_4_disgust_low}@g" \
      -e "s@__EV_5_FEAR_HIGH__@${ev_5_fear_high}@g" \
      -e "s@__EV_6_FEAR_LOW__@${ev_6_fear_low}@g" \
      -e "s@__EV_7_HAPPY_HIGH__@${ev_7_happy_high}@g" \
      -e "s@__EV_8_HAPPY_LOW__@${ev_8_happy_low}@g" \
      -e "s@__EV_9_NEUTRAL_HIGH__@${ev_9_neutral_high}@g" \
      -e "s@__EV_10_NEUTRAL_LOW__@${ev_10_neutral_low}@g" \
      -e "s@__EV_11_PAIN_HIGH__@${ev_11_pain_high}@g" \
      -e "s@__EV_12_PAIN_LOW__@${ev_12_pain_low}@g" \
      -e "s@__EV_13_SAD_HIGH__@${ev_13_sad_high}@g" \
      -e "s@__EV_14_SAD_LOW__@${ev_14_sad_low}@g" \
      ${fsf_template} > ${fsf_sub_run}

  echo
  echo

done

# create a bash array with all the 8 fsf and then run it in parallel
fsf_paths=("${sub_fmri_dir}/${model}/design_sub-${sub}_run-"{1..8}".fsf")

printf "%s\n" "${fsf_paths[@]}" | xargs -P 8 -I{} feat {}

#EOF