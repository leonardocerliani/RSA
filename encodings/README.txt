
The table movie_encodings.csv contains 4 columns:
original_code	high_low_code	actor	emotion

It was created starting from the movie_encoding_OLE.csv and applying the following R code

movie_encodings_table %>% 
  mutate(tmp_original_code = original_code) %>% 
  separate(tmp_original_code, into = c("actor", "emotion", "movie_recording_number"), sep = "_") %>% 
  mutate(emotion = case_when(
   emotion == "A" ~ "anger",
   emotion == "D" ~ "disgust",
   emotion == "F" ~ "fear",
   emotion == "H" ~ "happy",
   emotion == "N" ~ "neutral",
   emotion == "P" ~ "pain",
   emotion == "S" ~ "sad",
   TRUE ~ as.character(emotion)  # If none of the above, keep the original value
  )) %>% 
  select(-movie_recording_number)



