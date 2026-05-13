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
library(xml2)

pc="30%"

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
juelich <- ("jubrain_bilat.nii.gz")

# clever way to make it so that the displayed name corresponds to a certain
# filename
results_files <- dir(bd_results, pattern = "RData")
results_files_display <- gsub("\\.RData$", "", results_files)
results_file_choices <- setNames(results_files, results_files_display)


ui <- fluidPage(

  tags$style(HTML("
    .container-fluid {
      padding-top: 3vh;
      padding-left: 20vh;
      padding-right: 20vh;
    }
  ")),
  
  fluidRow(
    column(width = 6, 
      selectInput(
        "results_file", "Select results", choices = results_file_choices, width = "100%"
      )
    ),
    column(width = 6, 
      sliderInput(
        "positive_range", label = "Positive range", step = 0.01, 
        min = 0, max = 0.4, value = c(0.1, 0.25), width = "100%", ticks = FALSE
      )
    )
  ),
  

  fluidRow(
    column(4,
           tags$h4("ROIs set"), papayaOutput("papaya_atlas"),
           tags$div(style = "height: 10vh;"),
           tags$h4("Arousal"), papayaOutput("papaya_arousal")
    ),
    
    column(4,
           tags$h4("Emotion"), papayaOutput("papaya_emotion"),
           tags$div(style = "height: 10vh;"),
           tags$h4("Aroval"), papayaOutput("papaya_aroval")
    ),
    
    column(4,
           tags$h4("Juelich 3.1"), papayaOutput("papaya_juelich"),
           tags$div(style = "height: 10vh;"),
           reactableOutput('juelich_areas', height = "40vh")
    )
    
  )
)



server <- function(input, output, session) {
  
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
    
  })
  
  
  observe({

    req(input$results_file)
    req(exists("RSA_volumes_df", where = .GlobalEnv))
    
    prepare_result_volumes(atlas_filename) 
        
    output$papaya_atlas <- renderPapaya(papaya_display_atlas(atlas_filename))
    
    # Emotion
    output$papaya_emotion <- renderPapaya({
      papaya_display("emotion", input$positive_range[1], input$positive_range[2])
    })
    
    # Arousal
    output$papaya_arousal <- renderPapaya({
      papaya_display("arousal", input$positive_range[1], input$positive_range[2])
    })
    
    # Aroval
    output$papaya_aroval <- renderPapaya({
      papaya_display("aroval", input$positive_range[1], input$positive_range[2])
    })
    
    # # Valence
    # output$papaya_valence <- renderPapaya({
    #   papaya_display("valence", input$positive_range[1], input$positive_range[2])
    # })
    
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
papaya_display <- function(model, positive_min, positive_max) {
  
  rsa_results_nii <- paste0(bd,"/RSA_ROI_APP/results_RSA_ROI/tmp_",model,".nii.gz")
  
  papaya(
    c(Dummy, MNI, rsa_results_nii),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.5, lut = "Grayscale"),
      papayaOptions(alpha = 0.6, lut = "Red Overlay", min = positive_min, max = positive_max)
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


# papaya display juelich 3.1 atlas
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
    hide_controls = TRUE,
    sync_view = TRUE,
    title = ("Juelich31")
  )
  
}


# display table of the juelich 3.1 area names
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


















