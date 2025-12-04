#!/bin/bash

# define the radius of the spherical kernel
r=6

reference_surface="Q1-Q6_R440.L.inflated.32k_fs_LR.surf.gii"

atlas="HO_cort"

for model in emotion arousal aroval; do

  for stat in T p BF01; do

    echo mapping RSA_${model}_${atlas}_${stat}

    # dilate using maximum filtering (-dilF)
    fslmaths RSA_${model}_${atlas}_${stat} \
      -kernel sphere $r -dilF \
      dil${r}_RSA_${model}_${atlas}_${stat}

    # map on the surface using the enclosing option to prevent interpolation 
    wb_command -volume-to-surface-mapping \
      dil${r}_RSA_${model}_${atlas}_${stat}.nii.gz \
      ${reference_surface} \
      mapped_RSA_${model}_${atlas}_${stat}.func.gii \
      -enclosing
    
  done

done

rm dil*