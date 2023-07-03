library(tidyverse)



# Check Join --------------------------------------------------------------




joinFileNames <- list.files(
  path = "Data/5_joinGEELag/",
  full.names = T
)



# Non Function

joinDataset <- read_csv(joinFileNames[[1]])


joinDataset %>% glimpse()



naTable <- joinDataset %>% 
  filter(if_any(everything(), is.na))  %>% 
  group_by(clust, Month, Year) %>% 
  select_if(function(x) any(is.na(x)))


# Function method

findNA <- function(fileName) {
  
  
  
  
  dataset <- read_csv(fileName)
  
  
  #joinDataset %>% glimpse()
  
  
  
  naTable <- dataset %>% 
    filter(if_any(everything(), is.na))  %>% 
    group_by(clust, Month, Year) %>% 
    select_if(function(x) any(is.na(x)))
  
  naTable
  
  
  
}

naInfo <- map(joinFileNames, findNA)



# Investigate Joined Data -------------------------------------------------


# Bird Data ---------------------------------------------------------------


naInfo[[1]]

naInfo[[2]]

naInfo[[3]]

setdiff(
  naInfo[[3]], 
  naInfo[[2]])

# Seems like for all the bird extractions, a select number of clusters in the 
# 2021 / 2022 are missing JRC data. This could be due to gaps in the datasets
# themselves, but need to check this




# Pools Data --------------------------------------------------------------


naInfo[[4]] 

naInfo[[5]]
naInfo[[6]]


symdiff(naInfo[[4]], naInfo[[5]])

symdiff(naInfo[[4]], naInfo[[6]])

symdiff(naInfo[[5]], naInfo[[6]])


wy4 <- naInfo[[4]] %>% 
  select(clust, Month, Year)


wy4 %>% view()


wy5 <- naInfo[[5]] %>% 
  select(clust, Month, Year)


wy6 <- naInfo[[6]] %>% 
  select(clust, Month, Year)



# It's certain dates / clusters taht are missing data
symdiff(wy4, wy5)

symdiff(wy4, wy6)

symdiff(wy6, wy5)

# There is a large amount of data missing, and for all these, there are 
# 14,740 different rows


# Missing data for 2021 - 2023 only
naInfo[[4]] %>% 
  ungroup() %>% 
  distinct(Year)
  


naInfo[[4]] %>% 
  ungroup() %>% 
  filter(Year == 2021)%>% 
  
  select_if(function(x) any(is.na(x)))


# For 2021, 2022, only JRC is missing (consistent with birds / sentinels)
# I didn't run extractions for 2023, so this data is missing as well (update GEE)

missClustJRC <- naInfo[[4]] %>% 
  ungroup() %>% 
  distinct(clust)



totlClust <- read_csv(joinFileNames[[4]]) %>% 
  distinct(clust)



# Sentinel Data -----------------------------------------------------------


naInfo[[7]]

naInfo[[8]]

naInfo[[9]]


# Find how much CHIRPS is missing

naInfo[[7]] %>% 
  filter(!is.na(chirpsMean)) %>%
  ungroup() %>% 
  distinct(clust)

naInfo[[8]]

naInfo[[9]]

# All Chirps is missing! Just totally replace with 3000m buffer values



symdiff(naInfo[[7]], naInfo[[8]])

symdiff(naInfo[[7]], naInfo[[9]])

symdiff(naInfo[[8]], naInfo[[9]])


# So chirps is missing for the 1500, 2000 datasets, which I was aware of. HOwever
# JRC is also missing, I guess this would make sense given that it seems to be 
# missing data in other places too. Not sure what's going on 


