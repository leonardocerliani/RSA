library(shiny)
library(tidyverse)
library(ggstatsplot)
library(reactable)
library(papayaWidget)
library(ComplexHeatmap)
library(circlize)  # For color mapping functions
library(grid)  # For gpar()
library(patchwork)
library(RNifti)

options(warn = -1)

# Thank to the great John Muschelli!
# https://github.com/muschellij2/linked_viewer/blob/master/app.R
# https://www.youtube.com/watch?v=_We6tviv3bQ


# Define the path to your directory
bd="/data00/leonardo/RSA/analyses"
bd_atlases = paste0(bd,"/ROIS_REPO")
bd_results = paste0(bd,"/RSA_ROI_APP/results_RSA_ROI")

# Volumes for papaya display
Dummy <- paste0(bd,"/ROIS_REPO/Dummy.nii.gz")
MNI <- paste0(bd,"/ROIS_REPO/MNI152_T1_2mm_brain.nii.gz")

# clever way to make it so that the displayed name corresponds to a certain
# filename
results_files <- dir(bd_results, pattern = "RData")
results_files_display <- gsub("\\.RData$", "", results_files)
results_file_choices <- setNames(results_files, results_files_display)

ui <- fluidPage(
  selectInput("results_file", "Select results", choices = results_file_choices),
  
  column(6,
     papayaOutput("papaya_atlas"), 
     tags$div(style = "height: 5cm;"),
     papayaOutput("papaya_arousal")  
  ),
  
  column(6,
     papayaOutput("papaya_emotion"),
     tags$div(style = "height: 5cm;"),
     papayaOutput("papaya_aroval")
  )
  
)



server <- function(input, output, session) {
  
  # Choose the results_file and load the corresponding RSA_mean_table
  observe({
    
    req(input$results_file)
    
    file_path <- file.path(bd_results, paste0(input$results_file))
    load(file_path, envir = .GlobalEnv)
    # print(ls(envir = .GlobalEnv))
    
  })
  
  
  observe({

    req(input$results_file)
    req(exists("RSA_volumes_df", where = .GlobalEnv))
    
    prepare_result_volumes(atlas_filename) 
        
    output$papaya_atlas <- renderPapaya(papaya_display_atlas(atlas_filename))
    
    output$papaya_emotion <- renderPapaya(papaya_display("emotion"))
    output$papaya_arousal <- renderPapaya(papaya_display("arousal"))
    output$papaya_aroval <- renderPapaya(papaya_display("aroval"))
    # output$papaya_valence <- renderPapaya(papaya_display("valence"))
    # file.remove(Sys.glob(paste0(bd_results,"/tmp*.nii.gz") ) )
    
  })
  
}


# ----------- aux funs ----------------

# takes the RSA_volumes_df from the .RData file
# and generates tmp_[model].nii.gz volumes
prepare_result_volumes <- function(atlas_filename) {
  
  f <- function(nii_filename) {
    return(paste0(bd_atlases,"/", nii_filename))
  }
  
  nii_atlas <- RNifti::readNifti( f(atlas_filename) )
  # view(nii_atlas)
  
  ratings_type <- colnames(RSA_volumes_df)
  
  ratings_type %>% walk(~{
    tmp_nii <- nii_atlas
    tmp_nii[1:length(nii_atlas)] <- RSA_volumes_df[[.x]]
    filename_2_write <- paste0(bd_results,"/tmp_",.x,".nii.gz")
    writeNifti(tmp_nii, filename_2_write)
  })
}


# papaya display RSA_volumes_df
papaya_display <- function(model) {
  
  rsa_results_nii <- paste0(bd,"/RSA_ROI_APP/results_RSA_ROI/tmp_",model,".nii.gz")
  
  papaya(
    c(Dummy, MNI, rsa_results_nii),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.5, lut = "Grayscale"),
      papayaOptions(alpha = 0.6, lut = "Red Overlay", min = 0.1, max = 0.25)
    ),
    interpolation = FALSE,
    orthogonal = TRUE,
    hide_controls = TRUE,
    sync_view = TRUE,
    title = model
  )
}



# papaya display atlas_filename
papaya_display_atlas <- function(atlas_filename) {
  
  atlas_path <- paste0(bd_atlases,"/",atlas_filename)

  papaya(
    c(Dummy, MNI, atlas_path),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.5, lut = "Grayscale"),
      papayaOptions(alpha = 0.6, lut = "Spectrum")
    ),
    interpolation = FALSE,
    orthogonal = TRUE,
    hide_controls = TRUE,
    sync_view = TRUE,
    title = str_replace(atlas_filename, ".nii.gz","")
  )
  
}




shinyApp(ui, server)


















