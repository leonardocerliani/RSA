#!/bin/bash

HO_sub=HarvardOxford-sub-maxprob-thr50-2mm

for roi in 1 2 3 8 12 13 14; do

	fslmaths ${HO_sub} -thr ${roi} -uthr ${roi} r${roi}

done

fslmaths ${HO_sub} -sub r1 -sub r2 -sub r3 -sub r8 -sub r12 -sub r13 -sub r14 HO_subcortical

rm r*

# EOF

