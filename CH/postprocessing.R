library(tidyverse)
library(lubridate)
library(ggdist)

## Load data

skyline_data <- NULL
for (clusters in c("min", "max")) {
    for (contact_tracing in c(TRUE, FALSE)) {
        for (sampUB in c("With sampling bound", "Without sampling bound" )) {
            pattern <- paste0("Re_skyline.", clusters, "_chains",
                              ".sampUB", ifelse(sampUB=="With sampling bound", "0.05", "1.0"),
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

            sampProp_temp_data <- data %>%
                pivot_longer(cols=starts_with("sampValues."),
                             names_to="interval", values_to="value",
                             names_prefix="sampValues.",
                             names_transform=list(interval=as.integer)) %>%
                select(Sample, interval, value) %>%
                mutate(variable="sampProp")

            skyline_temp_data <- bind_rows(Re_temp_data, sampProp_temp_data) %>%
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


sampProp_dates <- read_csv("sampPropChangeTimes.txt", col_names=c("age")) %>%
    add_row(age=0) %>%
    mutate(date=finalSampleDate - 365.25*age) %>%
    arrange(age) %>%
    mutate(interval=row_number())

## Plot skylines

ggplot(skyline_data %>% filter(variable=="Re") %>% left_join(Re_dates),
       aes(date, median, col=contact_tracing, fill=contact_tracing)) +
    geom_ribbon(aes(x, ymin=ylow, ymax=yhigh),
              data=tibble(x=c(ymd("2020-06-15"), ymd("2020-09-30")),
                          ylow=c(0,0), yhigh=c(Inf,Inf),
                          median=0.5, contact_tracing=TRUE),
              fill="grey", col=NA, alpha=0.5) +
    geom_ribbon(aes(ymin=low, ymax=high), alpha=0.5) +
    geom_line() +
    geom_hline(yintercept=1, linetype="dashed") +
    facet_grid(rows=vars(clusters), cols=vars(sampUB), scales="free") +
    scale_x_date(date_breaks="1 month", date_labels="%b %Y") +
    ylab("Re") + ggtitle("Re estimates") +
    theme(axis.text.x=element_text(angle=-45, hjust=0))
ggsave("figures/Re.pdf", width=15, height=5, units="in")

ggplot(skyline_data %>% filter(variable=="sampProp") %>% left_join(sampProp_dates),
       aes(date, median, col=contact_tracing, fill=contact_tracing)) +
    geom_lineribbon(aes(ymin=low, ymax=high), alpha=0.5, step="vh",
                    linewidth=1) +
    facet_grid(rows=vars(clusters), cols=vars(sampUB), scales="free") +
    scale_x_date(date_breaks="1 month", date_labels="%b %Y") +
    ylab("Sampling proportion") + ggtitle("Sampling proportion estimates") +
    theme(axis.text.x=element_text(angle=-45, hjust=0))
ggsave("figures/sampProp.pdf", width=15, height=5, units="in")

## Contact tracing effect size

CT_data <- NULL
for (clusters in c("min", "max")) {
    for (contact_tracing in c(TRUE, FALSE)) {
        for (sampUB in c("With sampling bound", "Without sampling bound" )) {
            pattern <- paste0("Re_skyline.", clusters, "_chains",
                              ".sampUB", ifelse(sampUB=="With sampling bound", "0.05", "1.0"),
                              ".", ifelse(contact_tracing, "1", "0"),
                              ".*.log")

            data <- NULL
            for (f in dir("results", pattern, full.names=TRUE)) {
                data <- bind_rows(data, read_tsv(f) %>% slice_tail(prop=0.9))
            }

            CT_data <- bind_rows(CT_data,
                                 data %>%
                                 slice_tail(prop=0.9) %>%
                                 select(Sample, "CTFactor[0]", "CTFactor[1]", "CTFactor[2]") %>%
                                 pivot_longer(cols=2:4) %>%
                                 mutate(lessThanOne=(value<1.0)) %>%
                                 mutate(clusters=clusters,
                                        contact_tracing=contact_tracing,
                                        sampUB=sampUB))
        }
    }
}

ggplot(CT_data %>% filter(contact_tracing) %>%
       group_by(clusters,name,sampUB) %>%
       summarize(pLessThanOne=mean(lessThanOne)),
       aes(name, pLessThanOne, col=name, fill=name)) +
    geom_col() +
    scale_x_discrete(labels=c("After Sep 30", "Jun 15 to Sep 30", "Before Jun 15")) +
    facet_grid(rows=vars(clusters), cols=vars(sampUB)) +
    theme(legend.position = "none") +
    ylab("Probability of damping coefficient <1")
ggsave("figures/CT_dampingProbs.pdf")

ggplot(CT_data %>% filter(contact_tracing, lessThanOne),
       aes(name, value, col=name, fill=name)) +
    geom_violin(scale="width") +
    facet_grid(rows=vars(clusters), cols=vars(sampUB), scales="free") +
    scale_x_discrete(labels=c("After Sep 30", "Jun 15 to Sep 30", "Before Jun 15")) +
    theme(axis.text.x=element_text(angle=-45, hjust=0)) +
    theme(legend.position = "none") +
    xlab("") +
    ylab("Damping coefficients (conditioned on being <1)")
ggsave("figures/CT_conditionedDamping.pdf")
