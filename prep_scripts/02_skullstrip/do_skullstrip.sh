#!/bin/bash

script_launch_dir=`pwd`

sub=$(printf "%02d" $1)

orig="/data00/leonardo/RSA/raw_data/sub-${sub}/anat"
dest="/data00/leonardo/RSA/prep_data/sub-${sub}/anat"

[ -d ${dest} ] && rm -rf ${dest}
mkdir ${dest}

cd ${orig}

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1

antsBrainExtraction.sh \
	-d 3 \
	-a sub-${sub}_T1w.nii.gz  \
	-e ${ANTS_TEMPLATES}/Oasis/T_template0.nii.gz \
	-m ${ANTS_TEMPLATES}/Oasis/T_template0_BrainCerebellumProbabilityMask.nii.gz \
	-o out

mv outBrainExtractionBrain.nii.gz sub-${sub}_T1w_brain.nii.gz
mv outBrainExtractionMask.nii.gz sub-${sub}_T1w_brain_mask.nii.gz

cp ${orig}/*T1w*.nii.gz ${dest}

echo Copied sub-${sub} T1w, T1w_brain and _T1w_brain_mask to
echo ${dest}
echo

cd ${script_launch_dir}

#EOF
