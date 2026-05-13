library(shiny)
library(shinythemes)
library(shinyWidgets)
library(bslib)
# thematic::thematic_shiny(font = "auto")
library(ggthemes)
library(ggdark)

library(tidyverse)
library(ggstatsplot)
library(reactable)
library(papayaWidget)
library(ComplexHeatmap)
library(circlize)  # For color mapping functions
library(grid)  # For gpar()
library(patchwork)
library(RNifti)
library(xml2)

library(BayesFactor)


options(warn = -1)
papaya_hide_toolbar = FALSE



# V 7
# - All the model names are NOT anymore hardcoded
# - Added a selector for the models to display in the boxplot.
#   The boxplot displays only the selected models, and in the specified order of selection
# - It is possible to choose between fdr and none in MCP
# - A dropdown menu lets you select which model to use for displaying the 
#   RSA on the Papaya volume
#
# V 6.5
# - The downloaded figure also contains indication of the results of the one-sample
#   ttest for <> 0 for each model
#
# V 6.4
# - Introduced a function (do_boxplot_4_download) and button (downloadButton)
#   to download a version of the figure in a format suitable for the paper
# 
# V 6.3
# - excluded Valence alone: Now only Emotion, Arousal and Aroval are present 
# 
# V 6.2
# - idx_ROI : fixed the issue when (ROI number != RSA_mean row number), i.e. when not all ROIs values are present in the atlas (e.g. because some have been masked out)
# - idx_ROI_value_in_atlas : same as above but for atlas display
# 
# V 3
# - include ttest of [model] !=0 
# - select roi from reactable
# - change color palette to viridis family (inferno)
# - hidden controls for Papaya


# Papaya viz thanks to the great John Muschelli!
# https://github.com/muschellij2/linked_viewer/blob/master/app.R
# https://www.youtube.com/watch?v=_We6tviv3bQ


# Define the path to your directory
bd="/data00/leonardo/RSA/analyses"
bd_atlases = paste0(bd,"/ROIS_REPO")
bd_results = paste0(bd,"/RSA_ROI_APP/results_RSA_ROI")


# Makes sure you remove the tmp_[model].nii.gz volumes from the previous session
file.remove(Sys.glob(paste0(bd_results,"/tmp*.nii.gz") ) )

# Volumes for papaya display
Dummy <- paste0(bd,"/ROIS_REPO/Dummy.nii.gz")
MNI <- paste0(bd,"/ROIS_REPO/MNI152_T1_2mm_brain.nii.gz")
juelich <- ("jubrain_bilat.nii.gz")


# clever way to make it so that the displayed name corresponds to a certain
# filename
results_files <- dir(bd_results, pattern = "RData")
results_files_display <- gsub("\\.RData$", "", results_files)
results_file_choices <- setNames(results_files, results_files_display)


# Nice fonts: "Coming Soon", "Handlee", "Overlock", "Montserrat", "Roboto"
# For use below e.g. in bs.theme 
FONT_PERSONALIZZATO <- "Roboto"

library(showtext)
font_add_google(FONT_PERSONALIZZATO)
showtext_auto()


