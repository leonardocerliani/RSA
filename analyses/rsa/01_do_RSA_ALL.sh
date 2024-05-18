#!/bin/bash

# Launch with :
# nohup ./do_RSA_ALL.sh > nohup_RSA_ALL.out &

# NB: keep in mind that each loop starts 10 * ratings_type * subs_set processes
# e.g. a loop with ratings_type = (emotion, arousal) and subs_set = (TOP_RATERS, ALL_SUBS)
# will start 40 background processes

# Also, GM_clean takes a lot of memory. For this reason, it's important to
# start one hemisphere first, and then other one only when the first one completes
# For this reason there is a wait between the loops


# gm_mask : 
# - GM_clean_RH / LH
# - insula_HO 
# - HO_subcortical
# - test_mask

# ratings_type
# - emotion (emotion_median / emotion_reference)
# - arousal
# - valence

# subs_set
# - TOP_RATERS 
# - ALL_SUBS


------------- REAL DEAL -----------

# TOP RATERS LH
gm_mask=GM_clean_LH
for ratings_type in emotion arousal valence; do
    for subs_set in TOP_RATERS; do
        nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done

wait 

# TOP RATERS RH
gm_mask=GM_clean_RH
for ratings_type in emotion arousal valence; do
    for subs_set in TOP_RATERS; do
        nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done

wait

# ALL SUBS LH
gm_mask=GM_clean_LH
for ratings_type in emotion arousal valence; do
    for subs_set in ALL_SUBS; do
        nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done

wait 

# ALL SUBS RH
gm_mask=GM_clean_RH
for ratings_type in emotion arousal valence; do
    for subs_set in ALL_SUBS; do
        nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done



# # ------------ JUST TEST -----------
# gm_mask=test_mask
# for ratings_type in emotion_median; do
#     for subs_set in TOP_RATERS; do
#         nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
#     done
# done













