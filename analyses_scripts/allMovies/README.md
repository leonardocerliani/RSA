# Group stats structure and procedure

Analyses are carried out using the standard procedure:
- 1st level : within sub/run
- 2nd level : within sub / across runs
- group-level : across subs

The 1st and 2nd level analyses are carried out in the `prep_data` dir.

The `.gfeat` of the 2nd level analysis is written in this dir, where the group-level analysis is carried out

Each model's analyses is isolated in its own dir which is named according to the model. In the present case, `allMovies`. All the scripts for all the levels are kept in this folder.



## First level stats

The following is an example of the structure for one sub at the end of first-level stats. The steps to create this file is explained below.

```
analysis_scripts/allMovies/
    do_prepare_mat.R
    first_level_template.fsf
    do_first_level_stats.sh

prep_data/sub-02/fmri/
    sub-02_run-{1..8}_preproc_reg.feat
    allMovies/
        sub-02_run-{1..8}.mat
        design_sub-02_run-{1..8}.fsf
        sub-02_run-{1..8}_stats.feat
```


### `do_prepare_mat.R`
Takes the onsets.csv file from `raw_data/sub-{n}/onsets/` and creates the `.mat` files which will be used by FSL Feat. The `allMovies` dir is also created in this step.

The `do_prepare_mat_nb.Rmd` is the notebook where the content of the script is prepared and tested.

output : 
```
prep_data/sub-{n}/fmri/allMovies/sub-{n}_run-{1..8}.mat
```

### `first_level_template.fsf`
This is obtained by manually creating one .fsf for the stats only of one sub/run using the Feat gui, using the .mat file(s) created above. 

Note that the input is the output .feat dir from the preprocessing.

To go from the single sub/run to the template, we need to identify the lines where specific values need to be replaced for other subs/runs. This is done during the writing of the `do_first_level_stats.sh` script.


### `do_first_level_stats.sh`
- cp `sub-02_run-{1..8}_preproc_reg.feat` to the `fmri/allMovies` dir

- uses the `first_level_template.fsf` to produce a `design_sub-02_run-{1..8}.fsf` design file to pass to feat

- runs `feat design_sub-02_run-{1..8}.fsf`

It is necessary to cp the preproc_reg into the underlying `allMovies` dir since we will use the preprocess data to fit several models

The `first_level_template.fsf` is also developed while writing this script.


**NB:** : in a first version of this script I also replaced the name of EVs and contrasts. This is likely _not_ necessary since these names do not change - and actually _need_ to be the same - across subs and runs. The .mat files change, but not the name of the EVs to which they are assigned.

At the end of the procedure, it might be appropriate to move all the .feat folders inside `fmri/allMovies` (as well as those from other models) into `/data01` to reduce the space used on `/data00`


## Second level - within sub - stats
It might be necessary to create a template also here, since there will be one .fsf file for each sub, where the input are the first-level .feat files


## Third level - group level
This can be easily and efficiently carried out in the Feat GUI.