#!/bin/bash


while read EVNUMBA EVNAME; do

cat << EOF >> ${fsf_sub_run}
# ------ EV ${EVNUMBA} title ------
set fmri(evtitle${EVNUMBA}) "${EVNAME}"

# Basic waveform shape (EV ${EVNUMBA})
# 3 : Custom (3 column format)
set fmri(shape${EVNUMBA}) 3

# Convolution (EV ${EVNUMBA})
# 2 : Gamma
set fmri(convolve${EVNUMBA}) 2
set fmri(convolve_phase${EVNUMBA}) 0
set fmri(tempfilt_yn${EVNUMBA}) 1
set fmri(deriv_yn${EVNUMBA}) 1

# Custom EV file (EV ${EVNUMBA})
set fmri(custom${EVNUMBA}) "sub-${sub}_run-${run}_${EVNAME}.mat"
set fmri(gammasigma${EVNUMBA}) 3
set fmri(gammadelay${EVNUMBA}) 6

# Display images for contrast_orig ${EVNUMBA}
set fmri(conpic_orig.${EVNUMBA}) 1
set fmri(conname_orig.${EVNUMBA}) "${EVNAME}"
set fmri(con_orig${EVNUMBA}.${EVNUMBA}) 1
EOF

done < list_numba_movies.txt



