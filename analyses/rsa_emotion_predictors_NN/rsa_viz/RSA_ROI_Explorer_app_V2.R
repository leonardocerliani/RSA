library(shiny)
library(RNifti)
library(papayaWidget)
library(ggstatsplot)
library(tidyverse)


# ----------- Thresholds for Papaya ----------------

min_Arousal <- 0.15
max_Arousal <- 0.3

min_Emotion <- -0.2
max_Emotion <- -0.3

min_Valence <- 0.1
max_Valence <- 0.2

min_Aroval <- 0.25
max_Aroval <- 0.35

# ----------- Thresholds for Papaya ----------------



bd <- "/data00/leonardo/RSA/analyses/rsa_emotion_predictors_NN"
thr <- 0.05  # RSA value (!), NOT p value...

MNI <- readNifti("MNI152_T1_2mm_brain.nii.gz")
GM_clean <- readNifti("GM_clean.nii.gz")


# Define the UI
ui <- fluidPage(
  # Application title
  titlePanel("RSA ROI inspection"),
  
  # Top row layout
  fluidRow(
    column(6, 
           radioButtons("subs_set", "Choose Version:",
                        choices = list("N14" = "N14", "N26" = "N26"),
                        selected = "N14")
    ),
    column(6, 
           selectInput("directory", "Select Directory:", choices = dir(bd, pattern = "rsa_results") )
    )
  ),
  
  # Middle row layout
  fluidRow(
    column(12,
           radioButtons("roi_type", "Select ROI Type:",
                        choices = list("Coord" = "coord", "ROI nii" = "nii"),
                        selected = "coord")
           
    )
  ),
  fluidRow(
    column(12,
           conditionalPanel(
             condition = "input.roi_type == 'coord'",
             fluidRow(
               column(3, numericInput("x_coord", "X Coordinate:", value = 45, step = 1)),
               column(3, numericInput("y_coord", "Y Coordinate:", value = 54, step = 1)),
               column(3, numericInput("z_coord", "Z Coordinate:", value = 45, step = 1)),
               column(3, numericInput("radius" , "Radius vox", value = 5, step = 1))
             ),
             fluidRow(
               column(12,
                      radioButtons("roi_tissue", "ROI tissue",
                                   choices = list("Sphere" = "sphere", "GM in sphere" = "gm_in_sphere")
                      )
               )
             )
             
           )
    ),
    column(12,
           conditionalPanel(
             condition = "input.roi_type == 'nii'",
             fluidRow(
               column(12, fileInput("nii_file", "Upload ROI NII file", accept = c(".nii", ".nii.gz")))
             )
           )
    )
  ),
  
  # Bottom row layout
  fluidRow(
    column(12, align = "left",
           actionButton("go_button", "GO!")
    )
  ),
  
  # Papaya widget
  fluidRow(
    column(6,
      papayaOutput("pap", height = "300px")
    ),
    column(6,
      plotOutput("boxplot", height = "600px")
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  observeEvent(input$go_button, {
    
    print(input$roi_tissue)
    
    # View papaya
    output$pap <- renderPapaya({
      req(input$directory)
      
      # Build a spherical ROI given the (papaya) coordinates of the center
      do_ROI_from_center(
        isolate(input$x_coord), isolate(input$y_coord), 
        isolate(input$z_coord), isolate(input$radius), 
        input$roi_tissue
      )

      # layout MNI, overlays, ROI in Papaya
      papaya_layout(input$directory, input$subs_set)
      
    }) # closes output$pap 
    
    output$boxplot <- renderPlot({
      do_boxplot(bd, input$directory, input$subs_set)
    })
    
  }) # closes observeEvent
  

  
}


# ------------------------ AUX FUNCTIONS -----------------------------


# ---------------- GGSTATPLOT OF THE RSA VALUES IN THE ROI-----------------
do_boxplot <- function(bd, directory, subs_set) {

  # change the value of subs according to input$subs_set
  
  if (subs_set == "N26") {
    subs_file <- "/data00/leonardo/RSA/sub_list.txt"
    subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)  
    subs <- subs[subs != "20"]  # This is the outlier with very high R values
  } else {
    # subs <- c("02","03","12","11","22","09","29","28","26","32","23","15","20","19")
    subs <- c("02","03","12","11","22","09","29","28","26","32","23","15","19")
  }
  
  # Prepare fn to read the RSA values in the ROI for one rating
  get_avg_ROI_values <- function(rat_type, bd, directory, subs_set, subs) {

    ind_ROI <- which(readNifti("ROI.nii.gz") != 0)
    
    # read each sub RSA result for that condition
    root <- file.path(bd, directory, paste0(subs_set,"_GM_clean_bilat"))
    
    subs %>% set_names %>% 
      map(~ readNifti(paste0(root,"/sub_",.x,"_RSA_",rat_type,".nii.gz")) ) %>% 
      map_dbl(~ mean(.x[ind_ROI]))
    
  }
  
  
  # Use the fn above to get the mean vals across all ROI voxels for each rating
  # and put everything in a tibble to prepare to plot
  ROI_mean_vals <- tibble(
    sub = subs,
    arousal = get_avg_ROI_values("arousal", bd, directory, subs_set, subs),
    emotion = get_avg_ROI_values("emotion", bd, directory, subs_set, subs),
    valence = get_avg_ROI_values("valence", bd, directory, subs_set, subs),
    aroval = get_avg_ROI_values("aroval", bd, directory, subs_set, subs)
  ) %>% 
    pivot_longer(cols = c("emotion","arousal","valence","aroval"), names_to = "rat_type")
  
  
  
  # Do the actual plot
  p <- ggstatsplot::ggwithinstats(
      ROI_mean_vals,
      x = rat_type,
      y = value,
      type = "parametric",
      centrality.label.args = list(size  = 6),
      ggstatsplot.layer = FALSE,
      ggplot.component = list(theme(text = element_text(size = 15)))
    )
  
  return(p)
  
}





# -------- Prepare Papaya Layout -----------

papaya_layout <- function(directory, subs_set) {
  papaya(
    c(
      file.path(bd, directory, "Dummy.nii.gz"),
      file.path(bd, directory, "MNI152_T1_2mm_brain.nii.gz"),
      file.path(bd, directory, paste0(subs_set,"_GM_clean_bilat_arousal.nii.gz")),
      file.path(bd, directory, paste0(subs_set,"_GM_clean_bilat_emotion.nii.gz")),
      file.path(bd, directory, paste0(subs_set,"_GM_clean_bilat_valence.nii.gz")),
      file.path(bd, directory, paste0(subs_set,"_GM_clean_bilat_aroval.nii.gz")),
      "ROI.nii.gz"
    ),
    options = list(
      papayaOptions(alpha = 1, lut = "Grayscale"),
      papayaOptions(alpha = 0.3, lut = "Grayscale"),
      papayaOptions(alpha = 1, lut = "Red Overlay", min = min_Arousal, max = max_Arousal),
      papayaOptions(alpha = 1, lut = "Blue Overlay", min = min_Emotion, max = max_Emotion),
      papayaOptions(alpha = 1, lut = "Green Overlay", min = min_Valence, max = max_Valence),
      papayaOptions(alpha = 1, lut = "Green Overlay", min = min_Aroval, max = max_Aroval),
      papayaOptions(alpha = 0.7, lut = "Gold", min = 0, max = 2)
    ),
    interpolation = FALSE,
    hide_controls = TRUE
  )
  
}




# --------  ROI generation from papaya coordinate -----------------

# Convert papaya coordinates to actual voxel coord
# This needs to be used just for the ROI center of gravity
papaya_to_real_coordinates <- function(p_coord, MNI) {
  p_coord = p_coord + 1
  center_MNI <- ceiling((dim(MNI) / 2) - 1) + 1
  return(2*center_MNI - p_coord)
}



# Searchlight function : returns the linear indices of the voxels in the searchlight
#
# NB: the coordinate of the ROI center
# must already be the actual one, NOT the one displayed by Papaya!
get_searchlight_ind <- function(ROI_center, r_mm, MNI) {

  voxel_size <- pixdim(MNI) %>% mean 
  ind <- which(MNI != 0)
  coords <- which(MNI != 0, arr.ind = TRUE)
  
  # Calculate distance of the given voxel from every other voxel, considering voxel size
  distances <- sqrt(rowSums((t(t(coords) - ROI_center) * voxel_size)^2))
  
  # return the idx of the voxels in the searchlight
  return(ind[distances <= r_mm])
}


# Use the two functions above to create and save to disk a spherical ROI
# centered on the papaya coordinates x,y,z
do_ROI_from_center <- function(x,y,z,radius,roi_tissue) {
  
  ifelse(
    roi_tissue == "sphere",
    MNI <- readNifti("MNI152_T1_2mm_brain.nii.gz"),
    MNI <- readNifti("GM_clean.nii.gz")
  )
  
  # Convert the ROI_COG from papaya to real coords
  p_coord_ROI_center <- c(x,y,z)
  coord_ROI_center <- papaya_to_real_coordinates(p_coord_ROI_center, MNI)
  
  # Get the ind of the searchlight ROI
  ind_searchlight <- get_searchlight_ind(coord_ROI_center, r_mm = radius, MNI)
  
  # Write the ROI to disk
  nii <- MNI * 0
  nii[ind_searchlight] = 1
  writeNifti(nii, "ROI.nii.gz")
  
}






# Run the application
shinyApp(ui = ui, server = server)









