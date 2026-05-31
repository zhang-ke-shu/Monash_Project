# install.packages(c("shiny", "dplyr", "readr", "tidyr", "leaflet", "ggplot2", "plotly", "sf"))

library(shiny)
library(dplyr)
library(readr)
library(tidyr)
library(leaflet)
library(ggplot2)
library(plotly)
library(sf)

# ----------------------------
# Load prepared data
# ----------------------------

map_data <- read_csv("data/map_data.csv", show_col_types = FALSE)
calendar_data <- read_csv("data/calendar_data.csv", show_col_types = FALSE)
species_summary <- read_csv("data/species_summary.csv", show_col_types = FALSE)
density_relation_data <- read_csv("data/density_relation_data.csv", show_col_types = FALSE)
zone_data <- read_csv("data/zone_data.csv", show_col_types = FALSE)

lga_boundary <- st_read("data/LGA_2025_AUST_GDA2020.shp", quiet = TRUE) %>%
  st_transform(4326) %>%
  mutate(
    LGA_CODE25 = as.character(LGA_CODE25)
  ) %>%
  st_make_valid() %>%
  st_simplify(dTolerance = 0.03, preserveTopology = TRUE)

lga_light_layer <- read_csv(
  "data/LGA_2025_VIIRS_avg_rad_2020_2024.csv",
  show_col_types = FALSE
) %>%
  mutate(
    LGA_CODE25 = as.character(LGA_CODE25)
  )

if ("avg_rad" %in% names(lga_light_layer) &&
    !"avg_rad_2020_2024" %in% names(lga_light_layer)) {
  lga_light_layer <- lga_light_layer %>%
    rename(avg_rad_2020_2024 = avg_rad)
}

# ----------------------------
# Colours and labels
# ----------------------------

species_levels <- c(
  "Cacatua galerita",
  "Trichoglossus moluccanus",
  "Eolophus roseicapilla"
)

species_colours <- c(
  "Cacatua galerita" = "#E84A5F",
  "Trichoglossus moluccanus" = "#2EAD4F",
  "Eolophus roseicapilla" = "#4C78A8"
)

pretty_species <- c(
  "Cacatua galerita" = "Sulphur-crested Cockatoo",
  "Trichoglossus moluccanus" = "Rainbow Lorikeet",
  "Eolophus roseicapilla" = "Galah"
)

zone_colours <- c(
  "Bright Urban" = "#E76F51",
  "Dark Island" = "#2A9D8F",
  "Bright Rural" = "#F4A261",
  "Quiet Rural" = "#8AB17D"
)

zone_lookup_lga <- zone_data %>%
  filter(!is.na(urban_zone)) %>%
  count(LGA_CODE25, urban_zone, sort = TRUE) %>%
  group_by(LGA_CODE25) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(LGA_CODE25, urban_zone)

make_radius <- function(x) {
  pmin(sqrt(x) * 0.24 + 1.8, 7.5)
}

make_bg_radius <- function(x) {
  pmin(sqrt(x) * 0.22 + 2, 8.5)
}

# ----------------------------
# Helper for selected map symbols
# ----------------------------

add_point_style <- function(data, selected, colour_column, base_opacity) {
  data$is_selected <- FALSE
  
  if (!is.null(selected)) {
    data$is_selected <- as.character(data$LGA_CODE25) == as.character(selected)
  }
  
  if (is.null(selected)) {
    data$point_opacity <- base_opacity
    data$point_weight <- 1
    data$point_stroke_colour <- data[[colour_column]]
  } else {
    data$point_opacity <- ifelse(data$is_selected, base_opacity, 0.12)
    data$point_weight <- ifelse(data$is_selected, 4, 1)
    data$point_stroke_colour <- ifelse(
      data$is_selected,
      "#000000",
      data[[colour_column]]
    )
  }
  
  data
}

apply_alpha <- function(cols, alphas) {
  unname(mapply(
    function(col, alpha) {
      grDevices::adjustcolor(col, alpha.f = alpha)
    },
    cols,
    alphas
  ))
}

# ----------------------------
# Pre-render background overlays as PNG
# Use gridded overlays instead of full polygons for clearer and more realistic background
# ----------------------------

dir.create("www", showWarnings = FALSE)

human_density_breaks <- c(0, 1, 5, 10, 25, 50, 100, 250, 500, 1000, Inf)
human_density_labels <- c(
  "0-1",
  "1-5",
  "5-10",
  "10-25",
  "25-50",
  "50-100",
  "100-250",
  "250-500",
  "500-1,000",
  "1,000+"
)

human_density_base_colours <- c(
  "#f6f1fb",
  "#e6d8f5",
  "#d4bee9",
  "#bea2dc",
  "#a785cf",
  "#8d67bf",
  "#7449ad",
  "#5d3793",
  "#472777",
  "#31185a"
)

human_density_alpha <- c(0.05, 0.08, 0.12, 0.18, 0.24, 0.32, 0.42, 0.52, 0.62, 0.72)
human_density_colours <- apply_alpha(human_density_base_colours, human_density_alpha)

