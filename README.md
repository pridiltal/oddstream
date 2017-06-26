oddstream <img src="logo.png" align="right" height="150" />
============================================

# oddstream {Outlier Detection in Data STREAMs}
---------------------------------------------------
oddstream: A package for Outlier Detection in Data Streams

Rapid advances in hardware technology have enabled a wide range of physical objects, living beings and 
environments to be monitored using sensors attached to them. Over time these sensors generate streams 
of time series data. Finding anomalous events in streaming time series data has become an interesting 
research topic due to its wide range of possible applications such as: intrusion detection, water 
contamination monitoring, machine health monitoring, etc. This package proposes a framework that provides
real time support for early detection of anomalous series within a large collection of streaming time 
series data. By definition, anomalies are rare in comparison to a system's typical behaviour. We define
an anomaly as an observation that is very unlikely given the forecast distribution. The proposed framework
first forecasts a boundary for the system's typical behaviour using a representative sample of the typical
behaviour of the system. An approach based on extreme value theory is used for this boundary prediction
process. Then a sliding window is used to test for anomalous series within the newly arrived collection 
of series. Feature based representation of time series is used as the input to the model. To cope with 
concept drift, the forecast boundary for the system's typical behaviour is updated periodically. 

This package is still under development and this repository contains a development version of the R package *oddstream*.

Installation
------------
The development version can be installed as follows:
``` r
#install.packages("devtools")
devtools::install_github("pridiltal/oddstream")
```

Usage
============
````
library(oddstream)

#Package help
package?oddstream


#Example 1
#Generate training dataset
set.seed(890)
nobs = 250
nts = 100
train_data <- ts(apply(matrix(ncol = nts, nrow = nobs), 2, function(nobs){10 + rnorm(nobs, 0, 3)}))
# Generate test stream with some outliying series
nobs = 15000
test_stream <- ts(apply(matrix(ncol = nts, nrow = nobs), 2, function(nobs){10 + rnorm(nobs, 0, 3)}))
test_stream[360:1060, 20:25] = test_stream[360:1060, 20:25] * 1.75
test_stream[2550:3550, 20:25] =  test_stream[2550:3550, 20:25] * 2
find_odd_streams(train_data, test_stream , plot_type = 'line', trials = 100)

#Example 2
# To get mvtsplot
find_odd_streams(train_data, test_stream , plot_type = 'mvtsplot')

````


References
===========

Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate extreme value statistics. Journal of signal processing systems, 65 (3), (pp. 371-389).

Hyndman, R. J., Wang, E., & Laptev, N. (2015). Large-scale unusual time series
detection. In 2015 IEEE International Conference on Data Mining Workshop
(ICDMW), (pp. 1616-1619). IEEE.



