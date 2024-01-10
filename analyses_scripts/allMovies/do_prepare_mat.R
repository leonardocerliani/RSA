
# Reads the onsets.csv file in the raw_data folder and writes
# the prep_data/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}.mat file
# which will be used in the first-level feat.
# It cycles through all subs and all runs for each sub
# run with Rscript do_prepare_mat.R

# Load library and define initial variables

library(tidyverse)

subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

model="allMovies"

nRuns = 8
runs <- as.character(1:nRuns)


# Function that reads the onsets.csv file and writes the .mat files
read_onsets_write_mat <- function(sub, run, dest) {
  # Read the onset file for that run
  sub_onsets_file <- paste0(orig_csv_root,
                            "/sub-", sub,
                            "/onsets/sub-", sub,"_Ins_onsets_allmovies_run-", run, ".csv")
  
  df <- read_csv(sub_onsets_file, progress = F) %>% suppressMessages()
  colnames(df) = c("movie_number", "onset_sec", "duration", "movie_code")
  
  # Write a three column .mat file for feat
  # (1) onset, (2) duration, (3) intensity
  mat_4_feat <- df %>% 
    select(onset_sec, duration) %>% 
    mutate(onset_sec = round(onset_sec, 2)) %>% 
    arrange(onset_sec)
  
  mat_4_feat$intensity = 1
  # mat_4_feat %>% print
  
  mat_path <- paste0(dest, "/sub-", sub, "_run-", run, ".mat")
  
  write_tsv(mat_4_feat, col_names = FALSE, mat_path)
}

# # example: write all .mat files (one for each run) for one sub
# as.character(1:8) %>% map(~ read_onsets_write_mat(sub, run = .x, dest = dest))



# Loops across subs and runs
# I use a `for` construct for subjects since two nested `map` can be difficult to read 

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

