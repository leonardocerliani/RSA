Raw data location:

`/data01/cas/EmotionInsula7T_project/Data_Collection`

# Anatomical
- Rotate to std `fslreorient2std`
- Inhomogeneity correction: using `fast`, but it's pretty bad inhomogeneities here - might need to use ANTs
- Defacing apparently not needed
- Skull stripping: again we need to see how fsl is doing here - might need ANTs

# Functional
NB: it is important to separate the preproc from the stats stage in FEAT since it is likely that we will attempt many types of stats, while the preproc is always the same.

- For each run
- Reorient to std
- topup with fmap
- standard preprocessing w/out slice timing correction and spatial smoothing
- registration nonlinear

# Prepare predictors for stats
Details on how to build the EVs on the [Feat guide](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FEAT/UserGuide#EVs)

Note that since we have already carried out preproc, the input to the stats will be the `.feat` dir containing the preproc

- triplets for each movie: onset (seconds), duration (seconds), intensity. Note that the first volume is at t=0

- for a first-pass analysis, we will run four three-levels models (single run, second-level at the subject level, across subjects):
    - all movies 
    - emotion rating (max across all emotions?)
    - arousal (emotion vs neutral?)
    - valence (negative vs positive?)

- prepare EV.txt files in R. Hopefully also the contrast files can be prepared in R.