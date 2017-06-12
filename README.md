oddstream <img src="logo.png" align="right" height="250" />
============================================

# oddstream {Outlier Detection in Data STREAMs}
---------------------------------------------------
oddstream: A package for Outlier Detection in Data Streams

Rapid advances in hardware technology have enabled a wide range of physical objects, living beings and 
environments to be monitored using sensors attached to them. Over time these sensors generate streams of
time series data. Finding anomalous events in streaming time series data has become an interesting 
research topic due to its wide range of possible applications such as: intrusion detection, water contamination monitoring, machine health monitoring, etc. This package proposes a framework that provides real time 
support for early detection of anomalous series within a large collection of streaming time series data.
By definition, anomalies are rare in comparison to a system's typical behaviour. We define an anomaly as 
an observation that is very unlikely given the forecast distribution. The proposed framework first forecasts
a boundary for the system's typical behaviour using a representative sample of the typical behaviour of the
system. An approach based on extreme value theory is used for this boundary prediction process. Then a sliding
window is used to test for anomalous series within the newly arrived collection of series. Feature based 
representation of time series is used as the input to the model. To cope with concept drift, the forecast
boundary for the system's typical behaviour is updated periodically. 

Example 1
============
````
#example codes will appear here

````


References
===========

Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate extreme value statistics. Journal of signal processing systems, 65 (3),371-389.

Hyndman, R. J., Wang, E., & Laptev, N. (2015). Large-scale unusual time series
detection. In 2015 IEEE International Conference on Data Mining Workshop
(ICDMW), (pp. 1616{1619). IEEE.

Priyanga Dilini Talagala; Rob J Hyndman; Kate Smith-Miles; Sevvandi Kandanaarachchi; Mario A. Mu?oz (2017). Anomaly Detection in Streaming Time Series Data. 


