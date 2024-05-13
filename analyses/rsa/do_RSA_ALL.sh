#!/bin/bash

# NB: keep in mind that each loop starts 40 (forty!) background R processes

gm_mask=test_mask
for ratings_type in emotion arousal; do
    for subs_set in TOP_RATERS ALL_SUBS; do
        Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done

wait

gm_mask=insula_HO_GM
for ratings_type in emotion arousal; do
    for subs_set in TOP_RATERS ALL_SUBS; do
        Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done

wait

gm_mask=insula_HO
for ratings_type in emotion arousal; do
    for subs_set in TOP_RATERS ALL_SUBS; do
        Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done


wait

gm_mask=HO_subcortical
for ratings_type in emotion arousal; do
    for subs_set in TOP_RATERS ALL_SUBS; do
        Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done


wait


# GM_clean
# This requires a lot of memory, so only two processes at the time should be launched
for ratings_type in emotion arousal; do
    nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} GM_clean TOP_RATERS &
done

for ratings_type in emotion arousal; do
    nohup Rscript do_RSA_V10_Searchlight.R ${ratings_type} GM_clean ALL_SUBS &
done


# -------------------------------------------------------------------------------

gm_mask=insula_HO_GM
for ratings_type in emotion arousal; do
    for subs_set in TOP_RATERS ALL_SUBS; do
        Rscript do_RSA_V10_Searchlight.R ${ratings_type} ${gm_mask} ${subs_set} &
    done
done

wait

# Subsequent randomise
./do_randomise_simple.sh N14_insula_HO_GM_EER insula_HO_GM 5000
./do_randomise_simple.sh N26_insula_HO_GM_EER insula_HO_GM 5000