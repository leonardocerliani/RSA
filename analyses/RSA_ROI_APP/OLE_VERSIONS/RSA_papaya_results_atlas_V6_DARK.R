library(shiny)
library(shinythemes)
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

options(warn = -1)
papaya_hide_toolbar = TRUE


# Set the default theme for all tables
options(reactable.theme = reactableTheme(
  color = "hsl(233, 9%, 87%)",
  # backgroundColor = "hsl(233, 9%, 19%)",
  backgroundColor = "#000000",  # Set to black
  borderColor = "hsl(233, 9%, 22%)",
  stripedColor = "hsl(233, 12%, 22%)",
  highlightColor = "hsl(233, 12%, 24%)",
  inputStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
  selectStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
  pageButtonHoverStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),
  pageButtonActiveStyle = list(backgroundColor = "hsl(233, 9%, 28%)")
))



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


ui <- fluidPage(
  
  # theme = bs_theme(),
  # shinythemes::themeSelector(),
  theme = shinytheme("cyborg"),
  
  
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
    sidebarPanel(width = 3,
                 
                selectInput(
                      "results_file", "Select results", choices = results_file_choices, width = "100%"
                ),
                
                div(
                  style = "font-size: 8pt;",
                    HTML("
                      <strong>OEPM</strong> : one ev per movie (48+8 EVs) &nbsp;&nbsp;
                      <strong>EHLP</strong> : emotion high/low predictors (12+2 EVs)<br>
                      <strong>EP</strong> : emotion predictors (6+1 EVs)  &nbsp;&nbsp; 
                      <strong>RN</strong> : remove neutral &nbsp;&nbsp;
                      <strong>MN</strong> : minus neutral<br><br>
                    ")
                  ),
                 
                fluidRow(
                  column(6,
                     sliderInput(
                       "positive_range", label = "Positive range", step = 0.01, 
                       min = 0, max = 0.4, value = c(0.1, 0.25), width = "100%", ticks = FALSE
                     )                    
                  ),
                  column(6,
                     sliderInput(
                       "negative_range", label = "Negative range", step = 0.01, 
                       min = -0.4, max = 0, value = c(-0.25, -0.1), width = "100%", ticks = FALSE
                     )                  
                  )
                ),
                
                reactableOutput("RSA_mean_table"),

                reactableOutput("ttest_table"),

                tags$br(),
                radioButtons("ttest_type", "Paired samples t-test type", c("p","np","b"), selected = "p", inline = TRUE ),
                 
                plotOutput("models_boxplot")
                
    ),
    
    mainPanel(width = 9,
              fluidRow(
                column(4,
                       tags$h4("ROIs set"), papayaOutput("papaya_atlas"),
                       tags$h4("Arousal"), papayaOutput("papaya_arousal")
                ),
                
                column(4,
                       tags$h4("Emotion"), papayaOutput("papaya_emotion"),
                       tags$h4("Aroval"), papayaOutput("papaya_aroval")
                ),
                
                column(4,
                       tags$h4("Juelich 3.1"), papayaOutput("papaya_juelich"),
                       reactableOutput('juelich_areas', height = "40vh")
                )
              )
    )
  )
)




server <- function(input, output, session) {
  
  # bs_themer()
  
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
    
    output$RSA_mean_table <- renderReactable({
      reactable(
        RSA_mean %>% rename_with(~ str_replace(., "_mean", "")),
        defaultPageSize = 7,
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
    
    req(getReactableState("RSA_mean_table", "selected"))
    
    idx_ROI <- reactive({
      getReactableState("RSA_mean_table", "selected")
    })
    
    # print the table with the one-sample ttest for each model
    output$ttest_table <- renderReactable({
      reactable(
        do_ttest_table(RSA, idx_ROI()),
        selection = "single",
        defaultColDef = colDef(align = "right")
      )
    })
    
    # show boxplot across models
    output$models_boxplot <- renderPlot({
      do_boxplot(RSA, idx_ROI(), input$ttest_type )
    })
    
  })
  
  
  
  observe({

    req(input$results_file)
    req(exists("RSA_volumes_df", where = .GlobalEnv))
    
    # Display ONLY the atlas ROI selected in the RSA_mean_table
    output$papaya_atlas <- renderPapaya({
      
      req(getReactableState("RSA_mean_table", "selected"))
      selected_ROI <- reactive( getReactableState("RSA_mean_table","selected") )
      
      papaya_display_atlas(atlas_filename,selected_ROI())
      
    })
    
    
    # Emotion
    output$papaya_emotion <- renderPapaya({
      papaya_display("emotion", atlas_filename, input$positive_range[1], input$positive_range[2], input$negative_range[2], input$negative_range[1])
    })
    
    # Arousal
    output$papaya_arousal <- renderPapaya({
      papaya_display("arousal", atlas_filename, input$positive_range[1], input$positive_range[2], input$negative_range[2], input$negative_range[1])
    })
    
    # Aroval
    output$papaya_aroval <- renderPapaya({
      papaya_display("aroval", atlas_filename, input$positive_range[1], input$positive_range[2], input$negative_range[2], input$negative_range[1])
    })
    
    # # Valence
    # output$papaya_valence <- renderPapaya({
    #   papaya_display("valence", atlas_filename, input$positive_range[1], input$positive_range[2], input$negative_range[2], input$negative_range[1])
    # })
  
  })
  
}


# ----------- aux funs ----------------


# papaya display RSA_volumes_df
papaya_display <- function(model, atlas_filename, positive_min, positive_max, negative_min, negative_max) {
  
  # generate the tmp_[model].nii.gz results file
  nii_atlas <- RNifti::readNifti(paste0(bd_atlases,"/", atlas_filename))
  tmp_nii <- nii_atlas
  tmp_nii[1:length(nii_atlas)] <- RSA_volumes_df[[model]]
  filename_2_write <- paste0(bd_results,"/tmp_",model,".nii.gz")
  writeNifti(tmp_nii, filename_2_write)
  
  rsa_results_nii <- paste0(bd_results,"/tmp_",model,".nii.gz")
  
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




# boxplot of different models for the selected ROI
do_boxplot <- function(RSA, roi_numba, ttest_type) {
  
  RSA %>% 
    select(sub, roi, starts_with("rsa_")) %>% 
    filter(roi == roi_numba) %>% 
    select(starts_with("rsa_")) %>% 
    pivot_longer(cols = starts_with("rsa_"), names_to = "model") %>%
    mutate(model = str_replace(model, "rsa_rdm_","")) %>% 
    ggwithinstats(
      x = model, y = value,
      type = ttest_type,   # p, np, r, b
      title = paste0("roi ", roi_numba),
      results.subtitle = TRUE,
      bf.message = FALSE,
      ggsignif.args = list(textsize = 3, tip_length = 0.01),
      p.adjust.method = "fdr",
      centrality.label.args = list(size  = 5)
    ) +
    ggdark::dark_theme_dark() +
    theme(
      legend.position = "none",
      axis.text = element_text(size = 16),   # Font size for axis text (labels)
      axis.title = element_text(size = 16),  # Font size for axis titles
      plot.title = element_text(size = 18)   # Font size for the plot title
    ) 
}


# ttest for != 0 for a specific ROI selected in the RSA_mean reactable table
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



# papaya display atlas_filename
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
    hide_toolbar = papaya_hide_toolbar,
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


















