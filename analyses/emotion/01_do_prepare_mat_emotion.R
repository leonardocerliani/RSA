# Reads the onsets.csv file in the raw_data folder and writes
# the prep_data/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}.mat file
# which will be used in the first-level feat.
# It cycles through all subs and all runs for each sub
# run with Rscript do_prepare_mat_emotion.R

# Load library and define initial variables
library(tidyverse)

subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

model="emotion"

# read ratings and zeropad the sub number
# remove the onset_sec - the onset in the out-of-scanner session
# not to generate confusion with the onset_sec column in the 
# onset.csv file (onsets inside the scanner)
ratings <- read_csv(
  paste0(
    "/data00/leonardo/RSA/analyses/RATINGS", "/", model, "_ratings.csv"
  )
) %>% 
  mutate(sub = sprintf("%02d", sub)) %>% 
  select(!onset_sec)

ratings

nRuns = 8
runs <- as.character(1:nRuns)



# Reading onset.csv file, select ratings and write the .mat files
# **IMPORTANT:** in the onset file, the movie_number go from 0..5, 
# while in the ratings file they go from 1..56, 
# so we need to add 1 in the onset_file in order to have a proper match. 
# This is so important and can generate so much confusion - e.g. 
# running the code twice - that we will actually create 
# a separate df called df_added1.

# # --------------- just for testing - BEGIN -----------------------------------
# sub=subs[1]
# run = 1
# 
# orig_csv_root = "/data00/leonardo/RSA/raw_data"
# dest = paste0("/data00/leonardo/RSA/prep_data/sub-", sub, "/fmri/", model)
# 
# if (!dir.exists(dest)) {dir.create(dest)} else paste0(dest, " exists")
# paste0("Creating .mat files for sub", sub, " in ", dest) %>% print
# # --------------- just for testing - END -----------------------------------

read_onsets_write_mat <- function(sub, run, dest) {
  current_sub = sub
  current_run = run
  
  orig_csv_root = "/data00/leonardo/RSA/raw_data"
  dest = paste0("/data00/leonardo/RSA/prep_data/sub-", sub, "/fmri/", model)
  
  sub_onsets_file <- paste0(orig_csv_root,
                            "/sub-", sub,
                            "/onsets/sub-", sub,"_Ins_onsets_allmovies_run-", run, ".csv")
  
  df <- read_csv(sub_onsets_file, progress = F) %>% suppressMessages()
  
  colnames(df) = c("movie_number", "onset_sec", "duration", "movie_code")
  
  # add 1 to the movie number for consistency with the ratings file
  # retain only the col needed for the inner_join (movie_number) and
  # to write in the mat file (onset_sec, duration)
  df_added1 <- df %>% 
    mutate(movie_number = movie_number + 1) %>% 
    select(!movie_code)
  
  # Start from the rating, select sub and run and *then* join the df_added1
  # Finally select the three column .mat file for feat:
  # (1) onset, (2) duration, (3) intensity = rating
  mat_4_feat <- ratings %>% 
    filter(sub == current_sub, run == current_run) %>% 
    inner_join(df_added1, by = "movie_number") %>% 
    select(onset_sec, duration, starts_with("r_")) %>% 
    mutate(onset_sec = round(onset_sec, 2)) %>% 
    arrange(onset_sec)
  
  for (emotion in c("anger","disgust","fear","happy","pain","sad")) {
    mat_one_emotion <- mat_4_feat %>% 
      select(onset_sec, duration, paste0("r_", emotion))
    
    mat_path <- paste0(
      dest, "/sub-", sub, "_run-", run, "_", emotion, "_rating.mat"
    )
    # print(mat_path)
    
    write_tsv(mat_one_emotion, col_names = FALSE, mat_path)
  }
}

# # example: write all .mat files (one for each run) for one sub
# # NB!!! Needs orig and dest!
# as.character(1:8) %>% walk(~ read_onsets_write_mat(sub, run = .x, dest = dest))




# Loops across subs and runs
# I use a `for` construct for subjects since two nested `map` 
# can be difficult to read 

for (sub in subs) {
  
  # e.g. /data00/leonardo/RSA/raw_data/sub-02/onsets
  orig_csv_root = "/data00/leonardo/RSA/raw_data"
  dest = paste0("/data00/leonardo/RSA/prep_data/sub-", sub, "/fmri/", model)
  
  # create the dir where all the mat files (and the stats.feat) will be stored
  if (!dir.exists(dest)) {dir.create(dest)} else paste0(dest, " exists")
  paste0("Creating .mat files for sub", sub, " in ", dest) %>% print
  
  # write all .mat files (one for each run) for that sub
  runs %>% walk(~ read_onsets_write_mat(sub = sub, run = .x, dest = dest))
}
