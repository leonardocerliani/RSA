# ============================================================================
# Functions for Crossnobis RSA Analysis (V15 CROSSNOBIS)
# ============================================================================
# 
# This file contains adapted functions from funs_V15_ROIs.R
# specifically for crossnobis distance computation.
#
# Main differences from V15:
# - df_path_copes now includes 'run' column (8 runs × 14 copes = 112 files/sub)
# - load_sub_copes handles 3D structure (voxels × runs × copes)
# - DDOS_crossnobis implements leave-one-run-out Mahalanobis distance
# ============================================================================


library(tidyverse)
library(RNifti)
library(proxy)
library(ComplexHeatmap)
library(circlize)


# ============================================================================
# GENERAL FUNCTIONS (from V15 - used for behavioral RDMs)
# ============================================================================

# Custom Mahalanobis distance function for proxy::dist
mahal_custom <- function(x, y, Sigma) {
  delta <- x - y
  sqrt(t(delta) %*% Sigma %*% delta)
}

# Default Mahalanobis option
mahalanobis_flavour <- 'identity'  # 'identity' or 'pseudo'


#' DDOS_vec: Compute distances or similarities between observations
#'
#' Output: vector with the tril of the D[n,n] matrix of length (n^2 - n)/2
#'
DDOS_vec <- function(X,
                     method = c("pearson", "spearman", "euclidean", "cosine", "mahalanobis"),
                     mahal_option = mahalanobis_flavour) {

  method <- match.arg(method)
  mahal_option <- match.arg(mahal_option)

  # Replace NA values with 0
  X[is.na(X)] <- 0

  # Demean columns
  X <- scale(X, center = TRUE, scale = FALSE)

  D <- switch(method,
              pearson    = 1 - cor(t(X), method = "pearson") %>% as.dist(),
              spearman   = 1 - cor(t(X), method = "spearman") %>% as.dist(),
              euclidean  = dist(X, method = "euclidean"),
              cosine     = 1 - simil(X, method = "cosine"),
              mahalanobis = {
                # Compute covariance
                Sigma <- cov(X)
                # Try solving; fallback if singular
                Sigma_inv <- tryCatch(
                  solve(Sigma),
                  error = function(e) {
                    message("Covariance singular: using fallback")
                    if (mahal_option == "identity") diag(ncol(X))
                    else MASS::ginv(Sigma)
                  }
                )
                # Compute all pairwise Mahalanobis distances
                proxy::dist(X, method = mahal_custom, Sigma = Sigma_inv)
              },
              stop("Supported methods: 'pearson', 'spearman', 'euclidean', 'cosine', or 'mahalanobis'")
  )

  return(D[!is.na(D)])
}


# ---------- Plot_heatmap(D %>% as.matrix) ---------------
plot_heatmap <- function(M) {
  heatmap(M, Rowv = NA, Colv = NA, symm=T, revC = T)
}


# ----------- Plot full matrix from tril -----------------
plot_tril <- function(tril, model, source_copes_info=df_path_copes, 
                      reord = TRUE, fontsize = 6, side_mm=100) {
  
  # Get metadata about n_copes from df_path_copes (one sub, all copes)
  copes_info <- source_copes_info %>% 
    filter(sub == subs[1]) %>% 
    distinct(cope, .keep_all = TRUE)
  
  n_copes <- length(unique(copes_info$cope))
  
  # Create a full symmetric matrix from the lower triangular input
  full_matrix <- matrix(0, n_copes, n_copes)
  full_matrix[lower.tri(full_matrix, diag = FALSE)] <- unlist(tril)
  full_matrix <- full_matrix + t(full_matrix)
  
  # demean
  full_matrix <- full_matrix - mean(full_matrix)
  
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
                row_names_side = "left",
                column_names_side = "top",
                column_names_rot = 60,
                row_names_gp = gpar(fontsize = fontsize),
                column_names_gp = gpar(fontsize = fontsize))
  
  return(ht)
}


# ============================================================================
# CROSSNOBIS-SPECIFIC FUNCTIONS
# ============================================================================


