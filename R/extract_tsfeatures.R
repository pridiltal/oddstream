#' Extract features from a collection of time series
#'
#' @description This function extract time series features from a collection of time series.
#' This is a modification of  \code{\link[anomalous]{tsmeasures}}.
#' @param data A multivariate time series
#' @param normalise If TRUE, each time series is scaled to be normally distributed with mean 0 and sd 1
#' @param width A window size for variance change, level shift and lumpiness
#' @param window A window size for KLscore
#' @return An object of class features with the following components:
#'   \item{mean}{Mean}
#'   \item{var}{Variance}
#'   \item{lumpinessy}{Variance of annual variances of remainder}
#'   \item{lshifty}{Level shift using rolling window}
#'   \item{vchangey}{Variance change}
#'   \item{linearity}{Strength of linearity}
#'   \item{curvature}{Strength of curvature}
#'   \item{spikiness}{Strength of spikiness}
#'   \item{season}{Strength of seasonality}
#'   \item{peak}{Strength of peaks}
#'   \item{trough}{Strength of trough}
#'   \item{BurstinessFF}{Burstiness of time series using Fano Factor}
#'   \item{min}{Minimum value}
#'   \item{max}{maximum value}
#'   \item{rmeaniqmean}{Ratio between interquartile mean and the arithmetic mean }
#'   \item{moment3}{Third moment}
#'   \item{highlowmu}{ratio between the means of data that is below and upper the global mean}
#'
#' @seealso \code{\link[anomalous]{tsmeasures}}
#' @export
#' @importFrom moments moment
#' @importFrom RcppRoll roll_mean
#' @importFrom RcppRoll roll_var
#' @importFrom mgcv gam
#' @references {Hyndman, R. J., Wang, E., & Laptev, N. (2015). Large-scale unusual time series detection.
#' In 2015 IEEE International Conference on Data Mining Workshop (ICDMW), (pp. 1616-1619). IEEE.}\cr
#'
#' {Fulcher, B. D. (2012). Highly comparative time-series analysis. PhD thesis, University of Oxford.}
#' @examples
#' #Data Generation
#' nobs = 100
#' nts =50
#' tsframe <- ts(matrix(ncol=nts, nrow=nobs))
#' for(i in 1:nts){
#'   tsframe[,i] <- 10 + rnorm(nobs,0,3) # adding noise
#' }
#' f=extract_tsfeatures(tsframe)
extract_tsfeatures <- function(y, normalise = TRUE, width = ifelse(frequency(y) > 1, frequency(y), 10), window = width) {
    
    
    # y: a multivariate time series normalise: TRUE: scale data to be normally distributed width: a window size for variance
    # change and level shift, lumpiness window: a window size for KLscore
    y <- as.ts(y)
    tspy <- tsp(y)
    freq <- frequency(y)
    
    
    # Remove columns containing all NAs
    nay <- is.na(y)
    allna <- apply(nay, 2, all)
    x <- y[, !allna]
    
    # Normalise data to mean = 0, sd = 1
    if (normalise) {
        x <- as.ts(scale(x, center = TRUE, scale = TRUE))
    }
    
    # create a location to store the measures
    measures <- list()
    
    # measure1 - Calculate mean of ts
    measures$mean <- colMeans(y, na.rm = TRUE)
    
    # measure2 - Calculate variance of ts
    measures$var <- apply(y, 2, var, na.rm = TRUE)
    
    # measure5 - Lumpiness
    measures$lumpinessy <- apply(y, 2, Lump, width = width)
    
    # measure6 - Level shift using rolling window
    measures$lshifty <- apply(y, 2, RLshift, width = width)
    
    
    # measure7 - variance change using rolling window
    measures$vchangey <- apply(y, 2, RVarChange, width = width)
    
    # measure11,12,13,14,15,16,17 - Strength of trend and seasonality and spike
    varts <- apply(y, 2, VarTS, tspx = tspy)
    # measures$trend <- sapply(varts, function(y) y$trend)
    measures$linearity <- sapply(varts, function(y) y$linearity)
    measures$curvature <- sapply(varts, function(y) y$curvature)
    measures$spikiness <- sapply(varts, function(y) y$spike)
    if (freq > 1) {
        measures$season <- sapply(varts, function(y) y$season)
        measures$peak <- sapply(varts, function(y) y$peak)
        measures$trough <- sapply(varts, function(y) y$trough)
    }
    
    # measure19 - burstiness of time series
    measures$BurstinessFF <- apply(y, 2, BurstFF)
    
    # measure21,22 - Calculate the time series length)
    minmax <- apply(y, 2, function(x) tsminmax(x))  #original data set
    measures$min <- sapply(minmax, function(x) x$mn)
    measures$max <- sapply(minmax, function(x) x$mx)
    
    # measure28 - the ratio between interquartile mean and the arithmetic mean
    measures$rmeaniqmean <- apply(y, 2, rmeaniqmean)  #apply to original data
    
    # measure29 - Calculate the moments moments <- apply(y, 2, dmoments) #apply to original data set measures$moment3 <-
    # sapply(moments, function(y) y$m3)
    measures$moment3 <- apply(y, 2, dmoments)
    
    
    
    
    # measure32 - compare the means of data that is below and upper the global mean
    measures$highlowmu <- apply(y, 2, highlowmu)  #apply to original data
    
    # get all the measures to one data frame
    tmp <- do.call(cbind, measures)
    nr <- ncol(y)
    nc <- length(measures)
    mat <- matrix(, nrow = nr, ncol = nc)
    colnames(mat) <- colnames(tmp)
    mat[!allna, ] <- tmp
    out <- structure(mat, class = c("features", "matrix"))
    return(out)
}




