# Reads the onsets.csv file in the raw_data folder and writes
# the prep_data/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}.mat file
# which will be used in the first-level feat.
# It cycles through all subs and all runs for each sub
# run with Rscript do_prepare_mat_one_ev_per_movie.R


# Load library and define initial variables
library(tidyverse)

subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

model="one_ev_per_movie"

nRuns = 8
runs <- as.character(1:nRuns)


# Reading onset.csv file, select ratings and write the .mat files
# **IMPORTANT:** in the onset file, the movie_number go from 0..5, 
# while in the ratings file they go from 1..56, 
# so we need to add 1 in the onset_file in order to have a proper match. 
# This is so important and can generate so much confusion 
# - e.g. running the code twice - that we will actually # 
# create a separate df called df_added1.

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
  #
  # also, replace the duration - currently 1 - with 1.5 since the movies 
  # are approx 1.5 seconds
  
  df_added1 <- df %>% 
    mutate(movie_number = movie_number + 1) %>% 
    mutate(duration = 1.5) %>% 
    mutate(onset_sec = round(onset_sec,2)) %>% 
    separate(movie_code, into = c("actor", "emotion", "intensity"), sep = "_") %>% 
    mutate(emotion = case_when(
      emotion == "A" ~ "Anger",
      emotion == "D" ~ "Disgust",
      emotion == "F" ~ "Fear",
      emotion == "H" ~ "Happy",
      emotion == "N" ~ "Neutral",
      emotion == "P" ~ "Pain",
      emotion == "S" ~ "Sad",
      TRUE ~ as.character(emotion)  # If none of the above, keep the original value
    )) %>%
    mutate(movie = paste(actor, emotion, intensity, sep = "_")) %>% 
    select(!c(actor,emotion,intensity,movie_number)) %>% 
    mutate(feat_intensity = 1)
  
  
  # write the .mat files
  for (ith_movie in df_added1$movie) {
    mat_file_3_cols <- df_added1 %>% 
      filter(movie == ith_movie) %>% 
      select(!movie)
    
    mat_file_path <- paste0(
      dest, "/sub-", sub, "_run-", run, "_", ith_movie, ".mat"
    )
    # print(mat_file_path)
    
    write_tsv(mat_file_3_cols, col_names = FALSE, mat_file_path)
  }
  
}


# # example: write all .mat files (one for each run) for one sub
# # NB!!! Needs orig and dest!
# as.character(1:8) %>% walk(~ read_onsets_write_mat(sub, run = .x, dest = dest))
# # You can then check in the dir the correct numba of files with the bash:
# for i in $(seq 8); do echo run ${i} `ls sub*run-${i}* | wc -l`; done




# Loops across subs and runs
# I use a `for` construct for subjects since two nested 
# `map` can be difficult to read 

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