#' Import df_path_copes for crossnobis analysis
#'
#' Constructs paths directly for run-level cope files and checks existence.
#' Much faster than recursive scanning.
#'
#' @param bd_copes Base directory for first-level copes
#' @param subs Vector of subject IDs (e.g., c("02", "03", ...))
#' @param runs Vector of run numbers (default: 1:8)
#' @param copes Vector of cope numbers (default: 1:14)
#' @return A tibble with columns: sub, run, cope, path
#'
#' Expected path structure:
#' /data01/.../sub-XX/fmri/emotion_high_low_predictors/sub-XX_run-N_preproc_reg.feat/reg_standard/stats/copeM.nii.gz
#'
import_df_path_copes_crossnobis <- function(bd_copes, subs, runs = 1:8, copes = 1:14) {
  
  cat("Constructing paths for first-level cope files...\n")
  cat("(This may take a few seconds to check file existence)\n")
  
  # Construct all possible paths using expand_grid
  df_path_copes <- expand_grid(
    sub = subs,
    run = runs,
    cope = copes
  ) %>%
    mutate(
      path = sprintf(
        "%s/sub-%s/fmri/emotion_high_low_predictors/sub-%s_run-%d_preproc_reg.feat/reg_standard/stats/cope%d.nii.gz",
        bd_copes, sub, sub, run, cope
      )
    ) %>%
    # Check which files actually exist
    mutate(exists = file.exists(path)) %>%
    # Keep only existing files
    filter(exists) %>%
    select(sub, run, cope, path) %>%
    arrange(sub, run, cope)
  
  cat("\n=== PATH CONSTRUCTION COMPLETE ===\n")
  cat("Found", nrow(df_path_copes), "cope files\n")
  cat("Subjects:", length(unique(df_path_copes$sub)), "\n")
  cat("Runs:", paste(range(runs), collapse = "-"), "\n")
  cat("Copes:", paste(range(copes), collapse = "-"), "\n")
  cat("Expected per subject:", length(runs) * length(copes), "\n")
  
  # Show file count per subject
  cat("\nFiles per subject:\n")
  df_path_copes %>%
    count(sub) %>%
    print(n = Inf)
  
  return(df_path_copes)
}


#' Load all copes for one subject across all runs
#'
#' Loads all run-level cope files for one subject and organizes them
#' as a 3D array: voxels × runs × copes
#'
#' @param sub_id Subject ID (e.g., "02")
#' @param runs_numba Vector of run numbers (e.g., 1:8)
#' @param copes_numba Vector of cope numbers (e.g., 1:14)
#' @param df_path_copes Dataframe with cope locations
#' @return A 3D array with dimensions (n_voxels, n_runs, n_copes)
#'
load_sub_copes_crossnobis <- function(sub_id, runs_numba, copes_numba, df_path_copes) {
  
  cat("Loading copes for subject", sub_id, "...\n")
  
  # Get all paths for this subject
  sub_paths <- df_path_copes %>%
    filter(sub == sub_id) %>%
    arrange(run, cope)
  
  # Load first file to get dimensions
  first_nii <- readNifti(sub_paths$path[1])
  n_voxels <- length(as.vector(first_nii))
  n_runs <- length(runs_numba)
  n_copes <- length(copes_numba)
  
  # Initialize 3D array: voxels × runs × copes
  data_array <- array(NA, dim = c(n_voxels, n_runs, n_copes))
  
  # Load all files
  for (i in seq_len(nrow(sub_paths))) {
    run_idx <- which(runs_numba == sub_paths$run[i])
    cope_idx <- which(copes_numba == sub_paths$cope[i])
    
    nii_vec <- readNifti(sub_paths$path[i]) %>% as.vector()
    data_array[, run_idx, cope_idx] <- nii_vec
  }
  
  cat("  Loaded", n_runs, "runs ×", n_copes, "copes =", n_runs * n_copes, "files\n")
  
  return(data_array)
}


#' DDOS_crossnobis: Crossnobis distance computation
#'
#' Computes crossnobis distance using leave-one-run-out cross-validation
#' with Mahalanobis distance. For each fold, one run is held out as test
#' and the remaining runs are used to estimate the covariance matrix.
#'
#' @param X_roi 3D array for one ROI: voxels × runs × copes
#' @param cov_method Method for covariance estimation: "shrinkage" or "pseudoinverse"
#' @return Lower triangular distance vector (length = n_copes * (n_copes - 1) / 2)
#'
DDOS_crossnobis <- function(X_roi, cov_method = "shrinkage") {
  
  n_voxels <- dim(X_roi)[1]
  n_runs <- dim(X_roi)[2]
  n_copes <- dim(X_roi)[3]
  
  # Initialize distance matrix to accumulate across folds
  D_sum <- matrix(0, n_copes, n_copes)
  
  # Leave-one-run-out cross-validation
  for (fold in 1:n_runs) {
    
    # Test run: held-out run (voxels × copes)
    test_run <- X_roi[, fold, , drop = FALSE]
    test_data <- test_run[, 1, ]  # voxels × copes
    
    # Training runs: all except the held-out run (voxels × remaining_runs × copes)
    train_runs <- X_roi[, -fold, , drop = FALSE]
    
    # Average training runs across the run dimension for each cope
    # Result: voxels × copes
    train_avg <- apply(train_runs, c(1, 3), mean)
    
    # Compute residuals for covariance estimation
    # For each training run, subtract the mean
    train_residuals <- array(NA, dim = c(n_voxels, n_runs - 1, n_copes))
    for (r in 1:(n_runs - 1)) {
      train_residuals[, r, ] <- train_runs[, r, ] - train_avg
    }
    
    # Flatten residuals to (n_samples × n_voxels) for covariance calculation
    # where n_samples = (n_runs - 1) * n_copes
    residuals_flat <- matrix(NA, nrow = (n_runs - 1) * n_copes, ncol = n_voxels)
    idx <- 1
    for (r in 1:(n_runs - 1)) {
      for (c in 1:n_copes) {
        residuals_flat[idx, ] <- train_residuals[, r, c]
        idx <- idx + 1
      }
    }
    
    # Estimate covariance matrix and compute inverse based on selected method
    if (cov_method == "shrinkage") {
      # Option 2: Ledoit-Wolf shrinkage covariance (as in rsatoolbox)
      Sigma_shrink <- corpcor::cov.shrink(residuals_flat, verbose = FALSE)
      Sigma_inv <- solve(Sigma_shrink)
      
    } else if (cov_method == "pseudoinverse") {
      # Option 3: Pseudoinverse (most robust, always works)
      Sigma <- cov(residuals_flat)
      Sigma_inv <- MASS::ginv(Sigma)
      
    } else {
      stop("cov_method must be either 'shrinkage' or 'pseudoinverse'")
    }
    
    # Compute pairwise Mahalanobis distances between test copes
    # test_data is voxels × copes, need to transpose for distance calculation
    D_fold <- matrix(0, n_copes, n_copes)
    for (i in 1:(n_copes - 1)) {
      for (j in (i + 1):n_copes) {
        delta <- test_data[, i] - test_data[, j]
        D_fold[i, j] <- sqrt(as.numeric(t(delta) %*% Sigma_inv %*% delta))
        D_fold[j, i] <- D_fold[i, j]  # symmetric
      }
    }
    
    # Accumulate distances
    D_sum <- D_sum + D_fold
  }
  
  # Average across folds
  D_avg <- D_sum / n_runs
  
  # Extract lower triangular part as vector
  rdm_vector <- D_avg[lower.tri(D_avg)]
  
  return(rdm_vector)
}


