# Alluvial forest River Ammer
# Show Figure CWM seed mass ####
# Markus Bauer



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# A Preparation #########################################################
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


### Packages ###
library(here)
library(tidyverse)
library(ggbeeswarm)

### Start ###
rm(list = ls())
setwd(here("data", "processed"))

### Load data ###
sites <- read_csv("data_processed_sites.csv", col_names = TRUE,
                   col_types =
                     cols(
                       .default = col_double(),
                       id = col_factor(),
                       treatment = col_factor()
                     )) %>%
  select(id, treatment, cwmAbuSeedmass) %>%
  mutate(treatment = fct_relevel(treatment, c("no_dam", "behind_dam")),
         treatment = fct_recode(treatment,
                                "Active" = "no_dam",
                                "Inactive" = "behind_dam"))



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# B Plotten #############################################################
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


theme_mb <- function() {
  ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = "white"),
    text  = ggplot2::element_text(size = 10, color = "black"),
    axis.line.y = ggplot2::element_line(),
    axis.line.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    legend.key = ggplot2::element_rect(fill = "white"),
    legend.position = "right",
    legend.margin = ggplot2::margin(0, 0, 0, 0, "cm"),
    plot.margin = ggplot2::margin(.5, 0, 0, 0, "cm")
  )
}

ggplot(sites, aes(treatment, cwmAbuSeedmass)) +
  geom_boxplot(colour = "black") +
  geom_quasirandom(color = "black", dodge.width = .6, size = .8) +
  scale_y_continuous(limits = c(1, 3), breaks = seq(0, 100, .5)) +
  labs(x = "", y = "CWM seed mass [mg]", size = 3) +
  theme_mb()

### Save ###
ggsave(here("outputs", "figures", "figure_6_cwm_seedmass_800dpi_6x6cm.tiff"),
       dpi = 800, width = 6, height = 6, units = "cm")
