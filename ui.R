
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyBS)

shinyUI(fluidPage(
  tags$head(tags$style("#breakoutCode {color: green;
                                 font-size: 11px;
                                 font-style: italic;
                                 }"
            )
  ),
  # Application title
  titlePanel("Breakout Detection"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("minsize",
                  "Min. number of observations between change points:",
                  min = 1,
                  max = 100,
                  value = 25),
      radioButtons("method", "Method:",
                   c("Multiple Changes" = "multi",
                     "At Most One Change" = "amoc")),
      br(),
      sliderInput("beta",
                  "Penalization constant (beta):",
                  min = 0.001,
                  max = 0.02,
                  step = 0.001,
                  value = 0.008),
      sliderInput("degree",
                  "Degree of penalization polynomial:",
                  min = 0,
                  max = 2,
                  value = 1)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      strong("\"breakout\" function code:"), verbatimTextOutput("breakoutCode"),
      plotOutput("distPlot")
    )
  )
))
