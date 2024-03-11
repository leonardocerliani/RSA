#!/bin/bash

# This script checks if by mistake some $model variable has been
# erroneously hard-coded in some of the $model-specific scripts
# If it returns nothing, it means that everything is ok

for model in allMovies arousal emotion valence emotion_predictors; do

    for directory in allMovies arousal emotion valence emotion_predictors; do

        if [ ${model} != ${directory} ]; then

            echo "Checking for ${model} in ${directory}"
            grep -r "$model " ./${directory}/ --exclude=*.out

        fi

    done
    echo 

done

# EOF

