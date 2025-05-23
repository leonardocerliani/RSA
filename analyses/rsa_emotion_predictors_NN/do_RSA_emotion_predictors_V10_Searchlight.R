#' ---
#' title: "do_RSA_v10_Searchlight"
#' author: "LC"
#' date: "2024-05-03"
#' output: html_document
#' ---

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the number of arguments is not exactly three
if (length(args) != 3) {
  cat("\n")
  cat("Usage: Rscript do_RSA.R [ratings_type] [gm_mask] [TOP_RATERS/ALLSUBS]\n\n")
  cat("e.g.: Rscript do_RSA.R emotion test_mask TOP_RATERS\n")
  cat("\n")
  quit(status = 1)
}


#' # Load libraries
## ----load_libraries, message=F----------------------------------------------------------------
library(tidyverse)
library(future)
library(furrr)
library(tictoc)
library(RNifti)
library(proxy) # distances
library(profvis)
library(DT)
library(formattable)

source("funs_V10_emotion_predictors_Searchlight.R")



# # Emotion predictors copes correspondence
# Note: This copes/emotion correspondence is important to filter from the fmri data.
# In the ratings file, the cope number still corresponds to the original 56 copes.

emotion_cope_number <- tribble(
  ~emotion, ~cope,
  "anger",     1,
  "disgust",   2,
  "fear",      3,
  "happy",     4,
  "neutral",   5,
  "pain",      6,
  "sad",       7
)

emotion_cope_number


# # Expected numbers
# For the emotion_predictors flavour there are 6 copes/ratings:
#   (anger, disgust, fear. happy, pain, sad).
# 
# The RDMs will have (6^2 - 6)/2 = 15 elements
# 
# For the 14 most congruent participants, the RDMs_fmri and the RDMs_rats will 
# therefore ahve 14 * 15 = 210 rows



#' # Set the following paramters manually
## ---------------------------------------------------------------------------------------------

rsa_flavour="rsa_emotion_predictors_NN"

# # ratings_type can be emotion, arousal, valence
# ratings_type <- "arousal"
ratings_type <- args[1]

# # must be one of the masks in [rsa_flavour]/masks
# gm_file <- "test_mask"
gm_file <- args[2]

# Define searchlight radius in mm
r_mm <- 4

# # if set to TOP_RATERS, it will use only the subs below
# subs_selection = "TOP_RATERS"
subs_selection <- args[3]
top_raters_subs <- c("02","03","12","11","22","09","29","28","26","32","23","15","20","19")


#' 
#' 
#' # Other parameters
#' Do not touch unless you know what you are doing
## ---------------------------------------------------------------------------------------------
bd="/data00/leonardo/RSA/analyses"

# the following is our contrast of interest and it's always the same
copes_type <- "emotion_predictors_NN"

# full path of the gm mask onto which the searchlight will be used
gm_path <- paste0(bd,"/",rsa_flavour,"/masks/", gm_file, ".nii.gz")


# Choose the distance metric to use for fmri RDM
# The metric for ratings RDM *should be* euclidean, since arousal and valence
# ratings have only one value
# Supported methods: 'pearson', 'spearman', 'euclidean', 'cosine' or 'mahalanobis'
dist_method_rating <- "euclidean"
dist_method_fmri = "euclidean"
dist_method_rsa = "pearson"


# for RDM_type use:
# - tril for the lower triangular of the D matrix
# - svd for the first 3 pc from svd of the D matrix
# - in case of svd, set the number of components to return with ncomp_svd
RDM_type = "tril"  # svd or tril. Must be the same for both rating and fmri
ncomp_svd = 3  


# Vector of zeropadded sub_ids
subs_file <- "/data00/leonardo/RSA/sub_list.txt"
subs <- sprintf("%02d",readLines(subs_file) %>% as.numeric)

# Subset if TOP_RATERS since we need the length(sub) for the
# pathname of results_dir
if (subs_selection == "TOP_RATERS") {
  subs <- top_raters_subs
}


#' 
#' 
#' # Create the directory where the results will be stored
#' This will allow us also to store a text file with all the info about the analysis
#' 
## ---------------------------------------------------------------------------------------------
results_flavour <- generate_results_flavour(
  gm_file, dist_method_rating, dist_method_fmri, dist_method_rsa, subs
)

rsa_results_path <- paste0(bd, "/",rsa_flavour,"/rsa_results")
results_dir <- paste0(rsa_results_path, "/", results_flavour)

