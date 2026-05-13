-- IMPORTANT NOTE ABOUT THE list_numba_movies.txt FILE --

The file list_numba_movies.txt contains the correspondence 
between the movie description (actor_emotion_intensity, e.g. JvG_Fear_high)
and the cope number as it will be specified and output by FSL Feat.

This is necessary since in FSL Feat it is not possible to qualify the 
copes directly with a string. Instead, sequential (non-zeropadded) numbers
should be used. 
This happens when preparing the first-level fsf files in 02_do_first_level_stats.sh.

IT IS AN EXTREMELY IMPORTANT FILE because it allows to connect the 
output of Feat to a specific movie/stimulus

The number was assigned according to the alphabetical order of the 
movie code with the emotion name spelled out. This is the same in 
all participants.

For more information about how this file was generated, check out the
bottom cell in the 01_do_prepare_mat_one_ev_per_movie_DEV.Rmd notebook.
Since it needs to be generated only once, this cell was not 
placed in the 01_do_prepare_mat_one_ev_per_movie.R file.

