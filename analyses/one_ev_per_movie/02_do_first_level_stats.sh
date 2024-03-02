#!/bin/bash

# run with ./02_do_first_level_stats.sh $sub
# where $sub is NOT zeropadded. This is because we cannot (without too much difficulty)
# store zeropadded sub_id in /data00/leonardo/RSA/sub_list.txt

sub=$(printf "%02d" $1)

model="one_ev_per_movie"

RSA_dir="/data00/leonardo/RSA"
sub_fmri_dir="${RSA_dir}/prep_data/sub-${sub}/fmri"

fsf_template="${RSA_dir}/analyses/${model}/first_level_template.fsf"

list_numba_movies="${RSA_dir}/analyses/${model}/list_numba_movies.txt"


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
  # sub-02/fmri/emotion/sub-02_run-1
  # sub-02/fmri/emotion/sub-02_run-1


  # __NUMBA_EVS_ORIG__
  numba_evs_orig=`cat ${list_numba_movies} | wc -l`
  # __NUMBA_EVS_REAL__
  numba_evs_real=$(( ${numba_evs_orig} * 2 ))

  # __NUMBA_CONTRASTS__
  numba_contrasts=${numba_evs_orig}

  # __ADD_MOTION_PARAMETERS__
  # 0 = no motion parameters in the model
  # 1 = std motion parameters
  # 2 = extended motion parameters
  add_motion_parameters=1

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
      -e "s@__NUMBA_EVS_ORIG__@${numba_evs_orig}@g" \
      -e "s@__NUMBA_EVS_REAL__@${numba_evs_real}@g" \
      -e "s@__NUMBA_CONTRASTS__@${numba_contrasts}@g" \
      -e "s@__ADD_MOTION_PARAMETERS__@${add_motion_parameters}@g" \
      ${fsf_template} > ${fsf_sub_run}

  echo
  echo


# Add EV-specific lines
# NB: because we use the cat << EOF construct, these lines
# are NOT indented 
while read EVNUMBA EVNAME; do

# calculate the numba of con_real = (EVNUMBA *2) - 1
CON_REAL_NUMBA=$(( (${EVNUMBA}*2)-1 ))

cat << EOF >> ${fsf_sub_run}


# ------ EV ${EVNUMBA} title ------
set fmri(evtitle${EVNUMBA}) "${EVNAME}"

# Basic waveform shape (EV ${EVNUMBA})
# 3 : Custom (3 column format)
set fmri(shape${EVNUMBA}) 3

# Convolution (EV ${EVNUMBA})
# 2 : Gamma
set fmri(convolve${EVNUMBA}) 2
set fmri(convolve_phase${EVNUMBA}) 0
set fmri(tempfilt_yn${EVNUMBA}) 1
set fmri(deriv_yn${EVNUMBA}) 1

# Custom EV file (EV ${EVNUMBA})
set fmri(custom${EVNUMBA}) "${preproc_reg_dest}/sub-${sub}_run-${run}_${EVNAME}.mat"
set fmri(gammasigma${EVNUMBA}) 3
set fmri(gammadelay${EVNUMBA}) 6

# Display images for contrast_orig ${EVNUMBA}
set fmri(conpic_orig.${EVNUMBA}) 1
set fmri(conname_orig.${EVNUMBA}) "${EVNAME}"
set fmri(con_orig${EVNUMBA}.${EVNUMBA}) 1

# Display images for contrast_real ${EVNUMBA}
set fmri(conpic_real.${EVNUMBA}) 1                     
set fmri(conname_real.${EVNUMBA}) "${EVNAME}"       
set fmri(con_real${EVNUMBA}.${CON_REAL_NUMBA}) 1 
EOF

done < ${list_numba_movies}
# the lines above are NOT indented because of the cat << EOF construct
# do not change this!

# Add instructions for orthogonalization (all zeros, but necessary for feat to run)
  numba_evs_orig=`cat ${list_numba_movies} | wc -l`

  echo >> ${fsf_sub_run}

  for ev in $(seq 1 ${numba_evs_orig}); do
      for j in $(seq 0 ${numba_evs_orig} ); do
          echo "set fmri(ortho${ev}.${j}) 0" >> ${fsf_sub_run}
      done
      echo >> ${fsf_sub_run}
  done



done


# create a bash array with all the 8 fsf and then run it in parallel
fsf_paths=("${sub_fmri_dir}/${model}/design_sub-${sub}_run-"{1..8}".fsf")
printf "%s\n" "${fsf_paths[@]}" | xargs -P 8 -I{} feat {}

