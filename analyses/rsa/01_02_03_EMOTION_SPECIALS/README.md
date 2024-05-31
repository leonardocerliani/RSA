# EMOTION models

This dir contains the script to prepare the RSA and subsequent randomise analysis
to investigate differences between different models for emotion, and specifically
those that can be found in `/data00/leonardo/RSA/analyses/RATINGS`

- `emotion_ratings.csv` : the original emotion model, where each participant has its own ratings

- `emotion_MEDIAN` : where each participant's rating is replaced by the median across all participants

- `emotion_RUNE` : where each participant's rating is replaced by the ratings obtained by Rune during the online validation phase on N (?) participants

- `emotion_IDEAL` : where each congruent rating is 10 and every other rating is 0 - except for neutral movies, where the rating is always 0.

The scripts should be copied and run from `/data00/leonardo/RSA/analyses`

The final directory will be called `rsa_results_EMOTION_SPECIALS`