# Create the results if it does not exist
if (!dir.exists(results_dir)) {
  # Create the directory if it does not exist
  dir.create(results_dir, recursive = TRUE)
  print(paste0("Created ", results_dir))
} else {
  print(paste0(results_dir, " already exists"))
}

#' 
#' 
#' Store important information about the parameters for the analysis in a text file
#' 
## ---------------------------------------------------------------------------------------------

# redirect the cat msgs to the logfile
logfile <- paste0(results_dir, "/", ratings_type, "_log.txt")
sink(logfile)


cat("\n")
cat("Using", ratings_type, "rating\n\n")
cat("Calculating RSA for every voxel in the", gm_file, "mask\n") 
cat("using a searchlight of", r_mm, "mm\n\n")
cat(paste0("Ratings RDM to be calculated with : ", dist_method_rating, "\n"))
cat(paste0("fMRI RDM to be calculated with : ", dist_method_fmri, "\n\n"))

# If subs_selection is TOP_RATERS only the subs with highest movie/emotion
# congruency - defined above - will be included
if (subs_selection == "TOP_RATERS") {
  # subsetting subs <- top_raters_subs already done above
  cat("Only the", length(subs), "top raters")
} else {
  cat("All", length(subs), "subs")
}

cat("\n\n")

# stop sinking the cat msgs into the logfile
sink()


#' 
#' 
#' 
#' 
#' 
#' 
#' # Aux functions
## ---------------------------------------------------------------------------------------------
# plot_heatmap(D %>% as.matrix)
plot_heatmap <- function(M) {
  heatmap(M, Rowv = NA, Colv = NA, symm=T, revC = T)
}

#' 
#' 
#' # Create a df_path_copes with the location of the 56 cope niis from the one_movie_per_ev model
#' Extract the pathname of all copes using the `list.files()` function.
#' Also define a copes_numba vector with all the copes numbers.
#' 
#' NB: The cope numbers in the `cope` column are NOT zeropadded since this is how they come out from FSL Feat
## ----message=FALSE----------------------------------------------------------------------------

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


# ------- REMOVE NEUTRAL FROM FMRI COPES ----------
# For emotion_predictors NEUTRAL cope = 5

neutral_cope_numba <- emotion_cope_number %>% 
  filter(emotion == "neutral") %>% 
  select(cope) %>% pull

df_path_copes <- df_path_copes %>% 
  filter(sub %in% subs) %>% 
  filter(cope != neutral_cope_numba)

# ------- REMOVE NEUTRAL FROM FMRI COPES ----------


copes_numba <- df_path_copes$cope %>% unique


# df_path_copes


#' 
#' 
#' 
#' 
#' 
#' # Calculate RATINGS RDMs
#' We do this first since the RDM for the ratings will be the same for whatever
#' atlas will be used. Also, it's much faster than the RDM_fmri and can be done
#' for all the sub_ids at once.
#' 
#' 
#' - **tril** : The final RDMs_rats has 40040 nrows : 26 sub_ids * 1540, where the latter
#' derives from ((56^2)-56)/2 = 1540, i.e. tril from the D matrix of 56 movies
#' - **svd** : The final RDMs_rats has 4368 nrows : 26 sub_ids * 168, where the latter
#' derives from 56*3, i.e. the first three components from svd of the D matrix
## ----message=FALSE----------------------------------------------------------------------------

bd_ratings = paste0(bd,"/RATINGS")
ratings_path <- paste0(bd_ratings,"/",ratings_type,"_ratings.csv")
rats <- read_csv(ratings_path)

# ------- IMPORTANT : AVG ACROSS MOVIES FOR EMOTION PREDICTORS MODEL -----
rats <- rats %>% 
  select(sub, emotion, starts_with("r_")) %>%
  group_by(sub, emotion) %>% 
  reframe(across(starts_with("r_"), median, na.rm = TRUE)) %>% 
  ungroup %>% 
  arrange(sub, emotion)
# ------- IMPORTANT : AVG ACROSS MOVIES FOR EMOTION PREDICTORS MODEL -----

rats

# ------- REMOVE NEUTRAL FROM RATINGS ----------

rats <- rats %>% 
  filter(emotion != "neutral")

# ------- REMOVE NEUTRAL FROM RATINGS ----------

# for RDM_type use:
# - tril for the lower triangular of the D matrix
# - svd for the first 3 pc from svd of the D matrix
RDMs_rats_wider <- subs %>% map_dfc(~ {
  do_RDM_ratings_one_sub(.x, dist_method_rating, rats, RDM_type =  RDM_type)
})

