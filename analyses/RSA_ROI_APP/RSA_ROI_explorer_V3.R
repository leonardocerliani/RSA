library(shiny)
library(tidyverse)
library(ggstatsplot)
library(reactable)
library(papayaWidget)
library(ComplexHeatmap)
library(circlize)  # For color mapping functions
library(grid)  # For gpar()
library(patchwork)

options(warn = -1)

# Define the path to your directory
bd="/data00/leonardo/RSA/analyses"
bd_atlases = paste0(bd,"/ROIS_REPO")
bd_results = paste0(bd,"/RSA_ROI_APP/results_RSA_ROI")

# clever way to make it so that the displayed name corresponds to a certain
# filename
results_files <- dir(bd_results, pattern = "RData")
results_files_display <- gsub("\\.RData$", "", results_files)
results_file_choices <- setNames(results_files, results_files_display)




ui <- fluidPage(
  # Link to the external CSS file
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$style(HTML("
      .no-margin-padding {
        margin: 0;
        padding: 0;
      }
    "))
  ),
  
  # Main layout with top and bottom sections using container-fluid to remove margins
  div(class = "container-fluid no-margin-padding", 
      
      # Top section with two columns
      div(class = "row top-section no-margin-padding",
          div(class = "col-sm-4 no-margin-padding", # Left column - 4 columns wide
              div(class = "row no-margin-padding",
                  div(class = "col-sm-6 no-margin-padding", # First half (6 columns)
                      selectInput("results_file", "Select results", choices = results_file_choices)
                  )
              ),
              reactableOutput("RSA_mean_table", height = "30vh"),
              tags$br(),
              reactableOutput("ttest_table"),
              tags$br()
          ),
          div(class = "col-sm-8 no-margin-padding", # Right column - 8 columns wide
              plotOutput("boxplot", height = "45vh"),
          )
          
      ),
      
      # Bottom section with two columns
      div(class = "row bottom-section no-margin-padding",
          div(class = "col-sm-4 no-margin-padding", # Left column - 4 columns wide
              papayaOutput("pap")
          ),
          div(class = "col-sm-8 no-margin-padding", # Right column - 8 columns wide
              # Nested row for two equal columns within the bottom right section
              column(2,
                 radioButtons("reorder_fmri", label = "Reorder fMRI RDM",
                              choices = list("No" = "FALSE", "Yes" = "TRUE"),
                              selected = "FALSE", inline = TRUE),
                 
                 radioButtons("reorder_rats", label = "Reorder model RDM",
                              choices = list("No" = "FALSE", "Yes" = "TRUE"),
                              selected = "FALSE", inline = TRUE),
                 
                 selectInput("model_select", "Select model:", choices = NULL)
                 
              ),
              column(5,
                 plotOutput("RDM_fmri_mean", height = "52vh")
              ),
              column(5,
                 plotOutput("RDM_rats_mean", height = "52vh")
              )
          )
      )
  )
)



server <- function(input, output, session) {
  
  # observe which result_file has been selected and load the corresponding .RData into the global environment
  
  # render table from the RSA_mean loaded from the selected .RData file
  
  
  # Choose the results_file and load the corresponding RSA_mean_table
  observe({
    
    req(input$results_file)
    
    file_path <- file.path(bd_results, paste0(input$results_file))
    load(file_path, envir = .GlobalEnv)
    # print(ls(envir = .GlobalEnv))
    
    output$RSA_mean_table <- renderReactable({
      reactable(
        RSA_mean %>% rename_with(~ str_replace(., "_mean", "")),
        defaultPageSize = 12,
        selection = "single", defaultSelected = c(1)
      )
    })

  })
  

  
  
  observe({
    
    req(input$results_file)
    
    idx_ROI <- reactive({
      getReactableState("RSA_mean_table", "selected")
    })
    
    # print(idx_ROI())   
    req(idx_ROI())
    
    # print the table with the one-sample ttest for each model
    output$ttest_table <- renderReactable({
      reactable(
        do_ttest_table(RSA, idx_ROI()),
        defaultColDef = colDef(align = "right")
      )
    })
    
    # load rois and update the "Select ROI" dropdown selection choices
    rois <- RSA_mean$roi
    
    # define a vector with the models from the columns of RSA_mean
    models <- colnames(RSA_mean)[grepl("_mean$", colnames(RSA_mean))] %>% str_replace("_mean","") %>% sort
    updateSelectInput(
      session, "model_select",
      choices = models,
      selected = if (input$model_select %in% models) input$model_select else models[1]
    )
    
    # draw the boxplot for the selected ROI
    req(idx_ROI())
    output$boxplot <- renderPlot({
      do_boxplot(RSA, idx_ROI())
    })
  
    
    # render the selected ROI with papaya
    output$pap <- renderPapaya({
      prepare_papaya(atlas_filename, idx_ROI())
    })
    
    # plot the RDM_fmri for the chosen ROI
    output$RDM_fmri_mean <- renderPlot({
      
      req(idx_ROI())
      # ith_roi <- idx_ROI()
      ith_roi <- which(rois == idx_ROI())
      
      req(input$reorder_fmri)
      reord_fmri <- as.logical(input$reorder_fmri)
      
      plot_tril(
        mean_RDMs_fmri[ith_roi,]$data, model = paste0("fmri_roi_",ith_roi),
        fontsize=10, side_mm=200, reord = reord_fmri
      )
    })
    
    # plot the ratings/model RDMs
    output$RDM_rats_mean <- renderPlot({
      
      req(input$model_select)
      mod <- input$model_select
      
      req(input$reorder_rats)
      reord_rats <- as.logical(input$reorder_rats)
            
      plot_tril(
        mean_RDMs_rats[[paste0("rdm_",mod)]], model = mod,
        fontsize=10, side_mm=200, reord = reord_rats
      )
      
    })
    
  })
  
  # ------- aux funs ---------
  
  do_ttest_table <- function(RSA, roi_numba) {
    
    model <- function(val) t.test(val, mu = 0, alternative = "two.sided")  # greater or two.sided
    
    RSA %>% 
      select(sub, roi, starts_with("rsa_")) %>% 
      filter(roi == roi_numba) %>% 
      select(starts_with("rsa_")) %>% 
      rename_with(~ str_replace(.x, "^rsa_rdm_", "")) %>% 
      map_dfr(~ broom::tidy(model(.x)), .id = "rsa_model") %>%
      mutate(t = paste0("t= ",round(statistic, 2)) ) %>% 
      # mutate(p = ifelse(p.value >= 0.001, paste0("p = ",round(p.value,2) ), "p < 0.001")) %>% 
      mutate(p = paste0("p=",round(p.value, 3)) ) %>% 
      mutate(res = paste0(t,", ",p)) %>%
      select(rsa_model, res) %>% 
      pivot_wider(names_from = rsa_model, values_from = res) %>% 
      mutate(roi = roi_numba) %>% relocate(roi)
  }
  
  
  prepare_papaya <- function(atlas_filename, roi_numba) {
    
    f <- function(nii_filename) {
      return(paste0(bd_atlases,"/", nii_filename))
    }
    
    nii_atlas <- RNifti::readNifti( f(atlas_filename) )
    # view(nii_atlas)
    
    nii_atlas_thr <- ifelse(nii_atlas == roi_numba, 1, 0)
    RNifti::writeNifti(nii_atlas_thr, template = nii_atlas, paste0(bd_atlases,"/tmp_ROI.nii.gz"))
    
    papaya(
      c(f("Dummy.nii.gz"), f("MNI152_T1_2mm_brain.nii.gz"), f("tmp_ROI.nii.gz")),
      options = list(
        papayaOptions(alpha = 1, lut = "Grayscale"),
        papayaOptions(alpha = 0.5, lut = "Grayscale"),
        papayaOptions(alpha = 0.5, lut = "Red Overlay", min = 0, max = 5)
      ),
      interpolation = FALSE,
      orthogonal = TRUE,
      hide_controls = TRUE
    )
    
  }
  
  
  
  do_boxplot <- function(RSA, roi_numba) {
    
    RSA %>% 
      select(sub, roi, starts_with("rsa_")) %>% 
      filter(roi == roi_numba) %>% 
      select(starts_with("rsa_")) %>% 
      pivot_longer(cols = starts_with("rsa_"), names_to = "model") %>%
      mutate(model = str_replace(model, "rsa_rdm_","")) %>% 
      ggwithinstats(
        x = model, y = value,
        type = "p",   # p, np, r, b
        title = paste0("roi ", roi_numba),
        results.subtitle = TRUE,
        centrality.label.args = list(size  = 6)
      ) + theme(
        axis.text = element_text(size = 16),   # Font size for axis text (labels)
        axis.title = element_text(size = 16),  # Font size for axis titles
        plot.title = element_text(size = 18)   # Font size for the plot title
      )
  }
  
  
  plot_tril <- function(tril, model, source_copes_info=df_path_copes, 
                        reord = FALSE, fontsize = 8, side_mm=100) {
    
    # Get metadata about n_copes and - potentially - about neutral removal
    # by selecting one sub from df_path_copes
    copes_info <- source_copes_info %>% filter(sub == subs[1])
    n_copes <- length(copes_info$cope)
    
    # Create a full symmetric matrix from the lower triangular input
    full_matrix <- matrix(0, n_copes, n_copes)
    full_matrix[lower.tri(full_matrix, diag = FALSE)] <- unlist(tril)
    full_matrix <- full_matrix + t(full_matrix)
    
    # # demean
    # full_matrix <- full_matrix - mean(full_matrix)

    # # reduce range to 0..1
    # full_matrix <- (full_matrix - min(full_matrix)) / (max(full_matrix) - min(full_matrix))

    # Set diagonal to NA
    diag(full_matrix) <- NA
    
    # assign row/col names/labels
    rownames(full_matrix) <- copes_info$label
    colnames(full_matrix) <- copes_info$label
    
    # Define the color map
    library(viridisLite)
    min_val <- min(full_matrix, na.rm = TRUE)
    max_val <- max(full_matrix, na.rm = TRUE)
    num_colors <- 100
    # https://jmsallan.netlify.app/blog/the-viridis-palettes/
    color_palette <- plasma(num_colors)  # inferno, magma, viridis, mako, plasma
    breaks <- seq(min_val, max_val, length.out = num_colors)
    color_map <- colorRamp2(breaks, color_palette)
    
    
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
  

}

shinyApp(ui, server)



















