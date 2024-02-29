# Reads the onsets.csv file in the raw_data folder and writes
# the prep_data/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}.mat file
# which will be used in the first-level feat.
# It cycles through all subs and all runs for each sub
# run with Rscript 01_do_prepare_mat_arousal.R


# Load library and define initial variables
library(tidyverse)

subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

model="arousal"
movie_duration = 1.5 # (seconds)

# read ratings and zeropad the sub number
# remove the onset_sec - the onset in the out-of-scanner session
# not to generate confusion with the onset_sec column in the 
# onset.csv file (onsets inside the scanner)
ratings <- read_csv(
  paste0(
    "/data00/leonardo/RSA/analyses/RATINGS", "/", model, "_ratings.csv"
  )
)

ratings

nRuns = 8
runs <- 1:nRuns

runs

# In the posttask movies were presented only once, but we need to create .mat files
# for 8 runs, therefore we cp/paste all the rows 8 times
ratings_all_runs <- runs %>% map_dfr(
  ~ ratings %>% mutate(run = .x) %>% relocate(sub,run)
)


# Inner join the fmri log and the rating by high_low_code 
# For each sub and run separately, so that we can then purrr the function

read_onsets_write_mat <- function(sub_id, run_id, dest, show_test = FALSE) {
  
  sub_onsets_file <- paste0(orig_csv_root,
                            "/sub-", sub_id,
                            "/onsets/sub-", sub_id, "_onset_run",run_id,".csv")
  
  # NB: the sub in fmri_log is read from a csv and assigned to dbl for numbers
  # above 09, however I need to join it with the sub in ratings_all_runs
  # which is a char, therefore I need to change the datatype of that column
  fmri_log <- read_csv(sub_onsets_file, progress = F) %>% suppressMessages() %>% 
    mutate(sub = as.character(sub))
  
  joined_ratings_fmri_logs <- ratings_all_runs %>% 
    filter(sub == sub_id, run == run_id) %>% 
    select(sub, run, starts_with("r_"), high_low_code) %>% 
    inner_join(fmri_log, by = c("sub","run","high_low_code"))
  
  # select onset_sec, duration and intensity to prepare the .mat file
  mat_4_feat <- joined_ratings_fmri_logs %>% 
    mutate(duration = movie_duration) %>% 
    select(onset_sec, duration, starts_with("r_")) %>% 
    arrange(onset_sec)
  
  # write the .mat file for that sub and run
  mat_path <- paste0(dest, "/sub-", sub_id, "_run-", run_id, ".mat")
  write_tsv(mat_4_feat, col_names = FALSE, mat_path)
  
  # testing that same movies have same rating across runs but
  # different onset_sec
  if (show_test == TRUE) {
    test_onset_rating <- joined_ratings_fmri_logs %>% 
      mutate(duration = movie_duration) %>% 
      select(high_low_code, onset_sec, duration, starts_with("r_")) %>% 
      print()  
  }
  
}


# Loops across subs and runs
# I use a `for` construct for subjects since two nested `map` can be difficult to read 

for (sub_id in subs) {
  
  orig_csv_root = "/data00/leonardo/RSA/raw_data"
  dest = paste0("/data00/leonardo/RSA/prep_data/sub-", sub_id, "/fmri/", model)
  
  # create the dir where all the mat files (and the stats.feat) will be stored
  if (!dir.exists(dest)) {dir.create(dest)} else paste0(dest, " exists")
  paste0("Creating .mat files for sub", sub_id, " in ", dest) %>% print
  
  # write all .mat files (one for each run) for that sub
  runs %>% walk(~ read_onsets_write_mat(sub = sub_id, run = .x, dest = dest, show_test = F))
}

























