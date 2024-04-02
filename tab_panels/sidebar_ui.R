sidebar_ui <- function(){
  sidebar(
    title = "Filter your data",
    uiOutput("select_dataset"),     
    tags$br(),
    uiOutput("select_gridtype"),
    tags$br(),
    uiOutput("year_input"),
    checkboxInput("toggle_year", "Discrete selection of year", value = FALSE),
    tags$br(),
    uiOutput("select_species"),
    div(class = "row", 
        div(class = "col-6", 
            actionButton("all_species", "Select All Species")
        ),
        div(class = "col-6", 
            actionButton("major_tunas", "Select Major Tunas")
        )
    ),
    tags$br(),
    tags$br(),
    useShinyjs(),  # Initialize shinyjs
    div(id = "fishing_fleet_toggle", style = "cursor: pointer;", 
        HTML("Select Fishing Fleet <span id='arrow_indicator'>&#9660;</span>")),
    # Initially visible panel
    div(id = "fishing_fleet_panel",
        uiOutput("select_fishing_fleet"),
        actionButton("all_fishing_fleet", "Select All Fishing Fleets")
    ),
    # shinyjs::hidden(
    #   div(id = "fishing_fleet_panel",
    #       selectInput("test_fishing_fleet", "Fishing Fleet", choices = c("Fleet 1", "Fleet 2")),
    #       actionButton("all_fishing_fleet", "Select All Fishing Fleets")
    #   )
    # ),#test en dessous
    actionButton("all_fishing_fleet", "Select All Fishing Fleets"),
    tags$br(),
    tags$br(),
    div(class = "row", 
        div(class = "col-6", 
            actionButton("resetWkt", "Reset WKT to global")
        ),
        div(class = "col-6", 
            actionButton("resetFilters", "Reset Filters")
        )
    ),
    tags$br(),
    div(style = "position: -webkit-sticky; position: sticky; bottom: 0; z-index: 999;",
        actionButton("submit", "Submit", class = "btn-primary")
    )
  )
}