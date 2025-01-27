# Prepare site data ####
# Markus Bauer



### Packages ###
library(here)
library(tidyverse)
library(vegan)
library(FD) #dbFD
library(naniar) #are_na

### Start ###
#renv::restore()
renv::snapshot()
rm(list = ls())
setwd(here("data", "raw"))



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# A Load data ##########################################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


### 1 Sites ############################################################

sites <- read_csv("data_raw_sites.csv", col_names = TRUE,
                   col_types =
                    cols(
                      .default = "?"
                      )) %>%
  select(id, treatment, barrierDistance, treeCover, shrubCover, herbHeight) %>%
  filter(treatment != "infront_dam")


### 2 Species ##########################################################

species <- read_csv("data_raw_species.csv", col_names = TRUE,
                     col_types =
                    cols(
                      .default = "d",
                      name = "f",
                      layer = "f"
                      )
                    ) %>%
  select(-(Extra1:Extra4)) %>%
  filter(layer == "h") %>%
  group_by(name) %>%
  mutate(sum = sum(c_across(IN1:AC6)),
         presence = if_else(sum > 0, 1, 0)) %>%
  filter(presence == 1) %>%
  ungroup() %>%
  select(-sum, -presence, -layer)


### 3 Traits ###########################################################

traits <- read_csv("data_raw_traits.csv", col_names = TRUE,
                    col_types =
                      cols(
                        .default = "?"
                      )
                   ) %>%
  filter(layer == "herb")

traits <- traits %>%
  semi_join(species, by = "name")

miss_var_summary(traits)
gg_miss_var(traits)


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# B Create variables ###################################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


### 1 Create simple variables ##########################################

sites <- sites %>%
  mutate(conf.low = seq_along(id),
         conf.high = seq_along(id))


### 2 Coverages ########################################################

