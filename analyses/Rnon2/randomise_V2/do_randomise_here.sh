#!/bin/bash

orig=/data00/leonardo/RSA/analyses/Rnon2/Rnon2_imgs

dest=/data00/leonardo/RSA/analyses/Rnon2/randomise_V2

# tstat1 : A > B
# tstat2 : B > A
mat_file=${dest}/randomise_models/N26.mat
con_file=${dest}/randomise_models/N26.con

# MNI mask
mni_mask=/data00/leonardo/RSA/analyses/MNI/mni_mask.nii.gz

for model in allMovies arousal emotion valence; do

    fslmerge -t ${dest}/${model}_4d  $(ls ${orig}/${model}/*avg*)

done

# create the contrasts to be tested with one-sample t test
fslmaths allMovies_4d -sub arousal_4d  allMovies_vs_arousal
fslmaths allMovies_4d -sub emotion_4d  allMovies_vs_emotion
fslmaths allMovies_4d -sub valence_4d  allMovies_vs_valence

fslmaths arousal_4d   -sub emotion_4d  arousal_vs_emotion
fslmaths arousal_4d   -sub valence_4d  arousal_vs_valence

fslmaths emotion_4d   -sub valence_4d  emotion_vs_valence

rm *4d*

for contrast in \
    allMovies_vs_arousal  allMovies_vs_emotion  allMovies_vs_valence \
    arousal_vs_emotion    arousal_vs_valence \
    emotion_vs_valence; do

    nohup randomise -i ${contrast} -o stats_${contrast} -d ${mat_file} -t ${con_file} -m ${mni_mask} -n 1000 -v 5 -T &
    rm stats_${contrast}_tstat?.nii.gz

done