RDMs_rats <- RDMs_rats_wider %>% 
  pivot_longer(cols = everything(), names_to = "sub") %>% 
  arrange(sub)

RDMs_rats

#' 
#' 
#' # Calculate fMRI RDMs
#' 
#' ## Create SEARCHLIGHT regions
#' 
#' This code cell yields two outputs:
#' 
#' - `idx` : the index of each voxel in the mask, i.e. an integer from 1 to 91x109x91
#' 
#' - `idx_within_radius` : a list of list: each inner list contains the index of the
#' voxels which are within the defined radius, i.e. within the searchlight having that
#' voxel as a 'center'. 
#' 
#' Note that not all voxels have the same numba of other voxels
#' within their searchlight. The histogram below shows the distribution
#' of numba of voxels in the searchlight for each voxel in the mask.
#' 
#' 
## ---------------------------------------------------------------------------------------------

# 1. Read the gm mask and get voxel size, get idx of voxels in gm and their
#    xyz coordinates
gm <- readNifti(gm_path)
voxel_size <- pixdim(gm) %>% mean   # voxel size of gm
idx <- which(gm != 0)   # index of nonzero voxels
coords <- which(gm != 0, arr.ind = TRUE)   # get coordinates


# 2. Define a searchlight function returning the volume (92x109x92) idx of the 
#    voxels within the searchlight
searchlight <- function(center_coord, r_mm, coords, idx, voxel_size) {

  # Calculate distance of the given voxel from every other voxel, considering voxel size
  distances <- sqrt(rowSums((t(t(coords) - center_coord) * voxel_size)^2))
  
  # # TEST ONLY: return the coords of the voxels in the searchlight
  # return(coords[distances <= r_mm, , drop = FALSE])

  # return the idx of the voxels in the searchlight
  return(idx[distances <= r_mm])
}


# # Testing the searchlight fn with one coordinate 
# # See also the nb : earchlight_development.Rmd
# mycoord <- coords[1,]
# idx_within_radius <- searchlight(mycoord, r_mm=6, coords, idx, voxel_size)

# # Convert indices to coordinates (just to check)
# mycoord
# coords_within_radius <- coords[match(idx_within_radius, idx), , drop = FALSE]
# coords_within_radius


# 3. Get the idx of the vxls within radius for each voxel in gm (~ 20 sec)
plan(multisession, workers = 15)

tic()

idx_within_radius <- 1:length(idx) %>% future_map(
  ~ searchlight(coords[.x,], r_mm, coords, idx, voxel_size)
)

toc()

plan(sequential)

#
# idx_within_radius %>% map_dbl(length) %>% hist



#' 
#' 
#' 
#' ## Fn to carry out the RMDs Searchlight calculation for one sub
#' 
## ----message=FALSE----------------------------------------------------------------------------

# In order to test for one sub, I need to load the corresponding df_copes.
# In the next cells the df_copes of each sub are dynamically loaded
# when subs %>% future_map_dfr
sub_id = "02"
df_copes <- load_sub_copes(sub_id, copes_numba, df_path_copes)


calculate_fmri_RDMs_Searchlight <- function(df_copes, idx, idx_within_radius) {
  
  one_rdm <- idx_within_radius %>% map_dfc(~ {
    idx_spot <- unlist(.x)
    df_copes_region <- df_copes[idx_spot, ]
    
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
    
    # flat onto a vector
    D_feature_vector <- D_fmri[!is.na(D_fmri)]
  })
  
  colnames(one_rdm) = idx
  
  return(one_rdm)
}

# Again the following is just for testing on one sub
# ~ 90 seconds, no need to use furrr
N <- 10 #length(idx)
one_RDM_fmri <- calculate_fmri_RDMs_Searchlight(df_copes, idx[1:N], idx_within_radius[1:N])

one_RDM_fmri


#' 
#' 
#' 
#' ## Furrr the RDMs Searchlight calculation across subs
## ----message=FALSE----------------------------------------------------------------------------

# for testing on a subset of idx
N = length(idx)

# 5 workers give the best performance
plan(multisession, workers = 10)

tic()
RDMs_fmri <- subs %>% future_map_dfr(~{
  
  paste0("Calculating RDMs Searchlight for sub ",.x,"\n") %>% cat
  
  df_copes <- load_sub_copes(.x, copes_numba, df_path_copes)
  
  one_RDM_fmri <- calculate_fmri_RDMs_Searchlight(
    df_copes, 
    idx[1:N], 
    idx_within_radius[1:N]
  )
  
  one_RDM_fmri %>% mutate(sub = .x) %>% relocate(sub)
  
})
toc()