### a Querco-Fagetea coverage ------------------------------------------
data <- species %>%
  mutate(type = traits$sociality) %>%
  filter(type >= 8400) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(targetClass = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")
data <- species %>%
  mutate(type = traits$sociality) %>%
  filter(type >= 81000 & type < 84000) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(nontargetClass = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")

### b Fagetalia coverage -----------------------------------------------
data <- species %>%
  mutate(type = traits$sociality) %>%
  filter(type >= 84300 & type < 84400) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(targetOrder = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")
data <- species %>%
  mutate(type = traits$sociality) %>%
  filter(type >= 84100 & type < 84300) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(nontargetOrder = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")

### c Alno-Ulmion coverage ---------------------------------------------
data <- species %>%
  mutate(type = traits$sociality) %>%
  filter(type >= 84330 & type < 84340) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(targetAlliance = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")
data <- species %>%
  mutate(type = traits$sociality) %>%
  filter(type >= 84310 & type < 84330) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(nontargetAlliance = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")

### d Alnetum incanae coverage -----------------------------------------
data <- species %>%
  mutate(type = traits$name) %>%
  filter(type == "Thalictrum_aquilegiifolium" |
           type == "Alnus_incana") %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(targetAssociation = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")
data <- species %>%
  mutate(type = traits$name) %>%
  filter(
    type == "Prunus_padus" |
      type == "Aegopodium_podagraria" |
      type == "Brachypodim_sylvaticum" |
      type == "Carex_sylvatica" |
      type == "Paris_quadrifolia" |
      type == "Stachys_sylvatica"
      ) %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  summarise(total = sum(n)) %>%
  ungroup() %>%
  mutate(nontargetAssociation = round(total, 3), .keep = "unused")
sites <- sites %>%
  left_join(data, by = "id")

rm(data)


### 3 Species richness #################################################

spec_rich <- species %>%
  left_join(traits, by = "name") %>%
  select(starts_with("IN"), starts_with("AC"), name, flood, chwet)

### a total species richness -------------------------------------------
spec_rich_all <- spec_rich %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id) %>%
  mutate(n = if_else(n > 0, 1, 0)) %>%
  summarise(total = sum(n)) %>%
  group_by(id) %>%
  summarise(speciesRichness = sum(total)) %>%
  ungroup()

### b Ellenberg flood indicators (species richness) --------------------
spec_rich_flood <- spec_rich %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("AC") | starts_with("IN")) %>%
  group_by(id, flood) %>%
  mutate(n = if_else(n > 0, 1, 0)) %>%
  summarise(total = sum(n)) %>%
  filter(flood == "yes") %>%
  group_by(id) %>%
  summarise(floodRichness = sum(total)) %>%
  ungroup()

### c Ellenberg changing wetness indicators (species richness) ---------
spec_rich_chwet <- spec_rich %>%
  pivot_longer(names_to = "id", values_to = "n",
               cols = starts_with("IN") | starts_with("AC")) %>%
  group_by(id, chwet) %>%
  mutate(n = if_else(n > 0, 1, 0)) %>%
  summarise(total = sum(n)) %>%
  filter(chwet == "yes") %>%
  group_by(id) %>%
  summarise(chwetRichness = sum(total)) %>%
  ungroup()

### d implement in sites data set --------------------------------------
sites <- sites%>%
  left_join(spec_rich_all, by = "id") %>%
  left_join(spec_rich_flood, by = "id") %>%
  left_join(spec_rich_chwet, by = "id")

rm(list = setdiff(ls(), c("sites", "species", "traits")))


### 4 CWM of Ellenberg #################################################

### a N value ----------------------------------------------------------
data_traits <- traits %>%
  select(name, n) %>%
  filter(n > 0)
data_species <- semi_join(species, data_traits, by = "name") %>%
  pivot_longer(-name, "site", "value") %>%
  pivot_wider(site, name) %>%
  column_to_rownames("site")
data_traits <- column_to_rownames(data_traits, "name")
### Calculate CWM ###
n_weighted <- dbFD(data_traits, data_species, w.abun = TRUE,
                  calc.FRic = FALSE, calc.FDiv = FALSE, corr = "sqrt")

### b F value ----------------------------------------------------------
data_traits <- traits %>%
  select(name, f) %>%
  filter(f > 0)
data_species <- semi_join(species, data_traits, by = "name") %>%
  pivot_longer(-name, "site", "value") %>%
  pivot_wider(site, name) %>%
  column_to_rownames("site")
data_traits <- column_to_rownames(data_traits, "name")
### Calculate CWM ###
f_weighted <- dbFD(data_traits, data_species, w.abun = TRUE,
                  calc.FRic = FALSE, calc.FDiv = FALSE, corr = "sqrt")

### c implement in sites data set --------------------------------------
sites <- sites %>%
  mutate(x = n_weighted$CWM$n,
         x = as.character(x),
         cwmAbuN = as.numeric(x))
sites <- sites %>%
  mutate(x = f_weighted$CWM$f,
         x = as.character(x),
         cwmAbuF = as.numeric(x))

rm(list = setdiff(ls(), c("sites", "species", "traits")))


### 5 CWM and FDis of functional plant traits ##########################

traits_lhs <- traits %>%
  select(name, ldmc, seedmass, height) %>%
  drop_na()
traits_ldmc <- traits %>%
  select(name, ldmc) %>%
  drop_na()
traits_seedmass <- traits %>%
  select(name, seedmass) %>%
  drop_na()
traits_height <- traits %>%
  select(name, height) %>%
  drop_na()

### a All --------------------------------------------------------------

data_species <- semi_join(species, traits_lhs, by = "name")
data_traits <- semi_join(traits_lhs, data_species, by = "name")
data_species <- data_species %>%
  pivot_longer(-name, "site", "value") %>%
  pivot_wider(site, name) %>%
  column_to_rownames("site")
data_traits <- column_to_rownames(data_traits, "name")
log_data_traits <- log(data_traits)
data_abundance <- dbFD(log_data_traits, data_species, w.abun = TRUE,
                      calc.FRic = FALSE, calc.FDiv = FALSE, corr = "cailliez")
sites <- sites %>%
  mutate(fdisAbuLHS = data_abundance$FDis,
         fdisAbuLHS = as.character(fdisAbuLHS),
         fdisAbuLHS = as.numeric(fdisAbuLHS))

### b LDMC -------------------------------------------------------------

data_species <- semi_join(species, traits_ldmc, by = "name")
data_traits <- semi_join(traits_ldmc, data_species, by = "name")
data_species <- data_species %>%
  pivot_longer(-name, "site", "value") %>%
  pivot_wider(site, name) %>%
  column_to_rownames("site")
data_traits <- column_to_rownames(data_traits, "name")
log_data_traits <- log(data_traits)
data_abundance <- dbFD(log_data_traits, data_species, w.abun = TRUE,
                      calc.FRic = FALSE, calc.FDiv = FALSE, corr = "sqrt")
sites <- sites %>%
  mutate(x = data_abundance$FDis,
         x = as.character(x),
         fdisAbuLdmc = as.numeric(x))
sites <- sites %>%
  mutate(x = as.character(data_abundance$CWM$ldmc),
         x = as.numeric(x),
         cwmAbuLdmc = exp(x))

### C Seed mass --------------------------------------------------------

data_species <- semi_join(species, traits_seedmass, by = "name")
data_traits <- semi_join(traits_seedmass, data_species, by = "name")
data_species <- data_species %>%
  pivot_longer(-name, "site", "value") %>%
  pivot_wider(site, name) %>%
  column_to_rownames("site")
data_traits <- column_to_rownames(data_traits, "name")
log_data_traits <- log(data_traits)
data_abundance <- dbFD(log_data_traits, data_species, w.abun = TRUE,
                      calc.FRic = FALSE, calc.FDiv = FALSE, corr = "sqrt")
sites <- sites %>%
  mutate(x = data_abundance$FDis,
         x = as.character(x),
         fdisAbuSeedmass = as.numeric(x))
sites <- sites %>%
  mutate(x = as.character(data_abundance$CWM$seedmass),
         x = as.numeric(x),
         cwmAbuSeedmass = exp(x))

### D Canopy height ----------------------------------------------------

data_species <- semi_join(species, traits_height, by = "name")
data_traits <- semi_join(traits_height, data_species, by = "name")
data_species <- data_species %>%
  pivot_longer(-name, "site", "value") %>%
  pivot_wider(site, name) %>%
  column_to_rownames("site")
data_traits <- column_to_rownames(data_traits, "name")
log_data_traits <- log(data_traits)
data_abundance <- dbFD(log_data_traits, data_species, w.abun = TRUE,
                      calc.FRic = FALSE, calc.FDiv = FALSE, corr = "sqrt")
sites <- sites %>%
  mutate(x = data_abundance$FDis,
         x = as.character(x),
         fdisAbuHeight = as.numeric(x))
sites <- sites %>%
  mutate(x = as.character(data_abundance$CWM$height),
         x = as.numeric(x),
         cwmAbuHeight = exp(x))

rm(list = setdiff(ls(), c("sites", "species", "traits")))

sites <- sites %>%
  mutate(across(where(is.numeric), ~round(., digits = 3))) %>%
  select(-x)



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# C Save processed data ################################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


setwd(here("data", "processed"))
write_csv(sites, "data_processed_sites.csv")
write_csv(species, "data_processed_species.csv")
write_csv(traits, "data_processed_traits.csv")
