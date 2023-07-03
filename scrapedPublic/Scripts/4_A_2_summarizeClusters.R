


# Packages ----------------------------------------------------------------

library(sf)
library(tidyverse)
library(tmap)
library(lubridate)
library(scales)
library(splines2)
library(zoo)


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




birdSum <- sumFunc(bird)

poolSum <- sumFunc(pool)


sentSum <- sumFunc(sent)



glimpse(poolSum)

ggplot(data = poolSum, mapping = aes(x = Year, y = Month)) +
  geom_point()

# 
# # Write out
# write_csv(MIR, "./Data/5_summarizeClusters/testPIRMIRClusterTEST.csv")


poolSplit <- poolSum %>% 
  group_split(Year)



# Interpolate WNV ---------------------------------------------------------




# For test data
setSampleRange2 <- function(tibble) {
  
  # Subset table to first weeks with non 0 results
  nonZero <- tibble %>% 
    filter(Count > 0)
  
  # Get first week of year
  start <- min(nonZero$Month)
  # Last week of year
  end <- max(nonZero$Month)
  
  # Get table of min / max weeks for each cluster
  # If outside the range of positive results, remove
  # This yields table with 
  toBeTailed <- tibble %>% 
    group_by(clust) %>%
    # Get first and last week cluster sampled
    summarize(
      min = min(Month), 
      max = max(Month)
    ) %>% 
    # If outside pos range set to -99
    mutate(
      min = if_else(min <= start, -99, min),
      max = if_else(max >= end, -99, max)
    ) %>% 
    # Pivot and filter to get table of minimum and maximum 
    # that needs to be imputed per each cluster
    pivot_longer(
      cols = min:max,
      names_to = "tail",
      values_to = "Month"
    ) %>% 
    filter(Month > 0) %>% 
    select(-Month)
  
  # Convert "min" and "max" to range Month 
  tail <- tribble(
    ~tail, ~Month,
    "min", start,
    "max", end
  )
  
  # Join to main table with 0's for mosquito values at 
  # boundaries
  joinTable <- toBeTailed %>% 
    left_join(tail, by = "tail") %>% 
    select(-tail) %>% 
    mutate(
      Count = 0
    )
  
  
  tibble %>% 
    bind_rows(joinTable) %>% 
    fill(Year, .direction = "updown") %>% 
    arrange(clust, Year, Month)
  
  
  
}


poolRange <- map(poolSplit, setSampleRange2) %>% 
  bind_rows() %>% 
  group_split(clust, Year)



# Interpolate -------------------------------------------------------------


# Create vector of every Month between start and end sample dates
minMaxFunc <- function(table) {
  
  min <- min(table$Month)
  
  max <- max(table$Month)
  
  seq(min, max, 1)
}



# Testing Interpolation ---------------------------------------------------



testFunc <- function(table) {
  
  # If else to account for clusters with only 1 obs in a year
  if(nrow(table) > 1) {
    # Get weeks of year in range for 
    weeks <- table %>% 
      minMaxFunc() %>% 
      enframe(name = NULL, value = "Month")
    
    
    
    # Weeks with Data
    tableWeeks <- table %>%
      distinct(Month) %>% 
      full_join(weeks, by = "Month")
    
    
    
    # Missing weeks of data
    missingWeeks <- weeks %>%
      setdiff(tableWeeks)
    
    
    # Join
    joinTableRaw <- table %>%
      full_join(weeks, by = "Month") %>%
      arrange(Month) %>% 
      fill(clust) %>% 
      fill(Year) #%>% 
      # mutate(
      #   rowNum = row_number()
      # )
    
    
    
    
    # Linear Interpolations of Missing Data
    linTable <- joinTableRaw %>% 
      mutate(
        CountLinear = na.approx(Count)
      )
    
    
    #return(linTable)
    
    
    # Create Spline functions
    countSplineFun <- splinefun(table$Month, 
                              table$Count, 
                              method = "monoH.FC")
    
    
    # Spline interpolations of Missing Data
    totalFill <- linTable %>% 
      mutate(
        CountSpline = countSplineFun(Month)
        
      )
    
    return(totalFill)
    
  } else {
    
    
    # If only one year copy data over to interpolated columns
    clean <- table %>% 
      mutate(
        CountLinear = Count,
        CountSpline = Count
      )
    
    
    
    return(clean)
    
  }
  
}



poolInterp <- map(poolRange, testFunc) %>% 
  bind_rows()


# Infer 0's for rest of year ----------------------------------------------


# Make grid of all possible dates as well as clusters to fill 0's in
# extrapolated data

# Vector of all clusters

clustsTest <- poolInterp %>% 
  pull(clust) %>% 
  unique()

# Vector of all years
yrs <- seq(2003, 2022, 1)

# Vector of all weeks for year
mnths <- seq(1, 12, 1)



# Create all possible combinations of year + week 
allMonths <- expand_grid(yrs, mnths) %>% 
  mutate(
    Year = yrs,
    Month = mnths,
    .keep = "unused"
  ) 


testWClust <- allMonths %>% 
  #unite(col = "wy", c(yrs, mnths), remove = FALSE) %>% 
  expand_grid(clustsTest)


testWeeks <- poolInterp %>% 
  #unite(col = "wy", c(Year, Month), remove = FALSE) %>% 
  full_join(testWClust, by = c("Year", "Month", "clust" = "clustsTest")) %>% 
  #separate(wy, c("year", "woy"), remove = FALSE) %>% 
  mutate(
    Year = as.numeric(Year),
    Month = as.numeric(Month)
  ) %>% 
  select(-ends_with("x")) %>%
  select(-ends_with(".y")) %>% 
  select(clust, Year, Month, everything()) %>%
  mutate(
    across(starts_with("Count"), ~replace_na(., 0))
  ) 


testWeeks %>% 
  filter(if_any(everything(), is.na))  %>% 
  #group_by(clust, Month, Year) %>% 
  select_if(function(x) any(is.na(x)))





write_csv(sentSum, "./Data/4_summarizeClusters/sentinelClust.csv")
write_csv(birdSum, "./Data/4_summarizeClusters/birdClust.csv")
write_csv(testWeeks, "./Data/4_summarizeClusters/poolClust.csv")

