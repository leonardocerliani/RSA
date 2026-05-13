# Converting the anatomy toolbox to use in FSL

The [anatomy toolbox](https://github.com/inm7/jubrain-anatomy-toolbox) is the shittiest atlas distro in the world.

- It comes only in a matlab file
- In the provided map, the regions and the brain are in the same volume, therefore registration with the MNI in another space is not possible
- Also, the regions are not integers because most likely they went through a trilinear transformation (that should be *never* done with labels)

First we create a volume with only the regions. Looking at the histogram, we can *infer* that the regions have values above 150, and convert them to int16 (short)

```bash
orig="/Users/leonardo/Desktop/jubrain-anatomy-toolbox/anatomy_toolbox/JuBrain_Map_v30.nii"
fslmaths ${orig} -thr 150 jubrain_spm_space_float

# transform to INT16 to have proper labels
fslmaths jubrain_spm_space_float jubrain_spm_space_INT16 -odt short
```

Now we use fsleyes to create the affine matrix that will allow us to move the volume into the space we want. For this in fsleyes we use Tools -> Export Affine Transformation

Now we can use FLIRT (also from the gui) to finally export the image in FSL MNI 2mm space. 
**Remember the NN transformation!**

```bash
flirt -in jubrain_spm_space_INT16.nii.gz \
    -ref /Users/leonardo/fsl/data/standard/MNI152_T1_2mm_brain \
    -out jubrain_FSL2mm_space_INT16.nii.gz \
    -omat jubrain_FSL2mm_space_INT16.mat \
    -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  \
    -interp nearestneighbour
```

Finally, we still need to subtract 200 so that the regions start from 1

