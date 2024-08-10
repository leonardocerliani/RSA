

# bd="/data00/leonardo/RSA/analyses"
# 
# ratings_type <- "emotion"
# copes_type <- "one_ev_per_movie"
# atlas_filename <-  "juelich_2mm.nii.gz"
# dist_method_rating <- "Euclidean"
# 
# # Vector of zeropadded sub_ids
# subs_file <- "/data00/leonardo/RSA/sub_list.txt"
# subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)


# ----------- Plot full matrix from tril -----------------
plot_tril <- function(tril, n_copes, reord="NO") {
  full_matrix <- matrix(0, n_copes, n_copes)
  full_matrix[lower.tri(full_matrix, diag = FALSE)] <- unlist(tril)
  full_matrix <- full_matrix + t(full_matrix)
  
  if (reord == "YES") {
    heatmap(full_matrix, scale = "none", 
            symm = T, revC = T, 
            col = colorRampPalette(c("blue", "white", "red"))(100))  
  } else {
    heatmap(full_matrix, Rowv = NA, Colv = NA, scale = "none", 
            symm = T, revC = T, 
            col = colorRampPalette(c("blue", "white", "red"))(100))
  }
  
  
}



# ----------- DDOS - Do Distance Or Similarity -----------
# The input matrix should be observations-by-variables, that is:
# - rows index observations
# - columns index variables
# This is the format required by dist(), while for cor() is the
# opposite, so when using the cor() function we pass t(X) 
#
# example usage:
# DDOS(Y, method = "cosine")
#
# Output : vector with the tril of the D[n,n] matrix of length (n^2 - n)/2 
DDOS_vec <- function(X, method) {
  
  X[is.na(X)] = 0
  
  switch(method,
         pearson = {
           D <- 1 - cor(t(X), method = "pearson") %>% as.dist()
         },
         
         spearman = {
           D <- 1 - cor(t(X), method = "spearman") %>% as.dist()
         },
         
         euclidean = {
           D <- dist(X, method = "euclidean")
         },
         
         cosine = {
           D <- 1 - simil(X, method = "cosine")
         },
         
         mahalanobis = {
           D <- dist(X, method = "mahalanobis")
         },
         stop("Supported methods: 'pearson', 'spearman', 'euclidean', 'cosine' or 'mahalanobis'.")
  )
  return(D[!is.na(D)])
}




#  ------ Create a copes_location.csv file using dplyr::separate ----------
import_df_path_copes <- function(bd, copes_type, rsa_flavour) {
  
  bd_copes = paste0(bd, "/",copes_type,"/results/2nd_level")
  
  df_path_copes <- list.files(bd_copes, recursive = T) %>% tibble()
  names(df_path_copes) <- "fname"
  
  df_path_copes <- df_path_copes %>%
    filter(str_detect(fname, "gfeat/cope[0-9]+.feat/stats/cope")) %>%
    tidyr::separate(
      fname, c("sub","cope","tmp1","tmp2"),
      sep = "/", fill = "right", remove = F
    ) %>% 
    select(!starts_with("tmp")) %>% 
    mutate(sub = str_extract(sub, "[0-9]+")) %>% 
    mutate(cope = (str_extract(cope, "[0-9]+") %>% as.numeric) ) %>% 
    mutate(path = paste0(bd_copes,"/",fname)) %>% 
    select(!fname) %>% 
    arrange(sub,cope)
  
  write_csv(df_path_copes, paste0(bd,"/",rsa_flavour,"/copes_location.csv"))
  
}






# Loads the nii for all 56 copes for one sub, and returns a df of (91x109x91) rows
# and 56 (length(copes_numba)) columns, each one named with the cope numba
#
# Test with
# sub_id = "02"
# df_copes <- load_sub_copes(sub_id, copes_numba, df_path_copes)
load_sub_copes <- function(sub_id, copes_numba, df_path_copes) {
  
  copes_numba %>% map_dfc(~ {
    nii <- df_path_copes %>% 
      filter(sub == sub_id, cope == .x) %>% pull %>%  
      readNifti %>% as.vector
    
    tibble(!!paste0("cope_", .x) := nii)
  })
  
}





# Function to construct the filename of the rsa results
create_filename_results <- function(atlas_filename, ratings_type, dist_method_rating, dist_method_fmri, dist_method_rsa) {
  
  code_methods <- list(
    "euclidean" = "E",
    "mahalanobis" = "M",
    "cosine" = "C",
    "pearson" = "R",
    "spearman" = "S"
  )
  
  atlas_root <- str_replace(atlas_filename, ".nii.gz", "")
  
  results_filename <- paste0(
    "rsa", "_",
    atlas_root, "_",
    ratings_type, "_",
    code_methods[[dist_method_rating]],
    code_methods[[dist_method_fmri]],
    code_methods[[dist_method_rsa]],
    ".nii.gz"
  )
  
  return(results_filename)
  
}

# create_filename_results(
#   atlas_filename, ratings_type, dist_method_rating, dist_method_fmri, dist_method_rsa
# )
  




