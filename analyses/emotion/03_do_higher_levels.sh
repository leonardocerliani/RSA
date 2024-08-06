#!/bin/bash

# NB: currently the script is running only if we use the 26 subjects
# of the original sub_list.txt.
# I will modify it later to accept a new list of subs

export model="emotion"
# copes: anger | disgust | fear | happy | pain | sad | allMovies
export ncopes=7

export nruns=8  # input how many runs to process, e.g. 5 for runs 1..5

export sub_list="/data00/leonardo/RSA/sub_list.txt"

# ---------- DO NOT MODIFY ANYTHING BELOW THIS LINE ------------------------

export RSA_dir="/data00/leonardo/RSA"
export analyses_dir=${RSA_dir}/analyses/${model}

export fsf_template_2nd_level="${analyses_dir}/second_level_template.fsf"

export MNI_template="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm_brain"


sub_list="/data00/leonardo/RSA/sub_list.txt"
# cat $sub_list  | xargs -I{} printf "%02d\n" {}


# -------- second level analyses (across runs within sub) ----------------------

run_sub_2nd_level() {

    sub=$(printf "%02d" $1)

    fsf_sub_2nd_level=${analyses_dir}/results/2nd_level/fsf_sub_2nd_level_sub-${sub}.fsf
    gfeat_targetdir=${analyses_dir}/results/2nd_level/sub-${sub}_${model}.gfeat

    preproc_dir="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}"

    # remove previous analysis and create 
    [ -d ${analyses_dir}/data ] && rm -rf ${gfeat_targetdir}
    mkdir -p ${gfeat_targetdir}


    for var in sub model nruns preproc_dir gfeat_targetdir fsf_template_2nd_level fsf_sub_2nd_level; do
        echo ${var} : ${!var}
    done


    sed -e "s@__GFEAT_TARGETDIR__@${gfeat_targetdir}@g" \
        -e "s@__MNI_TEMPLATE__@${MNI_template}@g"  \
        -e "s@__NUMBA_RUNS__@${nruns}@g"  \
        -e "s@__EV_TITLE__@${model}@g" \
        ${fsf_template_2nd_level} > ${fsf_sub_2nd_level}


    # empty lines
    { echo; echo; echo; } >> "${fsf_sub_2nd_level}"


    echo "# 4D AVW data or FEAT directory (1..${nruns})" >> ${fsf_sub_2nd_level}
    for run in $(seq ${nruns}); do
        echo set "feat_files(${run}) \"${preproc_dir}/sub-${sub}_run-${run}_preproc_reg.feat\" " >> ${fsf_sub_2nd_level}
    done

    # empty lines
    { echo; echo; echo; } >> "${fsf_sub_2nd_level}"


    echo "# Higher-level EV value for EV 1 and input 1..${nruns}" >> ${fsf_sub_2nd_level}
    for run in $(seq ${nruns}); do
        echo "set fmri(evg${run}.1) 1" >> ${fsf_sub_2nd_level}
    done

    # empty lines
    { echo; echo; echo; } >> "${fsf_sub_2nd_level}"

    echo "# Group membership for input 1..${nruns}" >> ${fsf_sub_2nd_level}
    for run in $(seq ${nruns}); do
        echo "set fmri(groupmem.${run}) 1" >> ${fsf_sub_2nd_level}
    done


    echo "running 2nd level feat for sub-${sub}"
    feat ${fsf_sub_2nd_level}
}


# run the 2nd_level analysis for all the 26 subjects
export -f run_sub_2nd_level
cat ${sub_list} | xargs -P 30 -I{} bash -c 'run_sub_2nd_level {}'


# ---------- run the grouplevel analysis ------------------

RSA_dir="/data00/leonardo/RSA"
analyses_dir=${RSA_dir}/analyses/${model}

fsf_grouplevel_template="${analyses_dir}/grouplevel_template.fsf"

for i in $(seq ${ncopes}); do

    ncope="cope${i}"

    fsf_grouplevel_model="${analyses_dir}/results/grouplevel_${model}_${ncope}.fsf"
    group_outputdir="${analyses_dir}/results/grouplevel_${model}_${ncope}.gfeat"

    for var in fsf_grouplevel_template fsf_grouplevel_model group_outputdir; do
        echo ${var} = ${!var}
    done

    sed -e "s@__GROUP_OUTPUTDIR__@${group_outputdir}@g" \
        -e "s@__MNI_TEMPLATE__@${MNI_template}@g"  \
        -e "s@__MODEL__@${model}@g" \
        -e "s@__NCOPE__@${ncope}@g" \
        ${fsf_grouplevel_template} > ${fsf_grouplevel_model}

done


# run all the ${ncopes} grouplevel copes at once
eval "grouplevel_fsfs=(\"$PWD/results/grouplevel_${model}_cope\"{1..$ncopes}\".fsf\")"

printf "%s\n" "${grouplevel_fsfs[@]}" | xargs -P ${ncopes} -I{} feat {}



#EOF
