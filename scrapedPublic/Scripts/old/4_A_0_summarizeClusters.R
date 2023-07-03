


# Packages ----------------------------------------------------------------

library(sf)
library(tidyverse)
library(tmap)
library(lubridate)
library(scales)



tmap_mode("view")


dir.create("./Data/4_summarizeClusters/")

# Read in Data ------------------------------------------------------------


# id : Cluster key 
birdKey <- read_csv("Data/2_clusterExport/birdClusterIDKey.csv")
poolKey <- read_csv("Data/2_clusterExport/poolClusterIDKey.csv")
sentKey <- read_csv("Data/2_clusterExport/sentinelClusterIDKey.csv")

# Bird data
bird <- read_csv("Data/1_idGroup/birdId.csv") %>% 
  inner_join(birdKey, by = "id") %>% 
  select(clust, Date, Month, Year, Count) %>% 
  mutate(
    Month = month(Date)
  )

# Pool data
pool <- read_csv("Data/1_idGroup/poolId.csv") %>% 
  inner_join(poolKey, by = "id") %>% 
  select(clust, Date, Month, Year, Count) %>% 
  mutate(
    Month = month(Date)
  )

# Sentinel data
sent <- read_csv("Data/1_idGroup/sentinelId.csv") %>% 
  inner_join(sentKey, by = "id") %>% 
  select(clust, Date, Month, Year, Count) %>% 
  mutate(
    Month = month(Date)
  )



# Summarize by Cluster ----------------------------------------------------

sumFunc <- function(tibble) {
  
  tibble %>% 
    group_by(clust, Month, Year) %>%
    summarise(Count = sum(Count))
    
  
  
  
  
}

datasets <- list(bird, pool, sent)

sumData <- map(datasets, sumFunc)


sumData[[2]] %>%
  ungroup() %>% 
  arrange(clust, Year, Month) %>% 
  view()





# 
# # Write out
# write_csv(MIR, "./Data/5_summarizeClusters/testPIRMIRClusterTEST.csv")








