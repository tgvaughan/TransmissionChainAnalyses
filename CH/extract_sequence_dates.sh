#!/bin/bash

for prefix in max_chains min_chains; do
    (echo "date	cluster"; \
     grep '^>' sequences/$prefix.fasta \
         | cut -d'|' -f3,4 \
         | sed -e 's/|/	/' ) > sequences/$prefix.dates.txt
done
