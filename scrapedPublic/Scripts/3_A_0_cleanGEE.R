library(tidyverse)
library(lubridate)


buffers <- list("bird1500", "bird2000", "bird3000",
                "pool1500", "pool2000", "pool3000",
                "sentinel1500", "sentinel2000", "sentinel3000")

# Read in Data ------------------------------------------------------------


read_csv("./extractions/sentinel1500CHIRPS.csv")


cleanFunction <- function(buffer) {  
  
  chirpsReadName <- str_c("extractions/", buffer, "CHIRPS.csv")
  
  
  #Floor date down to julien weeks
  chirps <- read_csv(chirpsReadName) %>% 
    mutate(
      #Date = as_datetime(Date) %>% date() - ddays(3),
      chirpsMean = ifelse("mean" %in% colnames(.), mean, NA),
      .keep = "unused"
    )
  
  
  
  grid1ReadName <- str_c("extractions/", buffer, "MeanGrid.csv")
  
  
  gridmet1 <- read_csv(grid1ReadName) 
  
  
  grid2ReadName <- str_c("extractions/", buffer, "SumGrid.csv")
  
  
  gridmet2 <- read_csv(grid2ReadName) %>% 
    select(month, year, clust, mean) %>% 
    mutate(
      `Precip Mean mm / day` = mean,
      .keep = "unused"
    )
  
  
  gridmet <- gridmet1 %>% 
    left_join(gridmet2, by = c("year", "month", "clust"))
  
  
  
  modisReadName <- str_c("extractions/", buffer, "MODIS.csv")
  
  
  #Convert seconds since epoch to date
  modis <- read_csv(modisReadName)
  
  
  
  
  jrcReadName <- str_c("extractions/", buffer, "JRC.csv")
  
  
  #Format month/year and year as first day of time periods
  jrc <- read_csv(jrcReadName) %>% 
    mutate(
      jrcDate = str_replace(Date, "_", "-") %>% str_c("-01") %>% as_datetime(),
      year = year(jrcDate),
      month = month(jrcDate),
      jrcStandingWater = sum,
      .keep = "unused"
    ) %>% 
    select(-jrcDate)
  
  # 
  # irrReadName <- str_c("extractions/cluster", buffer, "IRR.csv")
  # 
  # 
  # irr <- read_csv(irrReadName) %>% 
  #   mutate(
  #     irrDate = str_c(Date, "-01-01") %>% as_datetime(),
  #     irrWater = sum,
  #     .keep = "unused"
  #   )
  # 
  
  droughtReadName <- str_c("extractions/", buffer, "Drought.csv")
  
  drought <- read_csv(droughtReadName)
  
  
  
  
  # Join  Tables ------------------------------------------------------------
  
  #return(chirps)
  
  totalJoin <- chirps %>% 
    left_join(gridmet, by = c("clust", "year", "month")) %>% 
    left_join(modis, by = c("clust", "year", "month")) %>% 
    left_join(jrc, by = c("clust", "year", "month")) %>% 
    # # left_join(irr, by = c("clust", "irrDate")) %>% 
    left_join(drought, by = c("clust", "year", "month")) %>% 
    select(-starts_with("system")) %>%
    select(-starts_with(".geo")) #%>%
    # #select(-matches("...year")) %>% 
    # #select(-matches("...month"))
    # 
  
  finalWriteName <- str_c("./extractions/extract", buffer, "Clean.csv")
  
  #return(totalJoin)
  
  write_csv(totalJoin, finalWriteName)
  
}  

map(buffers, cleanFunction)

#cleanFunction(buffers[[1]])

