#!/bin/bash

# run with ./do_first_level_stats.sh $sub
# where $sub is NOT zeropadded (see below)

sub=$(printf "%02d" $1)

model="valence"

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

  # __CUSTOM_EV_FILE_PATH__
  custom_ev_file_path="sub-${sub}/fmri/${model}/sub-${sub}_run-${run}"
  

  for var in tr total_volumes MNI_template total_voxels feat_dir \
             anat_brain_image custom_ev_file_path; do

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
      -e "s@__CUSTOM_EV_FILE_PATH__@${custom_ev_file_path}@g" \
      ${fsf_template} > ${fsf_sub_run}

  echo
  echo
done


# create a bash array with all the 8 fsf and then run it in parallel
fsf_paths=("${sub_fmri_dir}/${model}/design_sub-${sub}_run-"{1..8}".fsf")

# NB: the && wait makes sure that the subsequent rm command is launched only
# when all the background feat processes are completed
printf "%s\n" "${fsf_paths[@]}" | xargs -P 8 -I{} feat {} && wait

# tentative: remove all the .mat and .fsf files because in any case 
# they are copied inside the .feat directory
# I decided to leave them for the moment so that I can check the design with Feat
# rm ${sub_fmri_dir}/${model}/*.mat
# rm ${sub_fmri_dir}/${model}/*.fsf


#EOF


# rm -rf *.feat; rm *.fsf