#' Calculate crossnobis RDM for one subject
#'
#' Orchestrates the crossnobis RDM calculation for one subject across all ROIs
#'
#' @param sub_id Subject ID (e.g., "02")
#' @param runs_numba Vector of run numbers (e.g., 1:8)
#' @param copes_numba Vector of cope numbers (e.g., 1:14)
#' @param df_path_copes Dataframe with cope locations
#' @param atlas_nii Atlas NIfTI object
#' @param region_labels Vector of unique region labels in the atlas
#' @param cov_method Method for covariance estimation: "shrinkage" or "pseudoinverse"
#' @return Tibble with sub, roi, and rdm_fmri columns
#'
do_RDM_fmri_crossnobis <- function(sub_id, runs_numba, copes_numba, df_path_copes, atlas_nii, region_labels, cov_method = "shrinkage") {
  
  # Load all copes for this subject (3D array: voxels × runs × copes)
  data_array <- load_sub_copes_crossnobis(sub_id, runs_numba, copes_numba, df_path_copes)
  
  # Calculate RDM for each ROI
  one_sub_RDM_fmri <- tibble(
    sub = sub_id,
    roi = region_labels
  ) %>%
    
    # Extract voxel indices for each ROI
    mutate(idx_roi = roi %>% map(~ which(atlas_nii == .x))) %>%
    
    # Extract data for voxels in this ROI (creates 3D array: roi_voxels × runs × copes)
    mutate(data_roi = idx_roi %>% map(~ data_array[.x, , , drop = FALSE])) %>%
    
    # Calculate crossnobis RDM for this ROI using the specified covariance method
    mutate(rdm_fmri = data_roi %>% map(~ DDOS_crossnobis(.x, cov_method = cov_method))) %>%
    
    # Select only sub, roi, and rdm_fmri
    select(sub, roi, rdm_fmri)
  
  return(one_sub_RDM_fmri)
}


# ============================================================================
# UTILITY FUNCTIONS (copied from V15)
# ============================================================================


#' Create filename for results with appropriate codes
create_filename_results <- function(
    atlas_filename, 
    subs, 
    RSA_on_residuals, 
    filter_RDMs,
    dist_method_rating,
    dist_method_fmri,
    dist_method_rsa,
    bd_results
) {
  
  # Mapping from distance method names to single-letter codes
  code_methods <- list(
    "euclidean"   = "E",
    "mahalanobis" = "M",
    "cosine"      = "C",
    "pearson"     = "R",
    "spearman"    = "S",
    "crossnobis"  = "X"
  )
  
  # Strip the ".nii.gz" extension from atlas filename
  atlas_root <- sub("\\.nii\\.gz$", "", atlas_filename)
  
  # Optional codes
  residuals_code <- ifelse(RSA_on_residuals, "res", "")
  filter_code    <- ifelse(filter_RDMs, "filtered", "")
  
  # Number of subjects
  nsubs <- paste0("N", length(subs))
  
  # Distance codes
  dist_codes <- paste0(
    code_methods[[dist_method_rating]],
    code_methods[[dist_method_fmri]],
    code_methods[[dist_method_rsa]]
  )
  
  # Construct the final filename
  results_filename <- paste(
    atlas_root,
    nsubs,
    residuals_code,
    filter_code,
    dist_codes,
    sep = "_"
  )
  
  # Remove any double underscores
  results_filename <- gsub("__", "_", results_filename)
  
  # Full path
  file.path(bd_results, paste0(results_filename, ".RData"))
}
