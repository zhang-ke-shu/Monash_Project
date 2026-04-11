library(leaflet)
library(shiny)
library(tidyverse)
library(scales)
library(lubridate)
library(dplyr)
library(tidytext)
library(tidyr)

# 1. Data Preparation

df <- read.csv("ALA_PE2S12026.csv")

df_clean <- df %>%
  filter(!is.na(decimalLatitude), !is.na(decimalLongitude)) %>%
  mutate(observationDate = as.Date(observationDate)) %>%
  mutate(month = month(observationDate), year = year(observationDate)) %>%
  mutate(season = case_when(
    month %in% c(12, 1, 2) ~ "Summer",
    month %in% c(3, 4, 5)  ~ "Autumn",
    month %in% c(6, 7, 8)  ~ "Winter",
    month %in% c(9, 10, 11) ~ "Spring"
  )) %>%
  mutate(season = factor(season, levels = c("Summer", "Autumn", "Winter", "Spring")))


vis1_df <- df_clean %>%
  group_by(scientificName, season) %>%
  summarise(count = n(), .groups = "drop") %>%
  complete(season, scientificName, fill = list(count = 0)) %>%
  group_by(season) %>%
  mutate(proportion = count / sum(count)) %>%
  mutate(proportion = replace_na(proportion, 0)) %>%
  ungroup() %>%
  
  mutate(scientificName = factor(scientificName, levels = sort(unique(scientificName))))



# 2. UI

ui <- fixedPage(
  h3(strong("Australian Bird Observation Dashboard (2004-2024)"), 
             style = "text-align:center;"),
     p("Atlas of Living Australia (ALA) of 4 species",
       style = "text-align:center;"),
  hr(),
  #VIS 1
  fixedRow(
    column(7, 
           plotOutput("vis1Plot", height = "500px")
    ),
    column(5, 
           h4("VIS 1: Seasonal Distribution Analysis"),
           p("This static visualization presents a proportional breakdown of bird observations across the four Australian seasons between 2004 and 2024. By displaying the proportion within each season rather than raw counts, the chart enables a fair comparison of species distribution despite varying seasonal observation frequencies."),
           p("A primary insight is the seasonal dominance of the Swift Parrot (Lathamus discolor), which constitutes nearly half of all records in Autumn (48.1%) and Winter (44.3%). Conversely, the Little Lorikeet(Parvipsitta pusilla) reaches its peak relative abundance during the Summer months (45.4%), indicating distinct temporal shifts in species prominence throughout the year .")
    )
  ),
  
  hr(),
  
  #MAP
  fixedRow(
    column(12,
           wellPanel(
             fixedRow(
               column(6, 
                      checkboxGroupInput("speciesInput", "Filter Bird Species (Default: All):",
                                         choices = unique(df_clean$scientificName),
                                         selected = unique(df_clean$scientificName),
                                         inline = TRUE)
               ),
               column(6,
                      radioButtons("seasonInput", "Filter by Timeframe:",
                                   choices = c("Full Year", "Summer", "Autumn", "Winter", "Spring"),
                                   selected = "Full Year",
                                   inline = TRUE)
               )
             )
           ),
           leafletOutput("birdMap", height = "600px")
    )
  ),
  
  # MAP describe
  fixedRow(
    column(12,
           h4("Map: Spatial Migration Patterns"),
           p("The interactive map visualizes the spatial distribution of parrot species using proportional symbols, where marker size represents the volume of distinct observations. A critical insight revealed by the seasonal filters is the migration pattern of the Swift Parrot(Lathamus discolor). During summer, observations are concentrated in Tasmania for breeding; however, the population moves significantly toward south-eastern mainland Australia—primarily Victoria and New South Wales—during the autumn and winter months. The map also highlights the highly localized range of the endangered Orange-bellied Parrot(Neophema (Neonanodes) chrysogaster)."),
    )
  ),
  
  hr(),
  
  #Original Data Source Information
  fixedRow(
    column(12,
           tags$footer(
             p(strong("Original Data Source Information:")),
             p("Data Source: Atlas of Living Australia (ALA) — occurrence records for
         Lathamus discolor, Neophema chrysogaster, Parvipsitta pusilla,
         Parvipsitta porphyrocephala. "),
             p("URL: ", a("http://www.ala.org.au", href = "http://www.ala.org.au")),
             p("Licensor: Atlas of Living Australia "),
             p("Download: 2026")
           )
    )
  )
)



# 3. Server Logic

server <- function(input, output, session) {
  #VIS 1
  output$vis1Plot <- renderPlot({
    ggplot(vis1_df, aes(x = scientificName, y = proportion, fill = scientificName)) +
      geom_col(width = 0.3) + 
      geom_text(
        aes(label = scales::percent(proportion, accuracy = 0.1)),
        hjust = -0.1, 
        size = 2.5 
      ) +
      facet_wrap(~season, ncol = 2, scales = "fixed") + 
      coord_flip() +
      scale_y_continuous(
        labels = scales::percent, 
        limits = c(0, 0.5), 
        expand = expansion(mult = c(0, 0.15))
      ) +
      scale_fill_brewer(palette = "Set1") + 
      labs(
        title = "Proportion of Bird Species Observations by Season (2004-2024)",
        x = "Species (Scientific Name)",
        y = "Proportion of Observations (%)",
        fill = "Species Name"
      ) +
      theme_minimal() +
      theme(
        legend.position = "bottom",
        legend.text = element_text(size = 7),
        axis.text.y = element_text(size = 7),
        axis.text.x = element_text(size = 7),
        strip.text = element_text(face = "bold", size = 9), 
        plot.title = element_text(face = "bold", hjust = 0.5, size = 11),
        panel.grid.minor = element_blank()
      )
  })
  
  # MAP
  filtered_data <- reactive({
    data <- df_clean %>%
      filter(scientificName %in% input$speciesInput)
    
    if (input$seasonInput != "Full Year") {
      data <- data %>% filter(season == input$seasonInput)
    }
    
    data %>%
      group_by(decimalLatitude, decimalLongitude, scientificName, vernacularName, stateProvince) %>%
      summarise(nbr_obs = n(), .groups = "drop")
  })
  
  # Leaflet interaction
  output$birdMap <- renderLeaflet({
    pal <- colorFactor(palette = "Set1", domain = unique(df_clean$scientificName))
    leaflet(filtered_data()) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = 133.9453, lat = -30.4486, zoom = 3.5) %>%
      addCircleMarkers(
        lng = ~decimalLongitude,
        lat = ~decimalLatitude,
        radius = ~sqrt(nbr_obs) +2, 
        color = ~pal(scientificName),
        fillOpacity = 0.7,
        stroke = TRUE,
        weight = 1,
        
        # Tooltip
        label = ~paste0(
          "<strong>Observation Details</strong>",
          "<br/>Common Name: ", vernacularName,
          "<br/>Scientific Name: ", scientificName,
          "<br/>---------------------------",
          "<br/>Observations: ", nbr_obs,
          "<br/>State/Territory: ", stateProvince
        ) %>% lapply(htmltools::HTML),
        
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "8px"),
          textsize = "12px",
          direction = "auto"
        )
      ) %>%
      addLegend(
        pal = pal, 
        values = ~scientificName, 
        title = "Bird Species", 
        position = "bottomright"
      )
  })}



# run shiny
shinyApp(ui = ui, server = server)