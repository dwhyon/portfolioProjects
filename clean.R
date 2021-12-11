library(tidyverse)

ugly <- read_csv("landCoverArea.csv")

change <- ugly %>%
  select(-c(".geo", "system:index"))%>%
  select(matches("^.0"))

change1 <- change %>%
  pivot_longer(colnames(change), names_to = "Code", values_to = "Pixels") %>%
  transmute(
    Class2019 = str_sub(Code, 1, 1),
    Class2021 = str_sub(Code, 3),
    Pixels = Pixels,
  ) %>%
  group_by(Class2019) %>%
  mutate(
    Sum = sum(Pixels),
    PercentChange = Pixels / Sum
  ) %>%
  select(-c(Sum))


lc <- ugly %>%
  select(matches("^\\D+\\d"))

lc1 <- lc %>%
  pivot_longer(colnames(lc), names_to = "Class", values_to = "Area") %>%
  mutate(
    Year = str_sub(Class, -2),
    Class = str_replace(Class, Year, ""),
    Area = Area / 2.59e+6,
    Year = str_c("20", Year)
  )

key <- tribble(
  ~Class, ~Code,
  #Class, Class number
  "Vegetation", '1',
  "BuiltUp", '2',
  "Water", '3',
  "Fields", '4'
)

changeFinal <- change1 %>%
  left_join(key, c("Class2019" = "Code")) %>%
  mutate(
    Class2019 = Class
  ) %>%
  select(-c("Class")) %>%
  left_join(key, c("Class2021" = "Code")) %>%
  mutate(
    Class2021 = Class
  ) %>%
  select(-c("Class"))


write_csv(lc1, "ClassArea.csv")

write_csv(changeFinal, "ClassChange.csv")