ui <- fluidPage(

  # theme = bs_theme(),   # requires bs_themer() in the server
  # theme = bs_theme(bootswatch = "cerulean"),
  
  theme = bs_theme(
    preset = "cerulean",
    base_font = font_google(FONT_PERSONALIZZATO),
    font_scale = 0.9
  ),


  
  # shinythemes::themeSelector(),
  # theme = shinytheme("united"),
  
  
  tags$style(HTML("
    body {
      padding-top: 5vh;
    }
    .papayaWidget {
      height: 40vh !important;
    }
    .radio-inline {
      font-size: 8pt;
    }
  ")),
  
  sidebarLayout(
    sidebarPanel(width = 5,
                 
                selectInput(
                      "results_file", "Select RSA results", choices = results_file_choices, width = "100%"
                ),
                
                 
                fluidRow(
                  column(6,
                     sliderInput(
                       "positive_range", label = NULL, step = 0.01, 
                       min = 0, max = 0.4, value = c(0.1, 0.25), width = "100%", ticks = FALSE
                     )                    
                  ),
                  column(6,
                     sliderInput(
                       "negative_range", label = NULL, step = 0.01, 
                       min = -0.4, max = 0, value = c(-0.25, -0.1), width = "100%", ticks = FALSE
                     )                  
                  )
                ),
                
                reactableOutput("RSA_mean_table"),
                reactableOutput("ttest_and_BF01_table"),

                tags$br(),
                
                fluidRow(
                  column(5,
                    radioButtons("ttest_type", "Paired t-test type", c("p","np","b"), selected = "p", inline = TRUE ),    
                  ),
                  column(5,
                    radioButtons("MCP_correction_method", "Multiple Comparison Correction", c("fdr","none"), selected = "fdr", inline = TRUE )
                  ),
                  column(2,
                    downloadButton("downloadPlot", "PDF"),
                  )
                ),
                
                 
                plotOutput("models_boxplot"),
                uiOutput("boxplot_model_selector")
                
    ),
    
    mainPanel(width = 7,
              fluidRow(
                column(6,
                       tags$h4("ROIs set"), papayaOutput("papaya_atlas"),
                       uiOutput("papaya_model_selector"),
                       papayaOutput("dynamic_papaya")
                ),
                
                column(6,
                       tags$h4("Juelich 3.1"), papayaOutput("papaya_juelich"),
                       reactableOutput('juelich_areas', height = "40vh")
                )
              )
    )
  )
)




server <- function(input, output, session) {
  
  # bs_themer() # requires theme = bs_theme() in the UI
  
  # Show atlas and area names
  output$papaya_juelich <- renderPapaya({
    papaya_display_juelich()
  })
  
  output$juelich_areas <- renderReactable({
    show_juelich_areas()
  })
  
  
  # Choose the results_file and load the corresponding RSA_mean_table
  observe({

    req(input$results_file)

    file_path <- file.path(bd_results, paste0(input$results_file))
    load(file_path, envir = .GlobalEnv)
    # print(ls(envir = .GlobalEnv))
    
    
    output$papaya_model_selector <- renderUI({
      req(exists("RSA_mean"))
      model_choices <- gsub("_mean$", "", grep("_mean$", colnames(RSA_mean), value = TRUE))
      selectInput("model_choice", "", choices = model_choices, selected = model_choices[1])
    })
    

    output$RSA_mean_table <- renderReactable({
      reactable(
        RSA_mean %>% rename_with(~ str_replace(., "_mean", "")),
        defaultPageSize = 5,
        selection = "single", defaultSelected = c(1)
      )
    })

    
  })
  
  
  
  # Display ttest for != 0 for a specific ROI and the corresponding 
  # boxplot across models
  observe({
    
    # We require again the input$results_file to refresh the values of the 
    # ttest and boxplot, otherwise it would display those of the previously
    # selected results_file
    req(input$results_file)
    
    req(getReactableState("RSA_mean_table", "selected"), cancelOutput = "progress")

    # prevent warning if no row is selected (defaults to first row)
    idx_ROI <- reactive({
      
      # # UPDATED VERSION to deal with the case  (ROI number != RSA_mean row number)
      RSA_mean_selected_row <- getReactableState("RSA_mean_table", "selected")
      rs = RSA_mean$roi[RSA_mean_selected_row]
        
      # cat("RSA_mean row : ", RSA_mean_selected_row, " ROI numba : ", rs, "\n")
      ifelse(is.null(rs),1,rs)
    })
    

    # Display the combined ttest + BF01 result for the
    # corresponding model above
    output$ttest_and_BF01_table <- renderReactable({
      req(exists("RSA_mean"))
      
      models_to_ttest <- RSA_mean %>%
        select(!roi) %>% 
        rename_with(~ str_replace(., "_mean", "")) %>% 
        colnames()
      
      # Compute ttest and bayesian BF01 and bind them
      ttest_and_BF01_table <- do_ttest_and_BF01_table(RSA, idx_ROI(), models_to_ttest)
      
      reactable(
        ttest_and_BF01_table,
        selection = "single",
        defaultColDef = colDef(align = "right")
      )
    })
    
    
    
    
    # Select which models are to be passed to the boxplot
    # and therefore to the paired ttest in ggwithinstats
    output$boxplot_model_selector <- renderUI({
      req(exists("RSA_mean"))
      
      model_choices <- gsub("_mean$", "", grep("_mean$", colnames(RSA_mean), value = TRUE))
      default_selection <- c("emotion", "arousal", "aroval")
      
      # Preserve current selection (if available)
      selected_models <- isolate(input$boxplot_model_choice)
      valid_selected <- intersect(selected_models, model_choices)
      
      # Use default if fewer than 2 valid selections
      if (length(valid_selected) < 2) {
        valid_selected <- intersect(default_selection, model_choices)
      }
      
      checkboxGroupButtons(
        inputId = "boxplot_model_choice", label = "", choices = model_choices,
        selected = valid_selected, justified = TRUE
      )
    })
    
    
    
    # Show boxplot for the chosen models
    output$models_boxplot <- renderPlot({
      
      req(input$boxplot_model_choice)
      
      do_boxplot(RSA, idx_ROI(), input$ttest_type, 
                 input$boxplot_model_choice, input$MCP_correction_method,
                 df_noise_summary)
    }, height = 420)
    
    
    
    # Generate Boxplot for Download
    output$downloadPlot <- downloadHandler(
      filename = function() {
        req(idx_ROI())
        paste0("boxplot_roi_", idx_ROI(), ".pdf")
      },
      content = function(file) {
        req(input$boxplot_model_choice)
        pdf(file, width = 8, height = 6)
        plot_to_save <- do_boxplot_4_download(
          RSA, idx_ROI(), input$ttest_type,
          input$boxplot_model_choice, input$MCP_correction_method,
          df_noise_summary
        )
        print(plot_to_save)
        dev.off()
      }
    )
    
    
  })
  
  
  
  # Display Volumes in Papaya
  observe({

    req(input$results_file)
    req(exists("RSA_volumes_df", where = .GlobalEnv))
    
    # Display ONLY the atlas ROI selected in the RSA_mean_table
    output$papaya_atlas <- renderPapaya({

      # UPDATED VERSION : deals with missing ROIs in the atlas (ROI number != RSA_mean row number)
      req(getReactableState("RSA_mean_table", "selected"))
      RSA_mean_selected_row <- reactive( getReactableState("RSA_mean_table","selected") )
      idx_ROI_value_in_atlas <- RSA_mean$roi[RSA_mean_selected_row()]
      papaya_display_atlas(atlas_filename,idx_ROI_value_in_atlas)
      
    })
    
    
    # Display the Papaya RSA for the model selected in the Dropdown
    output$dynamic_papaya <- renderPapaya({
      req(input$model_choice)
      papaya_display(
        input$model_choice, atlas_filename,
        input$positive_range[1], input$positive_range[2],
        input$negative_range[2], input$negative_range[1]
      )
    })
    
    
  
  })
  
  

  
  
  
}


# ----------- aux funs ----------------


# Papaya display RSA_volumes_df
papaya_display <- function(model, atlas_filename, positive_min, positive_max, negative_min, negative_max) {
  
  # generate the tmp_[model].nii.gz results file
  nii_atlas <- RNifti::readNifti(paste0(bd_atlases,"/", atlas_filename))
  tmp_nii <- nii_atlas
  tmp_nii[1:length(nii_atlas)] <- RSA_volumes_df[[model]]
  filename_2_write <- paste0(bd_results,"/tmp_",model,".nii.gz")
  writeNifti(tmp_nii, filename_2_write)
  
  rsa_results_nii <- paste0(bd_results,"/tmp_",model,".nii.gz")
  # print(rsa_results_nii)
  
  # display tmp_[model].nii.gz results on the MNI
  papaya(
    c(Dummy, MNI, rsa_results_nii, rsa_results_nii),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.5, lut = "Grayscale"),
      papayaOptions(alpha = 0.6, lut = "Red Overlay", min = positive_min, max = positive_max),
      papayaOptions(alpha = 0.6, lut = "Overlay (Negatives)", min = negative_min, max = negative_max)
    ),
    interpolation = FALSE,
    orthogonal = TRUE,
    hide_toolbar = papaya_hide_toolbar,
    hide_controls = TRUE,
    sync_view = TRUE,
    title = model
  )
}



