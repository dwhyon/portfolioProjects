library(tidyverse)
library(sf)
library(tmap)
library(lubridate)




# Read in Data ------------------------------------------------------------


# Find all Shapefiles
shps <- list.files(
  path = "./Data/0_input/",
  pattern = "shp$",
  full.names = T
)

# Find CSV
csvs <- list.files(
  path = "./Data/0_input/",
  pattern = "csv$",
  full.names = T
)



pools <- read_sf(shps[[4]])


birds <- read_sf(shps[[1]])


sentinels <- read_sf(shps[[5]])







# Appendix ----------------------------------------------------------------


# 
# 
# wnvFull <- read_sf(shps[[2]])
# 
# 
# wnvFullCA <- read_sf(shps[[3]])

# 
# 
# wnvFull %>% 
#   st_drop_geometry() %>% 
#   distinct(Type)
# 
# 
# 
# wnvSentinels %>% 
#   st_drop_geometry() %>% 
#   distinct(Type)
# 
# 
