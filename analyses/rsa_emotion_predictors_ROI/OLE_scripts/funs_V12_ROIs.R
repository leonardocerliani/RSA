

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


# ---------- Plot_heatmap(D %>% as.matrix) ---------------
plot_heatmap <- function(M) {
  heatmap(M, Rowv = NA, Colv = NA, symm=T, revC = T)
}


# ----------- Plot full matrix from tril -----------------
# copes_numba : vector of copes number, e.g c(1,2,3...56)
# metadata_copes : a df containing the emtion and label (original code) for one sub
# model : for the title (e.g. "emotion")
# library(devtools)
# install_github("jokergoo/ComplexHeatmap")
# # https://github.com/jokergoo/ComplexHeatmap
plot_tril <- function(tril, model, source_copes_info=df_path_copes, 
                          reord = TRUE, fontsize = 6, side_mm=100) {
  
  # Get metadata about n_copes and - potentially - about neutral removal
  # by selecting one sub from df_path_copes
  copes_info <- source_copes_info %>% filter(sub == subs[1])
  n_copes <- length(copes_info$cope)
  
  # Create a full symmetric matrix from the lower triangular input
  full_matrix <- matrix(0, n_copes, n_copes)
  full_matrix[lower.tri(full_matrix, diag = FALSE)] <- unlist(tril)
  full_matrix <- full_matrix + t(full_matrix)
  
  # demean
  full_matrix <- full_matrix - mean(full_matrix)
  
  # # reduce range to -1..1
  # full_matrix <- full_matrix / max(abs(full_matrix))
  
  # Set diagonal to NA
  diag(full_matrix) <- NA
  
  # assign row/col names/labels
  rownames(full_matrix) <- copes_info$label
  colnames(full_matrix) <- copes_info$label

  # Define the color map
  color_map <- colorRamp2(c(min(full_matrix, na.rm = TRUE), 
                            0, 
                            max(full_matrix, na.rm = TRUE)), 
                          c("blue", "white", "red"))
  
  
  # Create the heatmap
  ht <- Heatmap(full_matrix, 
                column_title = model,
                rect_gp = gpar(col = "white", lwd = 1),
                col = color_map, cluster_rows = reord, cluster_columns = reord, 
                show_row_dend = reord, show_column_dend = reord, 
                heatmap_legend_param = list(title = model),
                width =  unit(side_mm, "mm"), 
                height = unit(side_mm, "mm"),
                row_names_side = "left",  # Display row names on the left
                column_names_side = "top",  # Display column names on the top
                column_names_rot = 60,  # Slant column names at 60 degrees
                row_names_gp = gpar(fontsize = fontsize),  # Set row names font size to 8
                column_names_gp = gpar(fontsize = fontsize))  # Set column names font size to 8
  
  return(ht)
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
  
  # Replace NA values with 0
  X[is.na(X)] <- 0
  
  # Demean each column
  X <- scale(X, center = TRUE, scale = FALSE)
  
  # Calculate the distance or similarity
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






# Loads the nii.gz for all n copes for one sub, and returns a df of (91x109x91) rows
# and n (length(copes_numba)) columns, each one named with the cope numba
#
# Test with
# sub_id = "02"
# df_copes <- load_sub_copes(sub_id, copes_numba, df_path_copes)

load_sub_copes <- function(sub_id, copes_numba, df_path_copes) {

  copes_numba %>% map_dfc(~ {
    nii <- df_path_copes %>%
      filter(sub == sub_id, cope == .x) %>%
      select(path) %>% pull %>%
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
  




