#!/bin/bash

#!/bin/bash

orig=/data00/leonardo/RSA/analyses/Rnon2/Rnon2_imgs

dest=/data00/leonardo/RSA/analyses/Rnon2/fsl_glm


mat_file=${dest}/glm_models/N26.mat
con_file=${dest}/glm_models/N26.con

# MNI mask
mni_mask=/data00/leonardo/RSA/analyses/MNI/mni_mask.nii.gz


# -------- comment if the 4d images are already there ------------
echo "Creating 4d images..."
for model in allMovies arousal emotion valence; do

    fslmerge -t ${dest}/${model}_4d  $(ls ${orig}/${model}/*avg*)

done

echo "Creating 4d contrast timeseries..."
# create the contrasts to be tested with one-sample t test
fslmaths allMovies_4d -sub arousal_4d       ALL_vs_A
fslmaths allMovies_4d -sub emotion_4d       ALL_vs_E
fslmaths allMovies_4d -sub valence_4d       ALL_vs_V

fslmaths arousal_4d   -sub allMovies_4d     A_vs_ALL
fslmaths arousal_4d   -sub emotion_4d       A_vs_E
fslmaths arousal_4d   -sub valence_4d       A_vs_V

fslmaths emotion_4d   -sub allMovies_4d     E_vs_ALL
fslmaths emotion_4d   -sub arousal_4d       E_vs_A
fslmaths emotion_4d   -sub valence_4d       E_vs_V

fslmaths valence_4d   -sub allMovies_4d     V_vs_ALL
fslmaths valence_4d   -sub arousal_4d       V_vs_A
fslmaths valence_4d   -sub emotion_4d       V_vs_E
# -------- comment if the 4d images are already there ------------



# In the following, vs means 'bigger than'
for contrast in \
                A_vs_ALL    E_vs_ALL    V_vs_ALL    \
    ALL_vs_A                E_vs_A      V_vs_A      \
    ALL_vs_E    A_vs_E                  V_vs_E      \
    ALL_vs_V    A_vs_V      E_vs_V;                 \
    do 

    echo "Running glm for ${contrast}" 
    fsl_glm -i ${contrast} -o betas_${contrast} \
            -d ${mat_file} -c ${con_file} -m ${mni_mask} \
            --out_p=pvals_${contrast}
    
    # imrm ${contrast}
    rm betas*

    # for some strange reason the contrast [1] is the *second* image
    # and the contrast [-1] is the *first* image
    fslroi pvals_${contrast} pvals_${contrast} 1 1
    fslmaths pvals_${contrast} -thr 0.95 pvals_${contrast}

done



