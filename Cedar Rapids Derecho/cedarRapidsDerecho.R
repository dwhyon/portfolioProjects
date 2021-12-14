library(tidyverse)

#Read in Land cover metrics extracted from Google earth Engine
ugly <- read_csv("landCoverArea.csv")


#Clean and parse raw data to separate from Area table
change <- ugly %>%
  select(-c(".geo", "system:index"))%>%
  select(matches("^.0"))


#Initial formatting
change1 <- change %>%
  #pivot to create proper long formatting
  pivot_longer(colnames(change), names_to = "Code", values_to = "Pixels") %>%
  transmute(
    #split single change code into before and after columns
    Class2019 = str_sub(Code, 1, 1),
    Class2021 = str_sub(Code, 3),
    Pixels = Pixels,
  ) %>%
  group_by(Class2019) 

#dictionary to convert numeric codes to string
key <- tribble(
  ~Class, ~Code,
  #Class, Class number
  "Vegetation", '1',
  "Built Up", '2',
  "Water", '3',
  "Field", '4'
)


#format change table
changeFinal <- change1 %>%
  #Replace numeric codes with strings
  left_join(key, c("Class2019" = "Code")) %>%
  mutate(
    Class2019 = Class
  ) %>%
  #get rid of numeric code
  select(-c("Class")) %>%
  #repeat for 2021
  left_join(key, c("Class2021" = "Code")) %>%
  mutate(
    Class2021 = Class
  ) %>%
  select(-c("Class")) %>%
  #format with 2021 as the first column
  select(Class2021, everything()) %>%
  #Join to total pixel table
  left_join(
    #Finds total pixels for each 2019 class
    changeFinal %>%
    group_by(Class2019) %>%
    summarise(
      total2019 = sum(Pixels)
    )
  ) %>%
  #Repeat for 2021
  left_join(
    changeFinal %>%
      group_by(Class2021) %>%
      summarise(
        total2021 = sum(Pixels)
      )
  ) %>%
  #Group and find proportion of pixels to get
  #Percent change
  group_by(Class2019) %>%
  mutate(
    proportion2019 = Pixels / total2019
  ) %>%
  #Repeat for 2021
  group_by(total2021) %>%
  mutate(
    proportion2021 = Pixels / total2021
  ) %>%
  #Ungroup and remove total columns
  ungroup() %>%
  select(-c("total2021", "total2019"))




# Unused
changeFrom <- changeFinal %>% 
  pivot_wider(names_from = Class2019, values_from = Pixels)
#Unused
changeTo <- changeFinal %>%
  pivot_wider(names_from = Class2021, values_from = Pixels)


#Format area tables


#Find all relevant columns using string regex
lc <- ugly %>%
  #Starts with non digit, then transitions to a digit
  #THis follows naming format landcoverclassYEAR, eg. Urban2020
  select(matches("^\\D+\\d"))


#Final Formatting 
lc1 <- lc %>%
  #pivot table
  pivot_longer(colnames(lc), names_to = "Class", values_to = "Area") %>%
  # format data and convert to sq miles
  mutate(
    Year = str_sub(Class, -2),
    Class = str_replace(Class, Year, ""),
    Area = Area / 2.59e+6,
    Year = str_c("20", Year)
  ) %>% 
  pivot_wider(names_from = Year, values_from = Area) %>% 
  #calculate percent change 
  mutate(
    percentChange = (`2021` -`2019`) / `2019`
  )



#Replace format BuiltUp to be more human readable
lc2 <- lc1
lc2$Class[lc2$Class == "BuiltUp"] <- "Built Up"


#Export as csv


write_csv(lc2, "ClassArea.csv")

write_csv(changeFinal, "ClassChange.csv")

#write_csv(changeTo, "2019ChangeStatistics.csv")

#write_csv(changeFrom, "2021ChangeStatistics.csv")