# Boxplot of different models for the selected ROI
do_boxplot <- function(RSA, roi_numba, ttest_type, models_for_boxplot, MCP_correction_method, df_noise_summary) {
  
  p <- RSA %>% 
    select(sub, roi, starts_with("rsa_")) %>% 
    filter(roi == roi_numba) %>% 
    select(starts_with("rsa_")) %>% 
    pivot_longer(cols = starts_with("rsa_"), names_to = "model") %>%
    mutate(model = str_replace(model, "rsa_rdm_","")) %>% 
    filter(model %in% models_for_boxplot) %>% 
    mutate(model = factor(model, levels = models_for_boxplot)) %>%  # Set the desired order
    ggwithinstats(
      x = model, y = value,
      type = ttest_type,   # p, np, r, b
      title = paste0("roi ", roi_numba),
      results.subtitle = TRUE,
      bf.message = FALSE,
      ggsignif.args = list(textsize = 3, tip_length = 0.01),
      p.adjust.method = MCP_correction_method,
      centrality.label.args = list(size  = 5),
      point.path = FALSE
    ) +
    labs(y = "RSA", x = NULL) +
    theme(
      text = element_text(size = 15, family = FONT_PERSONALIZZATO),
      axis.text = element_text(size = 15),
      axis.title.y = element_text(size = 16),   # Only affects y-axis title
      axis.title.x = element_blank(),           # Hides x-axis title
      plot.title = element_text(size = 18),
      plot.subtitle = element_text(size = 13)
    )
  
  # print(extract_stats(p))
  
  # Extract and plot noise floor/ceiling
  noise_vals <- df_noise_summary %>%
    filter(roi == roi_numba) %>%
    select(noise_floor, noise_ceiling) %>%
    unlist() %>%
    as.numeric()
  
  # create the rectangle layer (no inherited aesthetics)
  rect_layer <- annotate(
    "rect",
    xmin = -Inf, xmax = Inf,
    ymin = min(noise_vals), ymax = max(noise_vals),
    alpha = 0.3, fill = "grey"
  )
  
  # insert the rect layer at the beginning so it is drawn *under* the violin plot
  p$layers <- c(rect_layer, p$layers)
  
  return(p)
  
  
}












