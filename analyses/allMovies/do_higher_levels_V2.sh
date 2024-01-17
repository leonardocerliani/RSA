#!/bin/bash

sub_list="/data00/leonardo/RSA/sub_list.txt"
# cat $sub_list  | xargs -I{} printf "%02d\n" {}

model="allMovies"
MNI_template="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm_brain"

sub_list="/data00/leonardo/RSA/sub_list.txt"
# cat $sub_list  | xargs -I{} printf "%02d\n" {}

run_sub_2nd_level() {

    sub=$(printf "%02d" $1)

    model="allMovies"

    # input how many runs to process, e.g. 5 for runs 1..5
    nruns=8

    RSA_dir="/data00/leonardo/RSA"
    analyses_dir=${RSA_dir}/analyses/${model}

    fsf_template_2nd_level="${analyses_dir}/second_level_template.fsf"

    fsf_sub_2nd_level=${analyses_dir}/data/2nd_level/fsf_sub_2nd_level_sub-${sub}.fsf
    gfeat_targetdir=${analyses_dir}/data/2nd_level/sub-${sub}_allMovies.gfeat

    preproc_dir="${RSA_dir}/prep_data/sub-${sub}/fmri/${model}"

    MNI_template="/data00/leonardo/warez/fsl/data/standard/MNI152_T1_2mm_brain"

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

fsf_grouplevel_model="${analyses_dir}/data/grouplevel_${model}.fsf"
group_outputdir="${analyses_dir}/data/grouplevel_${model}.gfeat"

for var in fsf_grouplevel_template fsf_grouplevel_model group_outputdir; do
    echo ${var} = ${!var}
done

sed -e "s@__GROUP_OUTPUTDIR__@${group_outputdir}@g" \
    -e "s@__MNI_TEMPLATE__@${MNI_template}@g"  \
    -e "s@__MODEL__@${model}@g" \
    ${fsf_grouplevel_template} > ${analyses_dir}/data/grouplevel_${model}.fsf


feat ${analyses_dir}/data/grouplevel_${model}.fsf




#EOF