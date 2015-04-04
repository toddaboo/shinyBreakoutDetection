
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(BreakoutDetection)
library(ggplot2)
library(dplyr)
library(scales)

#generate fake data
counts <- rbind(runif(25, 1, 5), runif(25, 10, 20), runif(25, 28, 35), runif(25, 50, 65))
dates <- seq(Sys.Date()-99, Sys.Date(), by = "days")

data <- data.frame(cbind(dates, sample(as.vector(counts))))
names(data) <- c("timestamp", "count")
data$timestamp <- as.POSIXct(as.Date(data$timestamp, origin="1970-01-01"))

shinyServer(function(input, output) {

  output$breakoutCode <- renderText({
    paste("breakout(<data>, min.size=", input$minsize ,", method='", input$method, "', beta=", input$beta, ", degree=", input$degree, ", plot=TRUE)", sep="")
  })
  
  dat <- reactive({
    #run breakout detection
    d = breakout(data, min.size=input$minsize, method=input$method, beta=input$beta, degree=input$degree, plot=TRUE)
  })
  
  output$plot <- renderPlot({
    if(!input$fancy) {
      dat()$plot
    } else {
      res <- dat()
      ## use ggplot to visualize the mean shift at each break/change point
      ## the stock plot for breakout only shows the breaks
      #determine means of each segment
      breaks <- c(1, res$loc, nrow(res$plot$data))
      
      data$cat <- cut(as.numeric(rownames(data)), breaks, include.lowest=T)
      levels(data$cat) <- 1:length(unique(data$cat))
      
      data %>%
        group_by(cat) %>%
        summarise(mean(count)) -> means
      
      names(means)[2] <- "count"
      
      #determine points for line segments
      #vertical
      xv <- breaks
      yv <- c(means$count[1], means$count)
      xendv <- breaks
      yendv <- c(means$count, means$count[length(means$count)])
      vert <- data.frame(cbind(xv, yv, xendv, yendv))
      
      #horizontal
      xh <- breaks[-length(breaks)]
      yh <- means$count
      xendh <- breaks[-1]
      yendh <- means$count
      horiz <- data.frame(cbind(xh, yh, xendh, yendh)) 
      
      ggplot() + geom_segment(data=vert, aes(x=xv, y=yv), xend=xendv, yend=yendv, color='red', linetype="longdash") + geom_segment(data=horiz, aes(x=xh, y=yh), xend=xendh, yend=yendh, color='blue')
      
      #generate plot
      plot <- ggplot() + geom_line(data=res$plot$data, aes(x=timestamp, y=count), color='darkgray') + theme_bw() + theme(axis.text.x = element_text(angle=90)) + scale_x_datetime(breaks = date_breaks("1 week"), labels = date_format("%d %b %Y")) + xlab("Date") + ylab("Count")
      plot <- plot + geom_segment(data=vert, x=as.numeric(res$plot$data[xv, ]$timestamp), y=yv, xend=as.numeric(res$plot$data[xendv, ]$timestamp), yend=yendv, color='red', linetype="longdash") 
      plot <- plot + geom_segment(data=horiz, x=as.numeric(res$plot$data[xh, ]$timestamp), y=yh, xend=as.numeric(res$plot$data[xendh, ]$timestamp), yend=yendh, color='blue') + geom_text(data=horiz, x=as.numeric(res$plot$data[xh, ]$timestamp), y=yh, label=round(yh, 2), hjust=-0.5, vjust=-0.5)
      print(plot)
    }
  })

})
