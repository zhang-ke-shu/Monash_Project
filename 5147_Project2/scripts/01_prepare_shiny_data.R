library(dplyr)
library(readr)


analysis_data <- read_csv("data/analysis_data.csv")

# 1. 基础清理
analysis_clean <- analysis_data %>%
  mutate(
    species = as.character(species),
    year = as.integer(year),
    month = as.integer(month),
    individualCount_clean = ifelse(is.na(individualCount), 1, individualCount),
    ERP_Density = as.numeric(ERP_Density),
    avg_rad = as.numeric(avg_rad),
    AREASQKM = as.numeric(AREASQKM)
  ) %>%
  filter(
    !is.na(species),
    !is.na(decimalLatitude),
    !is.na(decimalLongitude),
    !is.na(year),
    !is.na(month),
    !is.na(LGA_CODE25),
    !is.na(ERP_Density),
    !is.na(avg_rad)
  )

# 2. Species summary：Step 1 用
species_summary <- analysis_clean %>%
  group_by(species) %>%
  summarise(
    total_observations = n(),
    total_individuals = sum(individualCount_clean, na.rm = TRUE),
    main_state = names(sort(table(stateProvince), decreasing = TRUE))[1],
    .groups = "drop"
  )

# 3. Map data：中间澳洲地图用
# 这里先按 LGA + species + year + month 聚合，避免 Shiny 直接加载上百万点
map_data <- analysis_clean %>%
  group_by(LGA_CODE25, LGA_NAME25, species, year, month) %>%
  summarise(
    obs_count = n(),
    individual_total = sum(individualCount_clean, na.rm = TRUE),
    lat = mean(decimalLatitude, na.rm = TRUE),
    lon = mean(decimalLongitude, na.rm = TRUE),
    ERP_Density = mean(ERP_Density, na.rm = TRUE),
    avg_rad = mean(avg_rad, na.rm = TRUE),
    area_sqkm = mean(AREASQKM, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    obs_density = obs_count / area_sqkm
  )

# 4. Calendar data：Step 2 的月份热力图用
calendar_data <- analysis_clean %>%
  group_by(species, month) %>%
  summarise(
    obs_count = n(),
    .groups = "drop"
  )

# 5. Human density relationship：Step 3 用
density_relation_data <- analysis_clean %>%
  group_by(LGA_CODE25, LGA_NAME25, species) %>%
  summarise(
    obs_count = n(),
    individual_total = sum(individualCount_clean, na.rm = TRUE),
    area_sqkm = mean(AREASQKM, na.rm = TRUE),
    ERP_Density = mean(ERP_Density, na.rm = TRUE),
    avg_rad = mean(avg_rad, na.rm = TRUE),
    lat = mean(decimalLatitude, na.rm = TRUE),
    lon = mean(decimalLongitude, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    obs_density = obs_count / area_sqkm,
    log_human_density = log10(ERP_Density + 1),
    log_obs_density = log10(obs_density + 1)
  )

# 6. Urban zone data：Step 4 用
human_threshold <- median(density_relation_data$ERP_Density, na.rm = TRUE)
light_threshold <- median(density_relation_data$avg_rad, na.rm = TRUE)

zone_data <- density_relation_data %>%
  mutate(
    human_level = ifelse(
      ERP_Density >= human_threshold,
      "High human density",
      "Low human density"
    ),
    light_level = ifelse(
      avg_rad >= light_threshold,
      "High nightlight",
      "Low nightlight"
    ),
    urban_zone = case_when(
      human_level == "High human density" & light_level == "High nightlight" ~ "Bright Urban",
      human_level == "High human density" & light_level == "Low nightlight" ~ "Dark Island",
      human_level == "Low human density" & light_level == "High nightlight" ~ "Bright Rural",
      TRUE ~ "Quiet Rural"
    )
  )

# 7. 输出给 Shiny 使用的 CSV
write_csv(species_summary, "data/species_summary.csv")
write_csv(map_data, "data/map_data.csv")
write_csv(calendar_data, "data/calendar_data.csv")
write_csv(density_relation_data, "data/density_relation_data.csv")
write_csv(zone_data, "data/zone_data.csv")

cat("Shiny data files created successfully.\n")