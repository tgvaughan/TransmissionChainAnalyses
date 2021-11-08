#!/bin/bash

xml=Re_skyline.xml

for prefix in min_chains max_chains; do
    for ctEst in 1 0; do
        for sampUB in 0.05 1.0; do
            for rep in 1 2 3 4 5; do
                all=`cat sequences/$prefix.all_clusters.txt | tr '\n' ','`
                nonSingletons=`cat sequences/$prefix.nonSingleton_clusters.txt | tr '\n' ','`

                beast -overwrite \
                      -seed $rep \
                      -D prefix=$prefix \
                      -D all="$all" \
                      -D nonSingletons="$nonSingletons" \
                      -D ctEst="$ctEst" \
                      -D sampUB="$sampUB" \
                      $xml
            done
        done
    done
done