### A function to calculate Lumpiness: cannot be used for yearly data first divide a series into blocks. Then the variances
### of each block are computed. The variance of the variances across these blocks measures the 'lumpiness' of the series.
### measure5 - Lumpiness
Lump <- function(x, width) {
    start <- seq(1, nr <- length(x), by = width)
    end <- seq(width, nr + width, by = width)
    nsegs <- nr/width
    varx <- sapply(1:nsegs, function(idx) var(x[start[idx]:end[idx]], na.rm = TRUE))
    lumpiness <- var(varx, na.rm = TRUE)
    return(lumpiness)
}


### A function to calculate Level shift using rolling window The 'level shift' is defined as the maximum difference in mean
### between consecutive blocks of 10 observations measure6 - Level shift using rolling window
RLshift <- function(x, width) {
    rollmean <- RcppRoll::roll_mean(x, width, na.rm = TRUE)
    lshifts <- tryCatch(max(abs(diff(rollmean, width)), na.rm = TRUE), warning = function(w) w)
    if (any(class(lshifts) == "warning")) {
        lshifts <- NA
    }
    return(lshifts)
}

### A function to calculate the maximum difference in variance using rolling window The 'variance change' is defined as the
### maximum difference in variance between consecutive blocks of 10 observations measure7 - variance change using rolling
### window
RVarChange <- function(x, width) {
    rollvar <- RcppRoll::roll_var(x, width, na.rm = TRUE)
    vchange <- tryCatch(max(abs(diff(rollvar, width)), na.rm = TRUE), warning = function(w) w)
    if (any(class(vchange) == "warning")) {
        vchange <- NA
    }
    return(vchange)
}