# Boxplot for Download (to insert in the paper)
do_boxplot_4_download <- function(RSA, roi_numba, ttest_type, models_for_boxplot, MCP_correction_method, df_noise_summary) {
  
  # Pass models_for_boxplot here too
  ttest_results <- do_ttest_table(RSA, roi_numba, models_for_boxplot) 
  
  p <- RSA %>%
    select(sub, roi, starts_with("rsa_")) %>%
    select(-any_of(c("rsa_rdm_valence", "rsa_rdm_motion_energy"))) %>%
    filter(roi == roi_numba) %>%
    select(starts_with("rsa_")) %>%
    pivot_longer(cols = starts_with("rsa_"), names_to = "model") %>%
    mutate(
      model = str_replace(model, "rsa_rdm_", "")
    ) %>%
    filter(model %in% models_for_boxplot) %>%
    mutate(
      model = factor(model, levels = models_for_boxplot)  # maintain order
    ) %>%
    ggwithinstats(
      x = model, y = value,
      type = ttest_type,
      title = paste0("roi ", roi_numba),
      results.subtitle = FALSE,
      bf.message = FALSE,
      ggsignif.args = list(textsize = 4, tip_length = 0.01),
      p.adjust.method = MCP_correction_method,
      centrality.label.args = list(size  = 8),
      point.args = list(size = 5, alpha = 0.5)
    ) +
    theme(
      axis.title = element_blank(),
      axis.text = element_text(size = 18),
      axis.title.y.right = element_blank(),
      plot.title = element_text(size = 18)
    ) +
    scale_x_discrete(labels = ttest_results[models_for_boxplot])
  
  
  # Extract and plot noise floor/ceiling
  noise_vals <- df_noise_summary %>%
    filter(roi == roi_numba) %>%
    select(noise_floor, noise_ceiling) %>%
    unlist() %>%
    as.numeric()
  
  # create the rectangle layer (no inherited aesthetics)
  rect_layer <- annotate(
    "rect",
    xmin = -Inf, xmax = Inf,
    ymin = min(noise_vals), ymax = max(noise_vals),
    alpha = 0.5, fill = "grey"
  )
  
  # insert the rect layer at the beginning so it is drawn *under* the violin plot
  p$layers <- c(rect_layer, p$layers)
  
  return(p)
}



