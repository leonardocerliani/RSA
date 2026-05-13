# AT_insula creation

```bash
cp ../HO_cort.nii.gz .
cp ../anatomy_toolbox.nii.gz .
cp ../MNI152_T1_2mm_brain.nii.gz .

# isolate insula in HO
fslmaths HO_cort.nii.gz -thr 2 -uthr 2 -bin HO_insula

# identify which regions of AT cross the insula as defined in HO
fslmaths anatomy_toolbox.nii.gz -mul HO_insula.nii.gz AT_HO_insula_intersect
fsl2ascii AT_HO_insula_intersect.nii.gz AT_HO_insula_intersect.txt
cat AT_HO_insula_intersect.txt00000 | tr ' ' '\n' | sort -n | uniq | grep -v '^0$' > AT_ROIs_numba_in_insula.txt

# isolate the corresponding regions in the AT atlas
fslmaths anatomy_toolbox -mul 0 AT_insula

for roi in $(cat AT_ROIs_numba_in_insula.txt); do

    echo roi ${roi}
    fslmaths anatomy_toolbox.nii.gz -thr ${roi} -uthr ${roi} tmp_${roi}
    fslmaths AT_insula -add tmp_${roi} AT_insula
    imrm tmp_${roi}

done

# The ventral anterior insula is missing from then AT, so we replace it with the remaining part of the HO_insula
fslmaths AT_insula.nii.gz -bin AT_insula_mask
fslmaths AT_insula_mask -add HO_insula.nii.gz -uthr 1 vAI
fslmaths vAI -mul HO_insula vAI

# Set the vAI voxels to 901
fslmaths vAI -add 900 vAI_shifted
fslmaths vAI -mul vAI_shifted vAI

# Add it to AT_insula
fslmaths AT_insula -add vAI AT_insula
```
