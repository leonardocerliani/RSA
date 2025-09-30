
# Produces a list that will be passed to the function rsa_stats_table(file_path, atlas, label)
# Accepts one of Yeo7, Yeo17, HO_cort, anatomy_toolbox_for_RSA
make_rdata_list <- function(atlas_name) {
  # Define all possible filename patterns
  files <- c(
    paste0(atlas_name, "_N26__EER.RData"),
    paste0(atlas_name, "_N26_filtered_EER.RData"),
    paste0(atlas_name, "_N26_res_EER.RData"),
    paste0(atlas_name, "_N26_res_filtered_EER.RData")
  )
  
  # Define corresponding labels
  labels <- c("original", "filtered", "res", "res_filtered")
  
  # Build list of lists
  rdata_list <- map2(files, labels, ~ list(file = .x, atlas = atlas_name, label = .y))
  
  rdata_list
}



# Runs all the ttest and ttestBF and returns them in a df
rsa_stats_table <- function(file_path, atlas, label) {
  
  # Internal helper to load the RData
  load_RData <- function(file_path) {
    local({
      load(file_path)  # assumes object inside is named RSA
      RSA %>% dplyr::select(sub, roi, dplyr::starts_with('rsa'))
    })
  }
  
  # Load the data
  df <- load_RData(file_path)
  
  # Detect RSA columns
  rsa_cols <- grep("^rsa_rdm", names(df), value = TRUE)
  roi_list <- unique(df$roi)
  
  # Iterate over ROIs
  results <- map_dfr(roi_list, function(r) {
    df_roi <- df %>% filter(roi == r)
    
    # One-sample t-tests
    t_tests <- map(rsa_cols, function(col) {
      t_res <- t.test(df_roi[[col]])
      bf_res <- ttestBF(df_roi[[col]], mu = 0)
      bf01 <- 1 / as.vector(bf_res)  # correct BF01
      
      paste0("T=", round(t_res$statistic, 2),
             ", p=", round(t_res$p.value, 3),
             ", BF01=", round(bf01, 2))
    })
    names(t_tests) <- paste0(gsub("rsa_rdm_", "", rsa_cols), "_vs_0")
    
    # Paired comparisons
    combs <- combn(rsa_cols, 2, simplify = FALSE)
    paired_tests <- map(combs, function(pair) {
      t_res <- t.test(df_roi[[pair[1]]], df_roi[[pair[2]]], paired = TRUE)
      bf_res <- ttestBF(df_roi[[pair[1]]], df_roi[[pair[2]]], paired = TRUE)
      bf01 <- 1 / as.vector(bf_res)
      
      paste0("T=", round(t_res$statistic, 2),
             ", p=", round(t_res$p.value, 3),
             ", BF01=", round(bf01, 2))
    })
    names(paired_tests) <- map_chr(combs, ~ paste0(gsub("rsa_rdm_", "", .x[1]),
                                                   "_vs_",
                                                   gsub("rsa_rdm_", "", .x[2])))
    
    tibble(
      atlas = atlas,   # NEW: first column
      roi = r,
      label = label,
      !!!t_tests,
      !!!paired_tests
    )
  })
  
  results
}



# Build the gt_table based on the results of rsa_stats_table
make_rsa_gt_table_colored <- function(results, roi_filter = NULL) {
  
  # Optionally filter ROIs
  if (!is.null(roi_filter)) {
    results <- results %>% filter(roi %in% roi_filter)
  }
  
  # Ensure atlas, roi, label are first columns
  results <- results %>% select(atlas, roi, label, everything()) %>% 
    mutate(roi_group = paste0("ROI ", roi))
  
  # Build initial gt table, grouped by ROI
  gt_table <- results %>%
    gt(groupname_col = "roi_group") %>%
    tab_header(
      title = "RSA Summary Table",
      subtitle = "T-tests and Bayes Factors per ROI"
    ) %>%
    cols_label(
      atlas = "ROI/Atlas",
      label = "RSA flavour",
      emotion_vs_0 = "Emotion ≠ 0",
      aroval_vs_0 = "AroVal ≠ 0",
      arousal_vs_0 = "Arousal ≠ 0",
      emotion_vs_arousal = "Emotion ≠ Arousal",
      emotion_vs_aroval = "Emotion ≠ AroVal",
      arousal_vs_aroval = "AroVal ≠ Arousal"
    ) %>%
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_column_labels(everything())
    ) %>%
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_row_groups()
    ) %>%
    tab_style(
      style = cell_text(weight = "bold", size = px(16)),
      locations = cells_title(groups = "title")
    ) %>%
    tab_style(
      style = cell_text(weight = "bold", size = px(14)),
      locations = cells_title(groups = "subtitle")
    ) %>%
    tab_options(
      table.font.size = px(12),
      heading.title.font.size = px(16),
      heading.subtitle.font.size = px(14)
    )
  
  # Apply colored text based on p < 0.05 (green) and BF01 > 3 (blue)
  for (col_name in names(results)[-(1:3)]) {  # skip atlas, roi, label
    # green text for p < 0.05
    rows_green <- which(as.numeric(str_extract(results[[col_name]], "(?<=p=)[0-9\\.e-]+")) < 0.05)
    if (length(rows_green) > 0) {
      gt_table <- gt_table %>%
        tab_style(
          style = cell_text(color = "darkgreen", weight = "bold"),
          locations = cells_body(columns = all_of(col_name), rows = rows_green)
        )
    }
    
    # blue text for BF01 > 3
    rows_blue <- which(as.numeric(str_extract(results[[col_name]], "(?<=BF01=)[0-9\\.e-]+")) > 3)
    if (length(rows_blue) > 0) {
      gt_table <- gt_table %>%
        tab_style(
          style = cell_text(color = "darkblue", weight = "bold"),
          locations = cells_body(columns = all_of(col_name), rows = rows_blue)
        )
    }
  }
  
  gt_table
}







