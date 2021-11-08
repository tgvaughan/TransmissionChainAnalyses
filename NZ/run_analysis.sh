#!/bin/bash

for prefix in max_chains min_chains; do
    all=`cat sequences/$prefix.all_clusters.txt | tr '\n' ','`
    nonSingletons=`cat sequences/$prefix.nonSingleton_clusters.txt | tr '\n' ','`

    for ctEst in 1 0; do
        for sampUB in 0.4 1.0; do
            for rep in 1 2 3 4 5; do
                beast -overwrite \
                      -seed $rep \
                      -D prefix=$prefix \
                      -D all="$all" \
                      -D nonSingletons="$nonSingletons" \
                      -D ctEst="$ctEst" \
                      -D sampUB="$sampUB" \
                      Re_skyline.xml
        done
    done
done
