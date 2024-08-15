#!/bin/bash

# The grouplevel GLM takes as input the results/2nd_level/sub-{sub}_{model}/cope[1..56].feat dirs
# and produces PE and tstat maps for that contrast across subjects
#
# Results are sent to the ./results/grouplevel_{model}_cope[1..56].gfeat dirs

export model="one_ev_per_movie_minus_neutral"

RSA_dir="/data00/leonardo/RSA"
analyses_dir=${RSA_dir}/analyses/${model}

fsf_grouplevel_template="${analyses_dir}/grouplevel_template.fsf"

for i in $(seq 56); do

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


# run all the 56 grouplevel copes in batches of 8 at a time
grouplevel_fsfs=("$PWD/results/grouplevel_${model}_cope"{1..56}".fsf")
printf "%s\n" "${grouplevel_fsfs[@]}" | xargs -P 8 -I{} feat {}