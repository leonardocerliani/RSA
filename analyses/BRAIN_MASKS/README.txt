
The GM_clean mask is created starting from the GM and Subcortical templates
provided with the CBIG repo from the Yeo lab (https://github.com/ThomasYeoLab/CBIG/tree/master).

Specifically the two maps can be found in 
/data00/leonardo/atlases/CBIG/data/templates/volume/FSL_MNI152_masks


fslmaths GM_Mask_MNI1mm_MNI2mm_91x109x91.nii.gz \
	-sub SubcorticalLooseMask_MNI1mm_sm6_MNI2mm_bin0.2.nii.gz \
	-thr 0 \
	GM_clean

As such, it does NOT include CRB and subcortical GM

# EOF

