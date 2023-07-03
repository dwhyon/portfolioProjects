library(tidyverse)
library(sf)
library(tmap)
library(lubridate)


# Create Directory -------------------------------------------------------


dir.create("./Data/1_idGroup")




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


# Clean Date Function -----------------------------------------------------



cleanDate <- function(tibble) {  
  tibble %>% 
    mutate(
      Collection2 = str_extract(Collection, 
                               "(?=(\")).+(?<=(\"))"
                               #"(?=\")[[::]]"
                               ),
      col = str_c("1", Collection2),
      Date = dmy(col),
      .keep = "unused"
    )
  
}


# Create data sets --------------------------------------------------------


birds <- read_sf(shps[[1]]) %>% 
  cleanDate() 

pools <- read_sf(shps[[4]]) %>% 
  cleanDate()
  


sentinels <- read_sf(shps[[5]]) %>% 
  cleanDate()



glimpse(sentinels)




# Mapping -----------------------------------------------------------------

tmap_mode("view")



sentinels %>% 
  tm_shape() + 
  tm_dots()



groupFunc <- function(tibble){
  
  
  tibble %>% 
    group_by(Lat, Lon) %>% 
    mutate(
      id = cur_group_id(),
      lon = Lon,
      lat = Lat
    ) %>% 
    #select(-Lat:-City) %>% 
    select(-City, -Collection2, -col) %>% 
    st_drop_geometry()
  
  
}




birdGroup <- birds %>% 
  groupFunc()


sentGroup <- sentinels %>% 
  groupFunc()


poolGroup <- pools %>% 
  groupFunc()




write_csv(birdGroup, "./Data/1_idGroup/birdId.csv")


write_csv(sentGroup, "./Data/1_idGroup/sentinelId.csv")


write_csv(poolGroup, "./Data/1_idGroup/poolId.csv")


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
