#!/bin/bash

bd=/data00/leonardo/RSA/analyses/rsa/rsa_results/GM_clean


for con in arousal emotion arousal_vs_emotion emotion_vs_arousal; do

	fslmaths ${bd}/N26_GM_clean_LH_EER/stats_${con}_tfce_corrp_tstat1 \
		-add  ${bd}/N26_GM_clean_RH_EER/stats_${con}_tfce_corrp_tstat1 \
		${bd}/N26_GM_clean_EER/stats_${con}_tfce_corrp_tstat1

done


