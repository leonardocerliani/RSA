#!/bin/bash

# run with
# nohup ./do_randomise.sh > nohup.out &

# # build the 4d : allMovies  arousal  emotion  valence
# fslmerge -t 4d $(ls /data00/leonardo/RSA/analyses/Rnon2/Rnon2_imgs/*/*avg*)

# # create a MNI mask
# MNI="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz"
# fslmaths ${MNI} -div ${MNI} mask

# randomise -i 4d -o stats -d design.mat -t design.con -f design.fts -m mask -e design.grp -T -n 1000

randomise -i 4d -o stats -d design.mat -t design.con -f design.fts -m mask -e design.grp -T -x --uncorrp -n 1000


# randomise -i 4d -o stats -d design.mat -t design.con -f design.fts -m mask -n 1000 -x --uncorrp



# EOF