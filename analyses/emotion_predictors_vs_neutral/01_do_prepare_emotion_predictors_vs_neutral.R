
# Load library and define initial variables
library(tidyverse)

subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

model="emotion_predictors_vs_neutral"
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
    select(emotion, onset_sec, duration, intensity) %>% 
    rename(mat_filename = emotion) %>% 
    arrange(mat_filename,onset_sec)
  
  # Write every mat file (in this case it will be one line per mat file)
  for (movie in unique(df_4_mat$mat_filename) ) {
    
    mat_file_path <- paste0(dest,"/sub-",sub_id,"_run-",run_id,"_",movie,".mat")
    paste0(mat_file_path,"\n") %>% cat
    
    mat_file_3_cols <- df_4_mat %>%
      filter(mat_filename == movie) %>%
      select(!mat_filename) %>%
      write_tsv(col_names = FALSE, mat_file_path)
    
  }
}



# Loops across subs and runs
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