## A function to find Strength of trend and seasonality and spike Some of our features rely on a robust STL decomposition
## [3]. For example, the size and location of the peaks and troughs in the seasonal component are used, and the spikiness
## feature is the variance of the leave-one-out variances of the remainder component. Other features measure structural
## changes over time. measure11-17 - Strength of trend and seasonality and spike
VarTS <- function(x, tspx) {
    x <- as.ts(x)
    tsp(x) <- tspx
    freq <- tspx[3]
    contx <- try(na.contiguous(x), silent = TRUE)
    len.contx <- length(contx)
    if (length(contx) < 2 * freq || class(contx) == "try-error") {
        trend <- linearity <- curvature <- season <- spike <- peak <- trough <- NA
    } else {
        if (freq > 1L) {
            all.stl <- stl(contx, s.window = "periodic", robust = TRUE)
            starty <- start(contx)[2L]
            pk <- (starty + which.max(all.stl$time.series[, "seasonal"]) - 1L)%%freq
            th <- (starty + which.min(all.stl$time.series[, "seasonal"]) - 1L)%%freq
            pk <- ifelse(pk == 0, freq, pk)
            th <- ifelse(th == 0, freq, th)
            trend0 <- all.stl$time.series[, "trend"]
            fits <- trend0 + all.stl$time.series[, "seasonal"]
            adj.x <- contx - fits
            v.adj <- var(adj.x, na.rm = TRUE)
            detrend <- contx - trend0
            deseason <- contx - all.stl$time.series[, "seasonal"]
            peak <- pk * max(all.stl$time.series[, "seasonal"], na.rm = TRUE)
            trough <- th * min(all.stl$time.series[, "seasonal"], na.rm = TRUE)
            remainder <- all.stl$time.series[, "remainder"]
            season <- ifelse(var(detrend, na.rm = TRUE) < 1e-10, 0, max(0, min(1, 1 - v.adj/var(detrend, na.rm = TRUE))))
        } else {
            # No seasonal component
            tt <- 1:len.contx
            trend0 <- fitted(mgcv::gam(contx ~ s(tt)))
            remainder <- contx - trend0
            deseason <- contx - trend0
            v.adj <- var(trend0, na.rm = TRUE)
        }
        trend <- ifelse(var(deseason, na.rm = TRUE) < 1e-10, 0, max(0, min(1, 1 - v.adj/var(deseason, na.rm = TRUE))))
        n <- length(remainder)
        v <- var(remainder, na.rm = TRUE)
        d <- (remainder - mean(remainder, na.rm = TRUE))^2
        varloo <- (v * (n - 1) - d)/(n - 2)
        spike <- var(varloo, na.rm = TRUE)
        pl <- poly(1:len.contx, degree = 2)
        tren.coef <- coef(lm(trend0 ~ pl))[2:3]
        linearity <- tren.coef[1]
        curvature <- tren.coef[2]
    }
    if (freq > 1) {
        return(list(trend = trend, season = season, spike = spike, peak = peak, trough = trough, linearity = linearity, curvature = curvature))
    } else {
        # No seasonal component
        return(list(trend = trend, spike = spike, linearity = linearity, curvature = curvature))
    }
}


## A function to calculate the burstiness of time series using Fano Factor Returns the 'burstiness' statistic: $(\sigma^2)
## / \mu$. Another measures of burstiness is the Fano Factor: a ratio between the variance and the mean . In statistis Fano
## Factor , like the coefficient of variation, is a measure of dispersion of proability distributions of a Fano noise. Fano
## factor is defined as $(\sigma^2) / \mu$. measure19 - Calculate the burstiness statistic
BurstFF <- function(x) {
    B = (sd(x, na.rm = TRUE)^2)/mean(x, na.rm = TRUE)
    return(B)
}


### Time series Minimum and Maximum Returns the minimum and maximum of the time series measure21,22 - Calculate the time
### series minimum and maximum
tsminmax <- function(x) {
    return(list(mn = min(x, na.rm = TRUE), mx = max(x, na.rm = TRUE)))
}

### a function to calculate the ratio between trimmed mean to mean the ratio between interquartile mean and the arithmetic
### mean of the scaled data. Low values (values closer to zero) indicate the presence of outliers. measure28 - the ratio
### between interquartile mean and the arithmetic mean
rmeaniqmean <- function(x) {
    out = mean(x, trim = 0.5, na.rm = TRUE)/mean(x, na.rm = TRUE)
    return(out)
}


## A function to calculate the moments Returns the moment of the distribution (the measure moments, m of the distribution,
## for m= 3,4,5,...,11.) of the input time series, normalizes by the standard deviation. Output This operation Uses the
## moments package in R measure29 - moments m of the distribution
dmoments <- function(x) {
    # momentssd<-rep(0,9) for(i in 1:9) {momentssd[i]= moments::moment(x, order=i+2, na.rm=TRUE) } out=momentssd/sd(x)
    # return(list(m3=out[1], m4=out[2], m5=out[3], m6=out[4], m7=out[5], m8=out[6], m9=out[7], m10=out[8], m11=out[9]))
    
    momentssd <- 0
    momentssd = moments::moment(x, order = 3, na.rm = TRUE)
    out = momentssd/sd(x, na.rm = TRUE)
    return(out)
}


## A function to compare the means of data that is below and upper the global mean Calculates a statistic related to the
## mean of the time series data that is above the (global) time-series mean compared to the mean of the data that is below
## the global time-series mean. measure32 - compare the means of data that is below and upper the global mean
highlowmu <- function(x) {
    mu = mean(x, na.rm = TRUE)
    mhi = mean(x[x > mu], na.rm = TRUE)
    mlo = mean(x[x < mu], na.rm = TRUE)
    out = mhi - mu/(mu - mlo)
    return(out)
}










