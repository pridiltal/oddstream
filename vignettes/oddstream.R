## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----3dplot2, eval= FALSE, echo=TRUE, warning=FALSE, message=FALSE, out.width='100%', out.height='100%'----
#  library(oddstream)
#  time <- nrow(anomalous_stream)
#  sensor <- ncol(anomalous_stream)
#  Time <- 1 : time
#  Sensor_ID <- 1 : sensor
#  #library(plotly)
#  #library(RColorBrewer)
#  Value <- as.matrix(anomalous_stream)
#  plot_ly(x = ~ Sensor_ID, y = ~ Time, z = ~ Value, colors = colorRamp(c("palegreen", "red", "red1", "red2", "red3"))) %>% add_surface()