night_light_breaks <- c(0, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 20, Inf)
night_light_labels <- c(
  "0-0.05",
  "0.05-0.1",
  "0.1-0.25",
  "0.25-0.5",
  "0.5-1",
  "1-2",
  "2-5",
  "5-10",
  "10-20",
  "20+"
)

night_light_base_colours <- c(
  "#fffde7",
  "#fff7bc",
  "#fee391",
  "#fec44f",
  "#fe9929",
  "#ec7014",
  "#cc4c02",
  "#993404",
  "#7f2704",
  "#4d1f00"
)

night_light_alpha <- c(0.06, 0.10, 0.16, 0.22, 0.30, 0.40, 0.50, 0.60, 0.70, 0.82)
night_light_colours <- apply_alpha(night_light_base_colours, night_light_alpha)

background_point_data <- map_data %>%
  mutate(
    LGA_CODE25 = as.character(LGA_CODE25)
  ) %>%
  group_by(LGA_CODE25) %>%
  summarise(
    lon = mean(lon, na.rm = TRUE),
    lat = mean(lat, na.rm = TRUE),
    ERP_Density = mean(ERP_Density, na.rm = TRUE),
    avg_rad = mean(avg_rad, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(
    !is.na(lon),
    !is.na(lat)
  ) %>%
  mutate(
    ERP_Density = ifelse(is.nan(ERP_Density) | is.infinite(ERP_Density) | ERP_Density < 0, NA_real_, ERP_Density),
    avg_rad = ifelse(is.nan(avg_rad) | is.infinite(avg_rad) | avg_rad < 0, NA_real_, avg_rad)
  )

overlay_bbox_4326 <- st_bbox(lga_boundary)
overlay_bounds <- list(
  c(as.numeric(overlay_bbox_4326["ymin"]), as.numeric(overlay_bbox_4326["xmin"])),
  c(as.numeric(overlay_bbox_4326["ymax"]), as.numeric(overlay_bbox_4326["xmax"]))
)

boundary_3857 <- st_transform(lga_boundary, 3857)
bbox_3857 <- st_bbox(boundary_3857)

background_points_sf <- st_as_sf(
  background_point_data,
  coords = c("lon", "lat"),
  crs = 4326,
  remove = FALSE
) %>%
  st_transform(3857)

grid_cellsize <- 180000

grid_sf <- st_make_grid(
  boundary_3857,
  cellsize = c(grid_cellsize, grid_cellsize),
  square = TRUE
) %>%
  st_sf(grid_id = seq_along(.), geometry = .)

point_grid_join <- st_join(
  background_points_sf,
  grid_sf,
  join = st_within,
  left = FALSE
)

grid_summary <- point_grid_join %>%
  st_drop_geometry() %>%
  group_by(grid_id) %>%
  summarise(
    ERP_Density = mean(ERP_Density, na.rm = TRUE),
    avg_rad = mean(avg_rad, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    ERP_Density = ifelse(is.nan(ERP_Density) | is.infinite(ERP_Density), NA_real_, ERP_Density),
    avg_rad = ifelse(is.nan(avg_rad) | is.infinite(avg_rad), NA_real_, avg_rad)
  )

overlay_grid_sf <- grid_sf %>%
  left_join(grid_summary, by = "grid_id") %>%
  filter(!is.na(ERP_Density) | !is.na(avg_rad)) %>%
  st_intersection(st_union(st_geometry(boundary_3857))) %>%
  st_make_valid() %>%
  mutate(
    human_density_bin = cut(
      ERP_Density,
      breaks = human_density_breaks,
      labels = human_density_labels,
      include.lowest = TRUE,
      right = FALSE
    ),
    night_light_bin = cut(
      avg_rad,
      breaks = night_light_breaks,
      labels = night_light_labels,
      include.lowest = TRUE,
      right = FALSE
    )
  )

overlay_width_m <- as.numeric(bbox_3857["xmax"] - bbox_3857["xmin"])
overlay_height_m <- as.numeric(bbox_3857["ymax"] - bbox_3857["ymin"])
overlay_aspect <- overlay_width_m / overlay_height_m

overlay_image_height <- 1700
overlay_image_width <- round(overlay_image_height * overlay_aspect)

create_overlay_png <- function(sf_data, class_col, output_file, colours, labels, na_colour = "#00000000") {
  grDevices::png(
    filename = output_file,
    width = overlay_image_width,
    height = overlay_image_height,
    res = 180,
    bg = "transparent",
    type = "cairo"
  )
  
  p <- ggplot(sf_data) +
    geom_sf(
      aes(fill = .data[[class_col]]),
      color = NA,
      linewidth = 0
    ) +
    scale_fill_manual(
      values = setNames(colours, labels),
      na.value = na_colour,
      drop = FALSE
    ) +
    coord_sf(
      crs = st_crs(3857),
      xlim = c(as.numeric(bbox_3857["xmin"]), as.numeric(bbox_3857["xmax"])),
      ylim = c(as.numeric(bbox_3857["ymin"]), as.numeric(bbox_3857["ymax"])),
      expand = FALSE
    ) +
    theme_void() +
    theme(
      legend.position = "none",
      plot.margin = margin(0, 0, 0, 0),
      plot.background = element_rect(fill = "transparent", colour = NA),
      panel.background = element_rect(fill = "transparent", colour = NA)
    )
  
  print(p)
  grDevices::dev.off()
}

create_overlay_png(
  sf_data = overlay_grid_sf,
  class_col = "human_density_bin",
  output_file = "www/human_density_layer.png",
  colours = human_density_colours,
  labels = human_density_labels,
  na_colour = "#00000000"
)

create_overlay_png(
  sf_data = overlay_grid_sf,
  class_col = "night_light_bin",
  output_file = "www/nighttime_light_layer.png",
  colours = night_light_colours,
  labels = night_light_labels,
  na_colour = "#00000000"
)

# ----------------------------
# UI
# ----------------------------

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color: #ffffff;
        font-family: Arial, Helvetica, sans-serif;
      }

      .app-title {
        font-size: 28px;
        font-weight: 700;
        margin-top: 10px;
        margin-bottom: 2px;
      }

      .app-subtitle {
        font-size: 15px;
        color: #555555;
        margin-bottom: 12px;
      }

      .panel-card {
        background-color: #f7f7f7;
        border-radius: 12px;
        padding: 14px;
        margin-bottom: 14px;
        border: 1px solid #e3e3e3;
      }

      .narrative-card {
        background-color: #f5f5f5;
        border-radius: 12px;
        padding: 15px 18px;
        margin-bottom: 14px;
        border-left: 6px solid #4C78A8;
      }

      .control-title {
        font-size: 18px;
        font-weight: 700;
        margin-bottom: 10px;
      }

      .selected-title {
        font-size: 16px;
        font-weight: 700;
        margin-bottom: 8px;
      }

      .selected-line {
        font-size: 13px;
        margin-bottom: 6px;
      }

      .small-note {
        font-size: 12px;
        color: #666666;
        line-height: 1.35;
      }
    ")),
    
    tags$script(HTML("
      $(document).on('mouseleave', '#map', function() {
        Shiny.setInputValue('map_mouseout', Math.random(), {priority: 'event'});
      });

      var currentBackgroundOverlay = null;

      Shiny.addCustomMessageHandler('backgroundOverlay', function(message) {
        var widget = HTMLWidgets.find('#map');

        if (!widget) {
          return;
        }

        var map = widget.getMap();

        if (currentBackgroundOverlay) {
          map.removeLayer(currentBackgroundOverlay);
          currentBackgroundOverlay = null;
        }

        if (message.action === 'add') {
          if (!map.getPane('backgroundOverlayPane')) {
            map.createPane('backgroundOverlayPane');
            map.getPane('backgroundOverlayPane').style.zIndex = 360;
          }

          currentBackgroundOverlay = L.imageOverlay(
            message.url,
            message.bounds,
            {
              opacity: message.opacity,
              pane: 'backgroundOverlayPane',
              interactive: false
            }
          );

          currentBackgroundOverlay.addTo(map);
        }
      });
    "))
  ),
  
  div(class = "app-title", "Urban Parrots and City Environments"),
  div(
    class = "app-subtitle",
    "Human density, nighttime light, and common parrot observations in Australia"
  ),
  
  uiOutput("narrative_panel"),
  
  fluidRow(
    column(
      width = 3,
      
      div(
        class = "panel-card",
        div(class = "control-title", "Control Panel"),
        
        radioButtons(
          inputId = "story_step",
          label = "Story step:",
          choices = c(
            "Step 1: Meet the parrots",
            "Step 2: Where and when?",
            "Step 3: Human density",
            "Step 4: Nighttime light"
          ),
          selected = "Step 1: Meet the parrots"
        ),
        
        selectInput(
          inputId = "species_filter",
          label = "Choose species:",
          choices = c("All", sort(unique(map_data$species))),
          selected = "All"
        ),
        
        sliderInput(
          inputId = "month_filter",
          label = "Choose month range:",
          min = 1,
          max = 12,
          value = c(1, 12),
          step = 1
        )
      ),
      
      div(
        class = "panel-card",
        div(class = "control-title", "Linked Insight Chart"),
        plotlyOutput("linked_chart", height = "390px")
      )
    ),
    
    column(
      width = 7,
      leafletOutput("map", height = "720px")
    ),
    
    column(
      width = 2,
      div(
        class = "panel-card",
        uiOutput("selected_location")
      ),
      
      div(
        class = "panel-card",
        uiOutput("step_guide")
      ),
      
      div(
        class = "panel-card",
        div(class = "selected-title", "Caution"),
        div(
          class = "small-note",
          "Observation records show where birds were reported. They do not directly prove true habitat preference, and may also reflect where people are more likely to observe and record birds."
        )
      )
    )
  )
)

# ----------------------------
# Server
# ----------------------------

server <- function(input, output, session) {
  
  selected_lga <- reactiveVal(NULL)
  
  output$narrative_panel <- renderUI({
    if (input$story_step == "Step 1: Meet the parrots") {
      div(
        class = "narrative-card",
        h4("Step 1: Meet the parrots — who are the main characters?"),
        p("This story begins with three common Australian parrots: Sulphur-crested Cockatoo, Rainbow Lorikeet, and Galah."),
        p("Use the map to see where these species are recorded. Symbol size represents observation volume, while colour identifies the dominant or selected species.")
      )
    } else if (input$story_step == "Step 2: Where and when?") {
      div(
        class = "narrative-card",
        h4("Step 2: Where and when are they observed?"),
        p("This step connects spatial and seasonal patterns. The map shows where observations occur, while the linked chart shows how observation counts change across months."),
        p("Use the month filter to focus on part of the year, or click a map symbol to inspect one LGA.")
      )
    } else if (input$story_step == "Step 3: Human density") {
      div(
        class = "narrative-card",
        h4("Step 3: How do observations relate to human density?"),
        p("This step adds human population density as an urban context. The transparent purple background overlay represents human density, while coloured parrot symbols show observation volume."),
        p("The linked scatter plot compares human density and observation count. Clicking a map symbol highlights the selected LGA in the chart.")
      )
    } else {
      div(
        class = "narrative-card",
        h4("Step 4: What about nighttime light?"),
        p("This step adds nighttime light as another urban factor. The transparent orange background overlay represents nighttime light intensity, while coloured parrot symbols show where parrots are recorded."),
        p("The linked heat chart uses a four-quadrant structure to compare observation counts across human density and nighttime light.")
      )
    }
  })
  
  filtered_base <- reactive({
    map_data %>%
      filter(
        month >= input$month_filter[1],
        month <= input$month_filter[2]
      )
  })
  
  all_species_map <- reactive({
    long_data <- filtered_base() %>%
      group_by(LGA_CODE25, LGA_NAME25, species) %>%
      summarise(
        obs_count = sum(obs_count, na.rm = TRUE),
        lat = mean(lat, na.rm = TRUE),
        lon = mean(lon, na.rm = TRUE),
        ERP_Density = mean(ERP_Density, na.rm = TRUE),
        avg_rad = mean(avg_rad, na.rm = TRUE),
        obs_density = mean(obs_density, na.rm = TRUE),
        .groups = "drop"
      )
    
    wide_data <- long_data %>%
      select(LGA_CODE25, LGA_NAME25, species, obs_count) %>%
      pivot_wider(
        names_from = species,
        values_from = obs_count,
        values_fill = 0
      )
    
    for (sp in species_levels) {
      if (!sp %in% names(wide_data)) {
        wide_data[[sp]] <- 0
      }
    }
    
    meta_data <- long_data %>%
      group_by(LGA_CODE25, LGA_NAME25) %>%
      summarise(
        total_obs = sum(obs_count, na.rm = TRUE),
        lat = mean(lat, na.rm = TRUE),
        lon = mean(lon, na.rm = TRUE),
        ERP_Density = mean(ERP_Density, na.rm = TRUE),
        avg_rad = mean(avg_rad, na.rm = TRUE),
        obs_density = mean(obs_density, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      left_join(zone_lookup_lga, by = "LGA_CODE25")
    
    out <- meta_data %>%
      left_join(wide_data, by = c("LGA_CODE25", "LGA_NAME25"))
    
    out$dominant_species <- species_levels[
      max.col(as.matrix(out[, species_levels]), ties.method = "first")
    ]
    
    out$dominant_colour <- unname(species_colours[out$dominant_species])
    out$dominant_label <- unname(pretty_species[out$dominant_species])
    
    out
  })
  
  long_species_map <- reactive({
    data <- filtered_base() %>%
      group_by(LGA_CODE25, LGA_NAME25, species) %>%
      summarise(
        obs_count = sum(obs_count, na.rm = TRUE),
        lat = mean(lat, na.rm = TRUE),
        lon = mean(lon, na.rm = TRUE),
        ERP_Density = mean(ERP_Density, na.rm = TRUE),
        avg_rad = mean(avg_rad, na.rm = TRUE),
        obs_density = mean(obs_density, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      left_join(zone_lookup_lga, by = "LGA_CODE25") %>%
      mutate(
        species_colour = unname(species_colours[species]),
        species_label = unname(pretty_species[species])
      )
    
    if (input$species_filter != "All") {
      data <- data %>% filter(species == input$species_filter)
    }
    
    data
  })
  
  observeEvent(input$map_marker_click, {
    selected_lga(input$map_marker_click$id)
  })
  
  observeEvent(input$map_mouseout, {
    selected_lga(NULL)
  })
  
  observeEvent(input$species_filter, {
    selected_lga(NULL)
  })
  
  observeEvent(input$month_filter, {
    selected_lga(NULL)
  })
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Voyager) %>%
      setView(lng = 134, lat = -27, zoom = 4)
  })
  
  observe({
    step <- input$story_step
    selected <- selected_lga()
    
    session$sendCustomMessage(
      "backgroundOverlay",
      list(action = "remove")
    )
    
    proxy <- leafletProxy("map") %>%
      clearGroup("background") %>%
      clearGroup("observations") %>%
      clearControls()
    
    if (step %in% c("Step 1: Meet the parrots", "Step 2: Where and when?")) {
      
      if (input$species_filter == "All") {
        
        data <- all_species_map() %>%
          filter(total_obs > 0)
        
        data <- add_point_style(
          data = data,
          selected = selected,
          colour_column = "dominant_colour",
          base_opacity = 0.68
        )
        
        data <- data %>%
          mutate(
            popup_text = paste0(
              "<b>LGA:</b> ", LGA_NAME25, "<br>",
              "<b>Total observations:</b> ", total_obs, "<br>",
              "<b>Dominant species:</b> ", dominant_label, "<br>",
              "<b>Cockatoo:</b> ", `Cacatua galerita`, "<br>",
              "<b>Lorikeet:</b> ", `Trichoglossus moluccanus`, "<br>",
              "<b>Galah:</b> ", `Eolophus roseicapilla`, "<br>",
              "<b>Human density:</b> ", round(ERP_Density, 2), "<br>",
              "<b>Nighttime light:</b> ", round(avg_rad, 2)
            )
          )
        
        proxy %>%
          addCircleMarkers(
            data = data,
            lng = ~lon,
            lat = ~lat,
            radius = ~make_radius(total_obs),
            color = ~point_stroke_colour,
            fillColor = ~dominant_colour,
            fillOpacity = ~point_opacity,
            opacity = ~ifelse(is_selected, 1, point_opacity),
            stroke = TRUE,
            weight = ~point_weight,
            layerId = ~as.character(LGA_CODE25),
            popup = ~popup_text,
            group = "observations"
          ) %>%
          addLegend(
            position = "bottomright",
            colors = unname(species_colours[species_levels]),
            labels = unname(pretty_species[species_levels]),
            title = "Dominant species"
          )
        
      } else {
        
        data <- long_species_map() %>%
          filter(obs_count > 0)
        
        data <- add_point_style(
          data = data,
          selected = selected,
          colour_column = "species_colour",
          base_opacity = 0.72
        )
        
        data <- data %>%
          mutate(
            popup_text = paste0(
              "<b>Species:</b> ", species_label, "<br>",
              "<b>LGA:</b> ", LGA_NAME25, "<br>",
              "<b>Observation count:</b> ", obs_count, "<br>",
              "<b>Human density:</b> ", round(ERP_Density, 2), "<br>",
              "<b>Nighttime light:</b> ", round(avg_rad, 2)
            )
          )
        
        proxy %>%
          addCircleMarkers(
            data = data,
            lng = ~lon,
            lat = ~lat,
            radius = ~make_radius(obs_count),
            color = ~point_stroke_colour,
            fillColor = ~species_colour,
            fillOpacity = ~point_opacity,
            opacity = ~ifelse(is_selected, 1, point_opacity),
            stroke = TRUE,
            weight = ~point_weight,
            layerId = ~as.character(LGA_CODE25),
            popup = ~popup_text,
            group = "observations"
          ) %>%
          addLegend(
            position = "bottomright",
            colors = unname(species_colours[input$species_filter]),
            labels = unname(pretty_species[input$species_filter]),
            title = "Selected species"
          )
      }
      
    } else {
      
      if (step == "Step 3: Human density") {
        
        session$sendCustomMessage(
          "backgroundOverlay",
          list(
            action = "add",
            url = paste0("human_density_layer.png?v=", as.integer(Sys.time())),
            bounds = overlay_bounds,
            opacity = 1
          )
        )
        
        proxy <- proxy %>%
          addLegend(
            position = "bottomright",
            colors = human_density_base_colours,
            labels = human_density_labels,
            title = "Human density"
          )
        
      } else {
        
        session$sendCustomMessage(
          "backgroundOverlay",
          list(
            action = "add",
            url = paste0("nighttime_light_layer.png?v=", as.integer(Sys.time())),
            bounds = overlay_bounds,
            opacity = 1
          )
        )
        
        proxy <- proxy %>%
          addLegend(
            position = "bottomright",
            colors = night_light_base_colours,
            labels = night_light_labels,
            title = "Nighttime light"
          )
      }
      
      if (input$species_filter == "All") {
        
        obs_data <- all_species_map() %>%
          filter(total_obs > 0)
        
        obs_data <- add_point_style(
          data = obs_data,
          selected = selected,
          colour_column = "dominant_colour",
          base_opacity = 0.72
        )
        
        obs_data <- obs_data %>%
          mutate(
            popup_text = paste0(
              "<b>LGA:</b> ", LGA_NAME25, "<br>",
              "<b>Total observations:</b> ", total_obs, "<br>",
              "<b>Dominant species:</b> ", dominant_label, "<br>",
              "<b>Cockatoo:</b> ", `Cacatua galerita`, "<br>",
              "<b>Lorikeet:</b> ", `Trichoglossus moluccanus`, "<br>",
              "<b>Galah:</b> ", `Eolophus roseicapilla`, "<br>",
              "<b>Human density:</b> ", round(ERP_Density, 2), "<br>",
              "<b>Matched nightlight:</b> ", round(avg_rad, 2)
            )
          )
        
        proxy %>%
          addCircleMarkers(
            data = obs_data,
            lng = ~lon,
            lat = ~lat,
            radius = ~make_radius(total_obs),
            color = ~point_stroke_colour,
            fillColor = ~dominant_colour,
            fillOpacity = ~point_opacity,
            opacity = ~ifelse(is_selected, 1, point_opacity),
            stroke = TRUE,
            weight = ~point_weight,
            layerId = ~as.character(LGA_CODE25),
            popup = ~popup_text,
            group = "observations"
          ) %>%
          addLegend(
            position = "bottomleft",
            colors = unname(species_colours[species_levels]),
            labels = unname(pretty_species[species_levels]),
            title = "Dominant species"
          )
        
      } else {
        
        obs_data <- long_species_map() %>%
          filter(obs_count > 0)
        
        obs_data <- add_point_style(
          data = obs_data,
          selected = selected,
          colour_column = "species_colour",
          base_opacity = 0.78
        )
        
        obs_data <- obs_data %>%
          mutate(
            popup_text = paste0(
              "<b>Species:</b> ", species_label, "<br>",
              "<b>LGA:</b> ", LGA_NAME25, "<br>",
              "<b>Observation count:</b> ", obs_count, "<br>",
              "<b>Human density:</b> ", round(ERP_Density, 2), "<br>",
              "<b>Matched nightlight:</b> ", round(avg_rad, 2), "<br>",
              "<b>Urban zone:</b> ", ifelse(is.na(urban_zone), "Unknown", urban_zone)
            )
          )
        
        proxy %>%
          addCircleMarkers(
            data = obs_data,
            lng = ~lon,
            lat = ~lat,
            radius = ~make_radius(obs_count),
            color = ~point_stroke_colour,
            fillColor = ~species_colour,
            fillOpacity = ~point_opacity,
            opacity = ~ifelse(is_selected, 1, point_opacity),
            stroke = TRUE,
            weight = ~point_weight,
            layerId = ~as.character(LGA_CODE25),
            popup = ~popup_text,
            group = "observations"
          ) %>%
          addLegend(
            position = "bottomleft",
            colors = unname(species_colours[input$species_filter]),
            labels = unname(pretty_species[input$species_filter]),
            title = "Selected species"
          )
      }
    }
  })
  
  output$selected_location <- renderUI ({
    current_lga <- selected_lga()
    
    if (is.null(current_lga)) {
      return(
        div(
          div(class = "selected-title", "Selected Location"),
          div(class = "small-note", "Click a map symbol to inspect one LGA. The selected symbol will keep its original colour and remain highlighted while other symbols fade.")
        )
      )
    }
    
    data <- all_species_map() %>%
      filter(as.character(LGA_CODE25) == as.character(current_lga))
    
    if (nrow(data) == 0) {
      return(
        div(
          div(class = "selected-title", "Selected Location"),
          div(class = "small-note", "The selected LGA is not available under the current filters.")
        )
      )
    }
    
    row <- data[1, ]
    
    div(
      div(class = "selected-title", "Selected Location"),
      div(class = "selected-line", paste("LGA:", row$LGA_NAME25)),
      div(class = "selected-line", paste("Total observations:", row$total_obs)),
      div(class = "selected-line", paste("Dominant species:", row$dominant_label)),
      div(class = "selected-line", paste("Human density:", round(row$ERP_Density, 2))),
      div(class = "selected-line", paste("Nighttime light:", round(row$avg_rad, 2))),
      div(class = "selected-line", paste("Urban zone:", ifelse(is.na(row$urban_zone), "Unknown", row$urban_zone)))
    )
  })
  
  output$step_guide <- renderUI({
    if (input$story_step == "Step 1: Meet the parrots") {
      div(
        div(class = "selected-title", "How to read Step 1"),
        div(class = "small-note", "The map introduces the three species. In All mode, each symbol is a proportional symbol for total observations and is coloured by the dominant species in that LGA.")
      )
    } else if (input$story_step == "Step 2: Where and when?") {
      div(
        div(class = "selected-title", "How to read Step 2"),
        div(class = "small-note", "Use the month range filter to explore seasonal patterns. The linked line chart shows monthly observation counts and changes when a species or LGA is selected.")
      ) 
    } else if (input$story_step == "Step 3: Human density") {
      div(
        div(class = "selected-title", "How to read Step 3"),
        div(class = "small-note", "The transparent purple overlay shows human population density as a background layer. The linked scatter plot shows each LGA by human density and observation count.")
      )
    } else {
      div(
        div(class = "selected-title", "How to read Step 4"),
        div(class = "small-note", "The transparent orange overlay shows nighttime light intensity as a contextual map layer. The linked heat chart uses four quadrants based on human density and nighttime light.")
      )
    }
  })
  
  output$linked_chart <- renderPlotly({
    
    current_lga <- selected_lga()
    
    if (input$story_step == "Step 1: Meet the parrots") {
      
      p <- species_summary %>%
        mutate(
          species_label = pretty_species[species],
          species_colour = unname(species_colours[species])
        ) %>%
        ggplot(aes(
          x = reorder(species_label, total_observations),
          y = total_observations,
          fill = species,
          text = paste0(
            "Species: ", species_label,
            "<br>Total observations: ", total_observations,
            "<br>Main state: ", main_state
          )
        )) +
        geom_col(width = 0.6) +
        coord_flip() +
        scale_fill_manual(values = species_colours) +
        labs(
          x = NULL,
          y = "Total observations",
          title = "Total observations by species"
        ) +
        theme_minimal(base_size = 11) +
        theme(
          legend.position = "none",
          plot.title = element_text(size = 13, face = "bold")
        )
      
      ggplotly(p, tooltip = "text")
      
    } else if (input$story_step == "Step 2: Where and when?") {
      
      step2_data <- map_data
      
      if (input$species_filter != "All") {
        step2_data <- step2_data %>% filter(species == input$species_filter)
      }
      
      if (!is.null(current_lga)) {
        step2_data <- step2_data %>%
          filter(as.character(LGA_CODE25) == as.character(current_lga))
      }
      
      step2_data <- step2_data %>%
        group_by(species, month) %>%
        summarise(
          obs_count = sum(obs_count, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          species_label = unname(pretty_species[species])
        )
      
      p <- step2_data %>%
        ggplot(aes(
          x = month,
          y = obs_count,
          colour = species,
          group = species,
          text = paste0(
            "Species: ", species_label,
            "<br>Month: ", month,
            "<br>Observations: ", obs_count
          )
        )) +
        geom_line(linewidth = 0.9) +
        geom_point(size = 1.8) +
        scale_colour_manual(
          values = species_colours,
          labels = pretty_species
        ) +
        scale_x_continuous(breaks = 1:12) +
        labs(
          x = "Month",
          y = "Observation count",
          title = "Monthly observation pattern",
          colour = "Species"
        ) +
        theme_minimal(base_size = 11) +
        theme(
          plot.title = element_text(size = 13, face = "bold"),
          legend.position = "bottom",
          legend.title = element_blank()
        )
      
      ggplotly(p, tooltip = "text")
      
    } else if (input$story_step == "Step 3: Human density") {
      
      step3_data <- filtered_base()
      
      if (input$species_filter != "All") {
        step3_data <- step3_data %>% filter(species == input$species_filter)
      }
      
      step3_scatter <- step3_data %>%
        group_by(LGA_CODE25, LGA_NAME25) %>%
        summarise(
          total_obs = sum(obs_count, na.rm = TRUE),
          ERP_Density = mean(ERP_Density, na.rm = TRUE),
          obs_density = mean(obs_density, na.rm = TRUE),
          avg_rad = mean(avg_rad, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        filter(
          !is.na(ERP_Density),
          !is.na(total_obs),
          total_obs > 0
        ) %>%
        mutate(
          LGA_CODE25 = as.character(LGA_CODE25),
          log_human_density = log10(ERP_Density + 1),
          log_observations = log10(total_obs + 1),
          tooltip_text = paste0(
            "LGA: ", LGA_NAME25,
            "<br>Human density: ", round(ERP_Density, 2),
            "<br>Observation count: ", total_obs,
            "<br>Observation density: ", round(obs_density, 4),
            "<br>Nighttime light: ", round(avg_rad, 2)
          )
        )
      
      if (!is.null(current_lga)) {
        selected_code <- as.character(current_lga)
        
        base_points <- step3_scatter %>%
          filter(LGA_CODE25 != selected_code)
        
        selected_points <- step3_scatter %>%
          filter(LGA_CODE25 == selected_code)
        
        base_alpha <- 0.18
      } else {
        base_points <- step3_scatter
        selected_points <- step3_scatter[0, ]
        base_alpha <- 0.65
      }
      
      p <- ggplot() +
        geom_point(
          data = base_points,
          aes(
            x = log_human_density,
            y = log_observations,
            text = tooltip_text
          ),
          color = "#4A4A4A",
          fill = "#4A4A4A",
          alpha = base_alpha,
          size = 2.4,
          stroke = 0.2,
          shape = 21
        )
      
      if (nrow(selected_points) > 0) {
        p <- p +
          geom_point(
            data = selected_points,
            aes(
              x = log_human_density,
              y = log_observations,
              text = tooltip_text
            ),
            color = "#000000",
            fill = "#D62728",
            alpha = 1,
            size = 5,
            stroke = 1.2,
            shape = 21
          )
      }
      
      p <- p +
        labs(
          x = "Human density, log scale",
          y = "Observation count, log scale",
          title = "Human density vs observation count"
        ) +
        theme_minimal(base_size = 11) +
        theme(
          plot.title = element_text(size = 13, face = "bold"),
          legend.position = "none"
        )
      
      ggplotly(p, tooltip = "text")
      
    } else {
      
      step4_data <- filtered_base() %>%
        filter(
          !is.na(ERP_Density),
          !is.na(avg_rad),
          !is.na(obs_count),
          obs_count > 0
        )
      
      if (input$species_filter != "All") {
        step4_data <- step4_data %>% filter(species == input$species_filter)
      }
      
      step4_lga <- step4_data %>%
        group_by(LGA_CODE25, LGA_NAME25) %>%
        summarise(
          total_obs = sum(obs_count, na.rm = TRUE),
          ERP_Density = mean(ERP_Density, na.rm = TRUE),
          avg_rad = mean(avg_rad, na.rm = TRUE),
          obs_density = mean(obs_density, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        filter(
          total_obs > 0,
          !is.na(ERP_Density),
          !is.na(avg_rad)
        ) %>%
        mutate(
          log_human_density = log10(ERP_Density + 1),
          log_light = log10(avg_rad + 1)
        )
      
      human_mid <- median(step4_lga$log_human_density, na.rm = TRUE)
      light_mid <- median(step4_lga$log_light, na.rm = TRUE)
      
      x_breaks <- seq(
        floor(min(step4_lga$log_human_density, na.rm = TRUE) * 2) / 2,
        ceiling(max(step4_lga$log_human_density, na.rm = TRUE) * 2) / 2,
        by = 0.25
      )
      
      y_breaks <- seq(
        floor(min(step4_lga$log_light, na.rm = TRUE) * 2) / 2,
        ceiling(max(step4_lga$log_light, na.rm = TRUE) * 2) / 2,
        by = 0.25
      )
      
      if (length(x_breaks) < 2) {
        x_breaks <- seq(0, 1, by = 0.25)
      }
      
      if (length(y_breaks) < 2) {
        y_breaks <- seq(0, 1, by = 0.25)
      }
      
      step4_heat <- step4_lga %>%
        mutate(
          human_bin = cut(
            log_human_density,
            breaks = x_breaks,
            include.lowest = TRUE,
            right = FALSE
          ),
          light_bin = cut(
            log_light,
            breaks = y_breaks,
            include.lowest = TRUE,
            right = FALSE
          )
        ) %>%
        filter(!is.na(human_bin), !is.na(light_bin)) %>%
        group_by(human_bin, light_bin) %>%
        summarise(
          total_obs = sum(total_obs, na.rm = TRUE),
          mean_human_density = mean(ERP_Density, na.rm = TRUE),
          mean_light = mean(avg_rad, na.rm = TRUE),
          mean_obs_density = mean(obs_density, na.rm = TRUE),
          n_lga = n(),
          selected_cell = any(as.character(LGA_CODE25) == as.character(current_lga)),
          .groups = "drop"
        ) %>%
        mutate(
          human_bin_id = as.numeric(human_bin),
          light_bin_id = as.numeric(light_bin),
          human_mid_value = x_breaks[human_bin_id] + diff(x_breaks)[1] / 2,
          light_mid_value = y_breaks[light_bin_id] + diff(y_breaks)[1] / 2,
          quadrant = case_when(
            human_mid_value >= human_mid & light_mid_value >= light_mid ~ "High density / High light",
            human_mid_value < human_mid & light_mid_value >= light_mid ~ "Low density / High light",
            human_mid_value < human_mid & light_mid_value < light_mid ~ "Low density / Low light",
            TRUE ~ "High density / Low light"
          )
        )
      
      p <- ggplot(step4_heat, aes(
        x = human_mid_value,
        y = light_mid_value,
        fill = total_obs,
        text = paste0(
          "Quadrant: ", quadrant,
          "<br>Human density, log bin: ", human_bin,
          "<br>Nighttime light, log bin: ", light_bin,
          "<br>Total observations: ", total_obs,
          "<br>Mean human density: ", round(mean_human_density, 2),
          "<br>Mean nighttime light: ", round(mean_light, 2),
          "<br>Mean obs. density: ", round(mean_obs_density, 4),
          "<br>LGAs: ", n_lga
        )
      )) +
        geom_tile(
          width = diff(x_breaks)[1],
          height = diff(y_breaks)[1],
          color = "white",
          linewidth = 0.35
        ) +
        geom_vline(
          xintercept = human_mid,
          color = "#D62728",
          linewidth = 0.8,
          linetype = "dashed"
        ) +
        geom_hline(
          yintercept = light_mid,
          color = "#D62728",
          linewidth = 0.8,
          linetype = "dashed"
        ) +
        scale_fill_gradient(
          low = "#f7f7f7",
          high = "#111111"
        ) +
        labs(
          x = "Human density, log scale",
          y = "Nighttime light, log scale",
          fill = "Observations",
          title = "Observation heatmap by density and light"
        ) +
        theme_minimal(base_size = 11) +
        theme(
          plot.title = element_text(size = 13, face = "bold"),
          panel.grid = element_blank()
        )
      
      if (!is.null(current_lga)) {
        selected_cells <- step4_heat %>%
          filter(selected_cell)
        
        if (nrow(selected_cells) > 0) {
          p <- p +
            geom_tile(
              data = selected_cells,
              aes(
                x = human_mid_value,
                y = light_mid_value
              ),
              inherit.aes = FALSE,
              width = diff(x_breaks)[1],
              height = diff(y_breaks)[1],
              fill = NA,
              color = "#D62728",
              linewidth = 1.2
            )
        }
      }
      
      ggplotly(p, tooltip = "text")
    }
  })
}

shinyApp(ui, server)