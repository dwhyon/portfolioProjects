library(tidyverse)
library(lubridate)

#options(scipen = 999)


dir.create("./Data/5_joinGEELag/")


# Read in Data ------------------------------------------------------------


interpolatedPaths <- list.files("./Data/4_summarizeClusters/",
                                full.names = T) %>% 
  enframe(name = NULL, value = "data")


geeClean <- list.files("extractions/", pattern = "Clean", full.names = T) %>% 
  enframe(name = NULL, value = "extract")


allComboRaw <- interpolatedPaths %>% 
  expand_grid(geeClean)


s <- allComboRaw %>% 
  filter(str_detect(data, "sentinel") & str_detect(extract, "sentinel"))

b <- allComboRaw %>% 
  filter(str_detect(data, "bird") & str_detect(extract, "bird"))


p <- allComboRaw %>% 
  filter(str_detect(data, "pool") & str_detect(extract, "pool"))


allCombo <- s %>% 
  bind_rows(b, p)

lag  <-  "0"


# Join --------------------------------------------------------------------


# Function to join GEE extractions to calSurv data
lagGEEJoin <- function(data, extract) {
  
  # Simple subtraction of date for GEE
  
  lagNum <- as.numeric(lag)
  
  
  datTable <- read_csv(data)
  
  
  fileNameTemplate <- data %>% 
    str_replace(replacement = "5_joinGEELag", pattern =  "4_summarizeClusters")
  
  #return(fileNameTemplate)
  
  geeLag <- read_csv(extract) %>%
    mutate(
      #Date = Date - lagWeeks,
      Month = month - lagNum,
      Year = if_else(Month < 1, year - 1, year),
      Month = if_else(Month < 1, 12 - Month, Month),
      .keep = "unused"
    ) 
  
  
  joined <- datTable %>%
    left_join(geeLag, by = c("clust", "Month", "Year"))
  
  
  
  bufferDist <- extract %>%
    str_extract(pattern = "[:digit:]{4}")
  
  
  writeName2 <- fileNameTemplate %>%
    str_replace("Clust", str_c(bufferDist, "Lag", lag))
  
  
  #return(writeName2)
  
  write_csv(joined, writeName2)
  
  
  
}



pmap(allCombo, lagGEEJoin)


#list.files("Data/9_joinGEE/")

