

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





# ----------- DDOS - Do Distance Or Similarity -----------
# The input matrix should be observations-by-variables, that is:
# - rows index observations
# - columns index variables
# This is the format required by dist(), while for cor() is the
# opposite, so when using the cor() function we pass t(X) 

DDOS <- function(X, method) {
  
  X[is.na(X)] = 0
  
  switch(method,
         pearson = {
           D <- cor(t(X), method = "pearson") %>% as.dist()
         },
         
         spearman = {
           D <- cor(t(X), method = "spearman") %>% as.dist()
         },
         
         euclidean = {
           D <- dist(X, method = "euclidean")
         },
         
         cosine = {
           D <- simil(X, method = "cosine")
         },
         
         mahalanobis = {
           D <- dist(X, method = "mahalanobis")
         },
         stop("Supported methods: 'pearson', 'spearman', 'euclidean', 'cosine' or 'mahalanobis'.")
  )
  return(D)
}

# # example usage:
# DDOS(Y, method = "cosine")




#  ------ Create a copes_location.csv file using dplyr::separate ----------
import_df_path_copes <- function(bd, copes_type) {
  
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
  
  write_csv(df_path_copes, paste0(bd,"/rsa/copes_location.csv"))
  
}


# ------------------- Ratings RDM calculation --------------------

# # Function to calculate the ratings RDM for one sub
# sub_id = "02"
# dist_method_rating <- "Euclidean"
# rats <- read_csv(ratings_path)
# ncomp_svd = 3

do_RDM_ratings_one_sub <- function(sub_id, dist_method_rating, rats, RDM_type = "tril") {
  
  rats_one_sub <- rats %>% 
    filter(sub == sub_id) %>% 
    select(starts_with("r_"))
  
  D_rats <- DDOS(rats_one_sub, method = dist_method_rating)
  D_rats[is.na(D_rats)] <- 0
  
  # calculate RDM as tril of the D matrix
  if (RDM_type == "tril") {
    D_feature_vector <- D_rats[!is.na(D_rats)]
  } else 
    
  # calculate RDM as the first 3 pc of the svd of the D_matrix
  if (RDM_type == "svd") {
    D_rats_full <- D_rats %>% as.matrix()
    svd_result <- svd(D_rats_full)
    U <- svd_result$u
    S <- svd_result$d[1:ncomp_svd]
    # pc <- U[,1:ncomp_svd] %*% diag(S)
    pc <- U[,1:ncomp_svd]
    D_feature_vector <- pc %>% as.vector()
  }
  
  D_feature_column <- tibble(!!sub_id := D_feature_vector)
  return(D_feature_column)
  
}

# # Test it with the following
# rating_RDM_onesub <- do_RDM_ratings_one_sub(subs[1], dist_method_rating, rats, RDM_type = "svd")
# dim(rating_RDM_onesub)

# # This function will be purrred across subs in the main script:
# RDMs_rats <- subs %>% map_dfc(~ {
#   do_RDM_ratings_one_sub(.x, dist_method_rating, rats, RDM_type = "svd")
# }) %>% 
#   pivot_longer(cols = everything(), names_to = "sub") %>% 
#   arrange(sub)
# 
# RDMs_rats



# ------------------- fMRI RDM calculation --------------------
# 
# The following two functions will be purrred across subs


# 1. Load the copes for that sub
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


# 2. Calculate the RDM for each atlas region
# Read atlas and calculate fmri RDMs : the final df has size lenght(tril_D-by-n_regions)
# (or length(svd_pc1..3) if the svd method was used)
# where :
# - n_tril_D : number of elements in the distance matrix = ((56^2)-56)/2 = 1540
# - n_regions : number of distinctly labelled regions in the atlas

# dist_method_fmri = "euclidean"
# ncomp_svd = 3

calculate_fmri_RDMs <- function(df_copes, atlas_nii, dist_method_fmri, RDM_type = "tril") {
  
  # Calculate the RDM for each atlas region, 
  # i.e. distance matrix of the betas of each movie across all voxels in that ROI.
  # Returns a df of length(triu(D))-by-n_atlas_regions
  region_labels %>% map_dfc(~ {
    idx <- which(atlas_nii == .x)
    df_copes_region <- df_copes[idx, ]
    
    # # center (i.e. demean) variables
    # df_copes_region_demean <- df_copes_region %>% 
    #   mutate(across(everything(), ~ .x - mean(.x)))
    
    # center (i.e. demean) variables
    # (treat also the case of single voxels)
    if(nrow(df_copes_region) > 1) {
      df_copes_region_demean <- df_copes_region %>% 
        mutate(across(everything(), ~ .x - mean(.x)))  
    } else {
      df_copes_region_demean <- df_copes_region
    }
    
    # calculate distance / similarity
    D_fmri <- DDOS( t(df_copes_region_demean), method = dist_method_fmri )
    D_fmri[is.na(D_fmri)] <- 0
    
    # calculate RDM as tril of the D matrix
    if (RDM_type == "tril") {
      D_feature_vector <- D_fmri[!is.na(D_fmri)]
    } else
      
      # calculate RDM as the first 3 pc of the svd of the D_matrix
      if (RDM_type == "svd") {
        D_fmri_full <- D_fmri %>% as.matrix()
        svd_result <- svd(D_fmri_full)
        U <- svd_result$u
        S <- svd_result$d[1:ncomp_svd]
        # pc <- U[,1:ncomp_svd] %*% diag(S)
        pc <- U[,1:ncomp_svd]
        D_feature_vector <- pc %>% as.vector()     
      } 
    
    D_feature_column <- tibble(!!paste0("RDM_region_", .x) := D_feature_vector)
  })
}










