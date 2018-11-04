---
output: github_document
title: oddstream
---


<!-- rmarkdown v1 -->
<img src="man/figures/logo.png" align="right" height="150"/>

[![Project Status: WIP â€“ Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Licence](https://img.shields.io/badge/licence-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)

[![Build Status](https://travis-ci.org/pridiltal/oddstream.svg?branch=master)](https://travis-ci.org/pridiltal/oddstream)
 
---
 
[![minimal R version](https://img.shields.io/badge/R%3E%3D-3.4.0-6666ff.svg)](https://cran.r-project.org/)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/oddstream)](https://cran.r-project.org/package=oddstream)
[![packageversion](https://img.shields.io/badge/Package%20version-0.5.0-orange.svg?style=flat-square)](commits/master)
 
---
 
[![Last-changedate](https://img.shields.io/badge/last%20change-2018--11--04-yellowgreen.svg)](/commits/master)


 
---




<!-- README.md is generated from README.Rmd. Please edit that file -->



# oddstream

The goal of oddstream (Outlier Detection in Data Streams) is to propose a framework that provides real time support for early detection of anomalous series within a large collection of streaming time series data. By definition, anomalies are rare in comparison to a system's typical behaviour. We define an anomaly as an observation that  is very unlikely given the forecast distribution. The algorithm first forecasts a boundary for the system's typical behaviour using a representative sample of the typical behaviour of the system. An  approach based on extreme value theory is used for this boundary prediction process. Then a sliding window is used to test for anomalous series within the newly arrived collection of series. Feature based representation of time series is used as the input to the model. To cope with concept drift, the forecast boundary for the system's typical behaviour is updated periodically.

This package is still under development and this repository contains a development version of the R package *oddstream*.

## Installation

You can install oddstream from github with:


```r
# install.packages("devtools")
devtools::install_github("pridiltal/oddstream")
```

## Example

### Multivariate time series plot of `anomalous_stream` dataset  available in `oddstream` package 


```r
library(oddstream)
library(tidyverse)
t <- nrow(anomalous_stream)
f <- ncol(anomalous_stream)
data <- as_tibble(anomalous_stream) %>%
  gather() %>%
  mutate(key = rep((1:f), each = t), Time = rep(1:t, f)) %>%
  setNames(c("Cable", "Value", "Time"))


p <- data %>% 
  ggplot(aes(x = Time, y = Cable, fill = Value)) +
  geom_tile() +
  scale_fill_gradientn(colours = c("#F0E442", "#000000", "#000000"), values = c(0, .1, max(anomalous_stream))) +
  scale_x_continuous(breaks = seq(0, 1400, 200)) +
  scale_y_continuous(breaks = seq(0, 600, 100)) +
  labs(x= "Time", y= "Time Series ID")

p
```

<img src="man/figures/README-dataset-1.png" title="plot of chunk dataset" alt="plot of chunk dataset" width="100%" height="40%" />


### Two dimensional feature space 


```r
library(oddstream)
features <- extract_tsfeatures(anomalous_stream[1:100, 1:100])
pc <- get_pc_space(features)
p <- gg_featurespace(pc)
p
```

![plot of chunk 2dpcspace](man/figures/README-2dpcspace-1.png)

```r

# Perform a 2D kernel density estimation using MASS::kde2d() and display the results with contours.
p + ggplot2::geom_density_2d()
```

![plot of chunk 2dpcspace](man/figures/README-2dpcspace-2.png)


```r
library(oddstream)
# Considers the first window  of the data set as the training set and the remaining as the test stream
train_data <- anomalous_stream[1:100, ]
test_stream <- anomalous_stream[101:1456, ]

output <- find_odd_streams(train_data, test_stream, plot_type = "none", trials = 100)
```

### Further Details

```r
?oddstream
```

## References

- Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate extreme value statistics. Journal of signal processing systems, 65 (3), (pp. 371-389).

- Hyndman, R. J., Wang, E., & Laptev, N. (2015). Large-scale unusual time series detection. In 2015 IEEE International Conference on Data Mining Workshop (ICDMW), (pp. 1616-1619). IEEE.

- Talagala, P. D., Hyndman, R. J., Smith-Miles, K., Kandanaarachchi, S., & Muñoz, M. A. (2018). Anomaly Detection in Streaming Nonstationary Temporal Data. Working paper 4/18, Department of Econometrics & Business Statistics, Monash University.


