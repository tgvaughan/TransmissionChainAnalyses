library(tidyverse)
library(lubridate)
library(ggdist)

## Load data

skyline_data <- NULL
for (clusters in c("min", "max")) {
    for (contact_tracing in c(TRUE, FALSE)) {
        for (sampUB in c("With sampling bound", "Without sampling bound" )) {
            pattern <- paste0("Re_skyline.", clusters, "_chains",
                              ".sampUB", ifelse(sampUB=="With sampling bound", "0.4", "1.0"),
                              ".", ifelse(contact_tracing, "1", "0"),
                              ".*.log")

            data <- NULL
            for (f in dir("results", pattern, full.names=TRUE)) {
                data <- bind_rows(data, read_tsv(f) %>% slice_tail(prop=0.9))
            }

            Re_temp_data <- data %>%
                pivot_longer(cols=starts_with("ReValues."),
                             names_to="interval", values_to="value",
                             names_prefix="ReValues.",
                             names_transform=list(interval=as.integer)) %>%
                select(Sample, interval, value) %>%
                mutate(variable="Re")

            skyline_temp_data <- bind_rows(Re_temp_data) %>%
                group_by(interval, variable) %>%
                summarize(median=median(value),
                          low=quantile(value, 0.025),
                          high=quantile(value, 0.975)) %>%
                mutate(clusters=clusters,
                       contact_tracing=contact_tracing,
                       sampUB=sampUB)

            skyline_data <- bind_rows(skyline_data, skyline_temp_data)
            
        }
    }
}

## Incoroporate interval dates

finalSampleDate <- ymd("2020-11-30")
Re_dates <- read_csv("sequences/date_to_week.csv") %>%
    distinct(week) %>%
    filter(week<finalSampleDate) %>%
    arrange(desc(row_number())) %>%
    transmute(interval=row_number(), date=week+3.5)

## Plot skylines

ctChange <- ymd("2020-05-15")
ggplot(skyline_data %>% filter(variable=="Re") %>% left_join(Re_dates),
       aes(date, median, col=contact_tracing, fill=contact_tracing)) +
    geom_vline(xintercept=ctChange, col="grey") +
    geom_ribbon(aes(ymin=low, ymax=high), alpha=0.5) +
    geom_line() +
    geom_hline(yintercept=1, linetype="dashed") +
    facet_grid(rows=vars(clusters), cols=vars(sampUB), scales="free") +
    scale_x_date(date_breaks="1 month", date_labels="%b %Y") +
    ylab("Re") + ggtitle("Re estimates") +
    theme(axis.text.x=element_text(angle=-45, hjust=0))
ggsave("figures/Re.pdf", width=15, height=5, units="in")

## Contact tracing effect size

CT_data <- NULL
for (clusters in c("min", "max")) {
    for (contact_tracing in c(TRUE, FALSE)) {
        for (sampUB in c("With sampling bound", "Without sampling bound" )) {
            pattern <- paste0("Re_skyline.", clusters, "_chains",
                              ".sampUB", ifelse(sampUB=="With sampling bound", "0.4", "1.0"),
                              ".", ifelse(contact_tracing, "1", "0"),
                              ".*.log")

            data <- NULL
            for (f in dir("results", pattern, full.names=TRUE)) {
                data <- bind_rows(data, read_tsv(f) %>% slice_tail(prop=0.9))
            }

            CT_data <- bind_rows(CT_data,
                                 data %>%
                                 slice_tail(prop=0.9) %>%
                                 select(Sample, "CTFactor[0]", "CTFactor[1]") %>%
                                 pivot_longer(cols=2:3) %>%
                                 mutate(lessThanOne=(value<1.0)) %>%
                                 mutate(clusters=clusters,
                                        contact_tracing=contact_tracing,
                                        sampUB=sampUB))
        }
    }
}

ggplot(CT_data %>% filter(contact_tracing) %>%
       group_by(clusters,sampUB,name) %>%
       summarize(pLessThanOne=mean(lessThanOne)),
       aes(name, pLessThanOne, col=name, fill=name)) +
    geom_col() +
    scale_x_discrete(labels=c("After May 15", "Before May 15")) +
    facet_grid(rows=vars(clusters), cols=vars(sampUB)) +
    theme(legend.position = "none") +
    ylab("Probability of damping coefficient <1")
ggsave("figures/CT_dampingProbs.pdf")

ggplot(CT_data %>% filter(contact_tracing, lessThanOne),
       aes(name, value, col=name, fill=name)) +
    geom_violin(scale="width") +
    facet_grid(rows=vars(clusters), cols=vars(sampUB), scales="free") +
    scale_x_discrete(labels=c("After May 15", "Before May 15")) +
    theme(axis.text.x=element_text(angle=-45, hjust=0)) +
    theme(legend.position = "none") +
    xlab("") +
    ylab("Damping coefficients (conditioned on being <1)")
ggsave("figures/CT_conditionedDamping.pdf")
