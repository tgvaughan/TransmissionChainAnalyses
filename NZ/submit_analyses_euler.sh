#!/bin/bash

xml=Re_skyline.xml

for prefix in max_chains min_chains; do

    all=`cat sequences/$prefix.all_clusters.txt | tr '\n' ','`
    nonSingletons=`cat sequences/$prefix.nonSingleton_clusters.txt | tr '\n' ','`
    clustersToLog=`cat sequences/$prefix.toLog.txt | tr '\n' ','`

    for ctEst in 1 0; do
        for sampUB in 0.4 1.0; do

            echo "Submitting analysis $prefix with ctEst=$ctEst and sampUB=$sampUB..."

            bsub <<EOF
#!/bin/sh
#BSUB -W 120:00
#BSUB -R "rusage[mem=4096]"
#BSUB -J "nz_$xml.$prefix.$sampUB.$ctEst[1-5]"
module load java

JAVA="java -Xmx3G"
JAR=\$HOME/bdmm-prime.jar

SEED=\$LSB_JOBINDEX
STATEFILE=results/$xml.$prefix.sampUB$sampUB.$ctEst.\$SEED.state

\$JAVA -jar \$JAR -seed \$SEED -statefile \$STATEFILE \
             -overwrite \
             -D prefix=$prefix \
             -D all="$all" \
             -D nonSingletons="$nonSingletons" \
             -D ctEst="$ctEst" \
             -D sampUB="$sampUB" \
             -D clustersToLog="$clustersToLog" \
             $xml
EOF

        done
    done
done
