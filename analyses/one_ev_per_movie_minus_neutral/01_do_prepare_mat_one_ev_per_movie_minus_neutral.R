# Reads the onsets.csv file in the raw_data folder and writes
# the prep_data/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}.mat file
# which will be used in the first-level feat.
# It cycles through all subs and all runs for each sub
# run with Rscript 01_do_prepare_mat_one_ev_per_movie.R


# Load library and define initial variables
library(tidyverse)

subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

model="one_ev_per_movie_minus_neutral"
movie_duration = 1.5 # (seconds)

nRuns = 8
runs <- as.character(1:nRuns)


# Reading onset.csv file, prepare and write the .mat files
read_onsets_write_mat <- function(sub_id, run_id, dest) {
  
  sub_onsets_file <- paste0(orig_csv_root,
                            "/sub-", sub_id,
                            "/onsets/sub-", sub_id, "_onset_run",run_id,".csv")
  
  # read onset file and add duration and intensity (constants) columns for mat file
  # NB here the "intensity" is not the high/low, it's the one for the 3-col mat file
  df <- read_csv(sub_onsets_file, progress = F) %>% suppressMessages() %>% 
    mutate(duration = movie_duration, intensity = 1)
  
  # select the 3 columns : onset_sec, duration, intensity
  # and generate the filename where the emotion code is replaced
  # by the emotion name spelled out
  df_4_mat <- df %>% 
    select(high_low_code, onset_sec, duration, intensity) %>% 
    separate(high_low_code, into = c("actor", "emotion_code", "high_low"), sep = "_") %>% 
    mutate(emotion_code = case_when(
      emotion_code == "A" ~ "Anger",
      emotion_code == "D" ~ "Disgust",
      emotion_code == "F" ~ "Fear",
      emotion_code == "H" ~ "Happy",
      emotion_code == "N" ~ "Neutral",
      emotion_code == "P" ~ "Pain",
      emotion_code == "S" ~ "Sad",
      TRUE ~ as.character(emotion_code)  # If none of the above, keep the original value
    )) %>% 
    mutate(mat_filename = paste(actor,emotion_code,high_low,sep = "_")) %>% 
    select(mat_filename, onset_sec, duration, intensity)
  
  # Write every mat file (in this case it will be one line per mat file)
  for (movie in df_4_mat$mat_filename) {
    
    mat_file_path <- paste0(dest,"/sub-",sub_id,"_run-",run_id,"_",movie,".mat")
    # paste0(mat_file_path,"\n") %>% cat
    
    mat_file_3_cols <- df_4_mat %>%
      filter(mat_filename == movie) %>%
      select(!mat_filename) %>%
      write_tsv(col_names = FALSE, mat_file_path)
    
  }
}


# Loop across subs and runs
# I use a `for` construct for subjects since two nested `map` can be difficult to read 
for (sub_id in subs) {
  
  # e.g. /data00/leonardo/RSA/raw_data/sub-02/onsets
  orig_csv_root = "/data00/leonardo/RSA/raw_data"
  dest = paste0("/data00/leonardo/RSA/prep_data/sub-", sub_id, "/fmri/", model)
  
  # create the dir where all the mat files (and the stats.feat) will be stored
  if (!dir.exists(dest)) {dir.create(dest)} else paste0(dest, " exists")
  paste0("Creating .mat files for sub", sub_id, " in ", dest) %>% print
  
  # write all .mat files (one for each run) for that sub
  runs %>% walk(~ read_onsets_write_mat(sub_id = sub_id, run_id = .x, dest = dest))
}




