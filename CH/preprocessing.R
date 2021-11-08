library(tidyverse)
library(lubridate)

prefixes <- c("max_chains",
              "min_chains")

finalSampleDate <- ymd("2020-11-30")

## Calculate final sample offsets and contact tracing start times:
## (We assume that contact tracing begins 2 days following the first sample.)

data <- list()

ctActive <- ymd("2020-06-15")
ctInactive <- ymd("2020-09-30")

for (prefix in prefixes) {

    data[[prefix]] <- read_tsv(paste0("sequences/", prefix, ".dates.txt"))

    offsets <- data[[prefix]] %>%
        group_by(cluster) %>%
        summarize(finalSampleOffset = (finalSampleDate - max(date))/365.25,
                  zone1start = min(date) + 2) %>%
        rowwise() %>%
        mutate(zone2start = max(zone1start, ctActive)) %>%
        mutate(zone3start = max(zone2start, ctInactive)) %>%
        mutate(changeAge1 = (finalSampleDate - zone3start)/365.25,
               changeAge2 = (finalSampleDate - zone2start)/365.25,
               changeAge3 = (finalSampleDate - zone1start)/365.25) %>%
        select(-zone1start, -zone2start, -zone3start) 
               
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

## Set up change times in sampling proportion:

sampPropChangeDates <- ymd(c("2020-04-23",
                             "2020-06-25",
                             "2020-09-14",
                             "2020-09-28",
                             "2020-10-19",
                             "2020-11-02"))
sampPropChangeAges <- sort(as.numeric(finalSampleDate - sampPropChangeDates)/365.25)
write_tsv(tibble(changeTimes=sampPropChangeAges),
                 "sampPropChangeTimes.txt",
                 col_names=FALSE)
