library(tidyverse)
library(lubridate)

## Run script to extract sequence dates and cluster information from
## fasta files.
system("./extract_sequence_dates.sh")

prefixes <- c("max_chains",
              "min_chains")

finalSampleDate <- ymd("2020-11-30")

## Calculate final sample offsets and contact tracing start times:
## (We assume that contact tracing begins 2 days following the first sample.)
data <- list()

ctChange <- ymd("2020-05-15")

for (prefix in prefixes) {

    data[[prefix]] <- read_tsv(paste0("sequences/", prefix, ".dates.txt"))

    offsets <- data[[prefix]] %>%
        group_by(cluster) %>%
        summarize(finalSampleOffset = (finalSampleDate - max(date))/365.25,
                  zone1start = min(date) + 2) %>%
        rowwise() %>%
        mutate(zone2start = max(zone1start, ctChange)) %>%
        mutate(changeAge1 = (finalSampleDate - zone2start)/365.25,
               changeAge2 = (finalSampleDate - zone1start)/365.25) %>%
        select(-zone1start, -zone2start) 
               
    write_tsv(offsets, paste0("sequences/", prefix, ".FSOs.txt"))
}

## Create list of non-singleton clusters and write it to nonSingletons.txt:
for (prefix in prefixes) {

    clusterSizes <- data[[prefix]] %>%
        group_by(cluster) %>%
        summarize(n=n())

    write_tsv(clusterSizes %>% select(cluster),
              paste0("sequences/", prefix, ".all_clusters.txt"), col_names=FALSE)
    write_tsv(clusterSizes %>% filter(n>1) %>% select(cluster),
              paste0("sequences/", prefix, ".nonSingleton_clusters.txt"), col_names=FALSE)
}

## Set up weekly change times in R0 going back 52 weeks:
changeAges <- read_csv("sequences/date_to_week.csv") %>%
    distinct(week) %>%
    transmute(age=as.numeric(finalSampleDate - week)/365.25) %>%
    filter(age>0) %>%
    arrange(desc(row_number()))

write_tsv(changeAges, "ReChangeTimes.txt", col_names=FALSE)