plan(sequential)

#' 
#' 
#' 
#' # RSA Searchlight
#' 
#' ## Calculate RSA and mean RSA across subs inside a tibble
## ---------------------------------------------------------------------------------------------

rdms_fmri_nested <- RDMs_fmri %>% 
  pivot_longer(cols = !starts_with("sub"), names_to = "region") %>% 
  group_by(sub,region) %>% 
  nest() %>% 
  rename(fmri = data)


rdms_rats_nested <- RDMs_rats %>% 
  group_by(sub) %>% 
  nest %>% 
  rename(rat = data)


# we put a copy of the rating RDM for each atlas region's RDM
joint_fmri_rat_nested <- right_join(rdms_fmri_nested,rdms_rats_nested, by = "sub")
# # the following is just to check that the join went as expected
# ff %>% mutate(sum_rat = rat %>% map_dbl(sum)  )

joint_fmri_rat_nested

# Calculate all RSA for each sub and each region/voxel
# and also round similarity and fix region data type
RSA <- joint_fmri_rat_nested %>% 
  mutate(
    similarity = list(fmri,rat) %>% pmap_dbl(~ cor(.x,.y, method = dist_method_rsa))
  ) %>%
  ungroup %>% 
  mutate(
    region = as.integer(region),
    similarity = round(similarity, 3)
  )

# Estimate avg_RSA
avg_RSA <- RSA %>%
  select(region, similarity) %>% 
  group_by(region) %>% 
  reframe(
    mean_similarity = round(mean(similarity),2),
    sd_similarity = round(sd(similarity),2)
  ) %>% 
  arrange(desc(mean_similarity))

avg_RSA %>% datatable()

#' 
#' 
#' ## Write the RSA results to niis
#' 
#' Two types of results are written in nii images, for each voxel in the mask:
#' - the RSA for each sub
#' - the average RSA across subs
#' 
#' ### Define `results_flavor` and create `results_dir` 
#' 
#' The following chunk is all to create an informative name for the results dir for this 
#' particular mask, rating type and distance methods, as well as to create the 
#' directory if it does not exist yet
#' 
#' **NB: The following section was moved to the very top in order to be able to** 
#' **write a text file with the parameters of the analysis**
#' 
## ---------------------------------------------------------------------------------------------

# # NB: [results_flavour].nii.gz will also be the name of the avg RSA across subs
# results_flavour <- generate_results_flavour(
#   gm_file, dist_method_rating, dist_method_fmri, dist_method_rsa, subs
# )
# 
# rsa_results_path <- paste0(bd, "/[rsa_flavour]/rsa_results")
# results_dir <- paste0(rsa_results_path, "/", results_flavour)
# 
# # Create the results if it does not exist
# if (!dir.exists(results_dir)) {
#   # Create the directory if it does not exist
#   dir.create(results_dir, recursive = TRUE)
#   print(paste0("Created ", results_dir))
# } else {
#   print(paste0(results_dir, " already exists"))
# }


#' 
#' 
#' ### Write the RSA nii for each sub - these will be used by `randomise`
#' 
## ---------------------------------------------------------------------------------------------

# Using the function write_RSA_results_to_nii. Documentation in the funs_[Vx]_Searchlight.R

RSA %>%
  select(sub, region, similarity) %>% 
  group_split(sub) %>% 
  walk(~ write_RSA_results_to_nii(.x, ratings_type, results_dir, gm))


#' 
#' 
#' 
#' 
#' ### Write the avg_RSA nii - for viz
#' 
## ---------------------------------------------------------------------------------------------

write_avg_RSA_to_nii <- function(avg_RSA, results_flavour, 
                                 ratings_type, rsa_results_path, gm) {
  
  results_nii <- gm
  
  idx_voxel <- avg_RSA$region
  results_nii[idx_voxel] = avg_RSA$mean_similarity
  
  nii2write_path <- paste0(rsa_results_path,"/", results_flavour, "_", ratings_type,".nii.gz")
  cat(paste0(nii2write_path,"\n"))
  
  writeNifti(results_nii, nii2write_path)
}


write_avg_RSA_to_nii(avg_RSA, results_flavour, ratings_type, rsa_results_path, gm)


#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
