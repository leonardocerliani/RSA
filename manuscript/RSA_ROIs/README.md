# Examining subregions of Yeo7 in different atlases

## Rationale
We selected two initial Yeo7 regions: the limbic and the ventral attentional system. Now we want to probe this regions, which are large, at the level of its subregions in different atlases, specifically the AT (Anatomy Toolbox), Yeo17 and the HO_cort (Harvard-Oxford cortical).

To do so, I wrote a script that takes two arguments: the initial Yeo7 region and the (sub-regional) atlas. This script shows all the regions in the atlas that intersect the initial Yeo7 region, and creates binary nii.gz for those regions.
Then these regions should be checked in the RSA_ROI_app to see if there is 1. a significant RSA score in emotion, arousal, aroval; and 2. a significant difference between them

The directory content is as follows:

```bash
├── _TEST_Yeo7_Limbic           # dir for creating regions from Ye07_Limbic
│   ├── AT.nii.gz               # AT Atlas
│   ├── AT_in_Yeo7_region       # directory with all the AT regions intersecting Yeo7_Limbic
│   ├── HO_cort.nii.gz
│   ├── HO_cort_in_Yeo7_region
│   ├── Yeo17.nii.gz
│   ├── Yeo17_in_Yeo7_region
│   ├── Yeo7_limbic_ROI5.nii.gz
│   ├── _SIG                    # regions with significance
│   └── do_filter_subregions.sh # script to create the regions from the atlas
│
└── _TEST_Yeo7_Ventral_Attentional  # dir for creating regions from Ye07_VA
```

## Generating the atlas regions intersecting the Yeo7 region
The script `do_filter_subregions.sh` requires two arguments, that are shown when it is run with no arguments:

```bash
Usage: ./do_filter_subregions.sh <yeo7_region> <atlas_filename (without .nii.gz)>
Example: do_filter_subregions.sh Yeo7_VA_ROI4.nii.gz Yeo17
```

The regions are then created in the `<atlas>_in_Yeo7_region`. At this point we should manually check the RSA_ROI_app which of these contain some significant result, and copy these regions in the `_SIG` dir.
**NB**: you should use the version in the RSA_ROI_app folder since it contains a button to download the image in pdf format.

## Drawings for the pictures
The boxplot can be downloaded from the app `RSA_papaya_results_atlas_V6.5_NO_VALENCE.R` in `/data00/leonardo/RSA/analyses/RSA_ROI_APP` (the one on the shiny server still does not have the possibility to download the picture). Note that the results of the within-model t-test are also included below the boxplots.

To clean them, open them in LibreOffice Draw. Make sure you save an .odg version of the clean version, since the pdf cannot be edited properly anymore afterwards

The brain overlays are in mricrogl (terminal `mri` command). Instructions about the mricrogl parameters are in the slides. 

Eventually, for one ROI you will have the following files:

```bash
.
├── AT_102.nii.gz       # volume extracted by the do_filter_subregions.sh
├── AT_102.pdf          # boxplot downloaded from the app
├── AT_102.odg          # edited (clean) version of the boxplot in LibreOffice format
├── AT_102_clean.pdf    # pdf version of the clean boxplot
├── AT_102.png          # mricrogl slice overlay of the ROI on the MNI
```