# ttest for != 0 for a specific ROI selected in the RSA_mean reactable table.
# Add also the BF01 from the bayesian model
do_ttest_and_BF01_table <- function(RSA, roi_numba, models_to_ttest) {
  
  # helper functions
  freq_model <- function(val) {
    out <- t.test(val, mu = 0, alternative = "two.sided")
    tibble(
      t = round(out$statistic, 2),
      p = round(out$p.value, 3)
    )
  }
  
  bayes_model <- function(val) {
    bf <- ttestBF(x = val, mu = 0)
    tibble(BF01 = round(1 / extractBF(bf)$bf, 2))
  }
  
  RSA %>%
    select(sub, roi, starts_with("rsa_")) %>%
    filter(roi == roi_numba) %>%
    select(starts_with("rsa_")) %>%
    rename_with(~ str_replace(.x, "^rsa_rdm_", "")) %>%
    select(any_of(models_to_ttest)) %>%
    map_dfr(function(x) {
      bind_cols(freq_model(x), bayes_model(x))
    }, .id = "rsa_model") %>%
    mutate(
      res = paste0("t=", t, ", p=", p, ", BF01=", BF01)
    ) %>%
    select(rsa_model, res) %>%
    pivot_wider(names_from = rsa_model, values_from = res) %>%
    mutate(roi = roi_numba) %>%
    relocate(roi)
}





# Papaya display atlas_filename
papaya_display_atlas <- function(atlas_filename, selected_ROI) {
  
  atlas_path <- paste0(bd_atlases,"/",atlas_filename)

  # to make a specific ROI visible, the range must be from ROI-1 to ROI+1
  if(!is.null(selected_ROI)) {
    min_val <- selected_ROI - 1
    max_val <- selected_ROI + 1
  } else {
    min_val <- max_val <- NULL
  }
  
  papaya(
    c(Dummy, MNI, atlas_path),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.5, lut = "Grayscale"),
      papayaOptions(alpha = 0.6, lut = "Spectrum", min = min_val, max = max_val)
    ),
    interpolation = FALSE,
    orthogonal = TRUE,
    hide_toolbar = papaya_hide_toolbar,
    hide_controls = TRUE,
    sync_view = TRUE,
    title = str_replace(atlas_filename, ".nii.gz","")
  )
  
}


# Papaya display juelich 3.1 atlas
papaya_display_juelich <- function() {
  
  papaya(
    c(Dummy, MNI, juelich),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.5, lut = "Grayscale"),
      papayaOptions(alpha = 0.6, lut = "Spectrum")
    ),
    interpolation = FALSE,
    orthogonal = TRUE,
    hide_toolbar = papaya_hide_toolbar,
    hide_controls = TRUE,
    sync_view = TRUE,
    title = ("Juelich31")
  )
  
}


# Display table of the juelich 3.1 area names
show_juelich_areas <- function() {
  
  jubrain_XML <- "JulichBrainAtlas_3.1_207areas_MPM_lh_MNI152.xml"
  xml_file <- read_xml(jubrain_XML)
  
  # Extract all Structure nodes
  structures <- xml_find_all(xml_file, "//Structure")
  
  # Create a dataframe with grayvalue and name
  df <- tibble(
    grayvalue = xml_attr(structures, "grayvalue"),
    name = xml_text(structures)
  )
  
  reactable(
    df,
    pagination = FALSE,
    searchable = TRUE
  )
}



shinyApp(ui, server)


















