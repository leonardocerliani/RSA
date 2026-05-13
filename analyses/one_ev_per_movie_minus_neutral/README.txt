one_ev_per_movie_minus_neutral
12-8-2024

Creating the 1st level fsf for this one was a total nightmare. The reason is that we need to 
write the 1 for the main contrast *and* the -1 for the neutral.

1. take the first_level_template.fsf from one_ev_per_movie
This will write all the common measures and the orthogonalizations (all set to zero) but not the matrices

2. take the 02_first_level_stats.sh are remove the following
# set fmri(con_orig${EVNUMBA}.${EVNUMBA}) 1
# set fmri(con_real${EVNUMBA}.${CON_REAL_NUMBA}) 1 
Since we will write the contrast lines manually

3. run the do_contrasts_for_1st_level_template.Rmd, which loads the emotion_ratings.do_contrasts_for_1st_level_template
and figures out the contrast table (at it also displays it).
Finally it generates contrast_lines.txt which are the same for all subs/run
(because the model is always the same)

4. modify the 02_first_level_stats.sh so that it attaches the contrast_lines.txt
at the bottom of each desing_sub-[sub]_run-[run].fsf

5. now it's ready to run. While you cannot really inspect the fsf in Feat, you can save
a new fsf after loading it and it will produce a png that will convince you that the 
model has been correctly specified


