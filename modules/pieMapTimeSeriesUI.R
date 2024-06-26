pieMapTimeSeriesUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      style = "height: 400px;",
      leafletOutput(ns("pie_map"))%>% withSpinner(),
      actionButton(ns("submit_draw"), "Update wkt from drawing",
                   class = "btn-primary",
                   style = "position: absolute; top: 100px; right: 20px; z-index: 400; font-size: 0.8em; padding: 5px 10px;")
    ),
  )
}


pieMapTimeSeriesServer <- function(id, category_var, data, centroid, submitTrigger) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    zoom_level <- reactiveVal(1)
    target_var <- getTarget(category_var)
    
    data_pie_map <- reactive({
      flog.info("Generating pie map data for category: %s", category_var)
      req(data())
      sf_data <- st_as_sf(as.data.frame(data()))
      df <- sf_data %>%
        dplyr::group_by(!!sym(category_var), geom_wkt) %>%
        dplyr::summarise(measurement_value = sum(measurement_value)) %>%
        tidyr::spread(key = !!sym(category_var), value = measurement_value, fill = 0) %>%
        dplyr::mutate(total = rowSums(across(any_of(target_var[[category_var]]))))
      flog.info("Pie map data: %s", head(df))
      df
    })
    
    la_palette <- reactive({
      flog.info("Generating palette for category: %s", category_var)
      la_palette <- getPalette(category_var)
      la_palette <- la_palette[names(la_palette) %in% colnames(data_pie_map())]
      flog.info("Palette: %s", la_palette)
      la_palette
    })
    
    output$pie_map <- renderLeaflet({
      flog.info("Rendering pie map")
      req(data_pie_map(), zoom_level())  
      req(centroid())
      df <- data_pie_map()
      centroid <- st_as_sf(centroid())
      lat_centroid <- st_coordinates(centroid)[2]
      lon_centroid <- st_coordinates(centroid)[1]
      la_palette <- la_palette()
      
      leaflet() %>% 
        addProviderTiles("Esri.NatGeoWorldMap", group = "background") %>%
        setView(lng = lon_centroid, lat = lat_centroid, zoom = zoom_level()) %>%
        onRender(
          sprintf(
            "function(el, x) {
      var map = this;
      map.on('zoomend', function() {
        console.log('Zoom level:', map.getZoom());
        Shiny.setInputValue('%smap_zoom_level', map.getZoom(), {priority: 'event'});
      });
      
      Shiny.setInputValue('%smap_zoom_level', map.getZoom(), {priority: 'event'});
    }", session$ns(""), session$ns("")
          )
        ) %>% 
        clearBounds() %>%
        addDrawToolbar(
          targetGroup = "draw",
          editOptions = editToolbarOptions(
            selectedPathOptions = selectedPathOptions()
          )
        ) %>%
        addLayersControl(
          overlayGroups = c("draw"),
          options = layersControlOptions(collapsed = FALSE)
        )  %>% 
        addMinicharts(lng = st_coordinates(st_centroid(df, crs = 4326))[, "X"],
                      lat = st_coordinates(st_centroid(df, crs = 4326))[, "Y"],
                      maxValues = max(df$total),
                      chartdata = dplyr::select(df, -total) %>% st_drop_geometry(), type = "pie",
                      colorPalette = unname(la_palette),
                      width =  8 + ((zoom_level() * 20) * (df$total / max(df$total))),
                      legend = TRUE, legendPosition = "bottomright", layerId = "minicharts") %>%
        addLayersControl(baseGroups = c("minicharts", "grid"), overlayGroups = c("background"))
    })
    
    observeEvent(input$map_zoom_level, {
      flog.info("Updating zoom level to: %s", input$map_zoom_level)
      df <- data_pie_map()
      la_palette <- la_palette()
      
      new_width <- 8 + (input$map_zoom_level * 20) * (df$total / max(df$total))
      
      leafletProxy("pie_map", data = df) %>%
        clearGroup("minicharts") %>% 
        addMinicharts(lng = st_coordinates(st_centroid(df, crs = 4326))[, "X"],
                      lat = st_coordinates(st_centroid(df, crs = 4326))[, "Y"],
                      maxValues = max(df$total),
                      chartdata = dplyr::select(df, -total) %>% st_drop_geometry(),
                      type = "pie",
                      colorPalette = unname(la_palette), transitionTime = 50,
                      width = new_width,  
                      legend = TRUE, legendPosition = "bottomright")
    })
    
    observeEvent(input$submit_draw, {
      flog.info("User requested to change spatial coverage")
      showModal(modalDialog(
        title = "Changing spatial coverage",
        "Attention, you are about to change the geographic coverage of the filter. Are you sure?",
        footer = tagList(
          modalButton("No"),
          actionButton(ns("yes_button"), "Yes")
        ),
        easyClose = TRUE,
        id = ns("confirmation_modal")  
      ))
    })
    
    observeEvent(input$yes_button, {
      flog.info("User confirmed changing spatial coverage")
      req(input$pie_map_draw_new_feature$geometry)
      req(input$pie_map_draw_stop)
      geojson <- input$pie_map_draw_new_feature$geometry
      geojson_text <- toJSON(geojson, auto_unbox = TRUE, pretty = TRUE)
      sf_obj <- geojsonsf::geojson_sf(geojson_text)
      wkt_val <- st_as_text(sf_obj$geometry)
      wkt(wkt_val)
      submitTrigger(TRUE)      
      removeModal()
      flog.info("Spatial coverage changed")
    })
  })
}
