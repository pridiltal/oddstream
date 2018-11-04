#' Detect outlying series within a collection of  sreaming time series
#'
#' @description This function detect outlying series within a collection of streaming time series. A sliding window
#' is used to handle straming data. In the precence of concept drift, the forecast boundary for the system's typical
#' behaviour can be updated periodically.
#' @param train_data A multivariate time series data set that represents the typical behaviour of the system.
#' @param test_stream A multivariate streaming time series data set to be tested for outliers
#' @param window_length Sliding window size (Ideally this window length should be equal to the length of the
#'  training multivariate time series data set that is used to define the outlying threshold)
#' @param window_skip The number of steps the window should slide forward. The default is set to window_length
#' @param update_threshold If TRUE, the threshold value to determine outlying series is updated.
#' The default value is set to TRUE
#' @param concept_drift If TRUE, The outlying threshold will be updated after each window. The default is set
#' to FALSE
#' @param trials Input for \code{set_outlier_threshold} function. Default value is set to 500.
#' @param p_rate False positive rate. Default value is set to 0.001.
#' @param cd_alpha  Singnificance level for the test of non-stationarity.
#' @return a list with components
#' \item{out_marix}{The indices of the outlying series in each window}
#' \item{p_value}{p-value for the two sample comparison test for concept drift detection}
#' \item{anom_threshold}{anomalous threshold}
#' For each window a plot is also produced on the current
#' graphic device
#' @seealso  \code{\link{extract_tsfeatures}}, \code{\link{get_pc_space}}, \code{\link{set_outlier_threshold}},
#' \code{\link{gg_featurespace}}
#' @export
#' @importFrom ks kde
#' @importFrom ks Hscv
#' @importFrom mvtsplot mvtsplot
#' @importFrom tibble as_tibble
#' @importFrom reshape melt
#' @importFrom dplyr mutate
#' @importFrom tidyr gather
#' @importFrom kernlab kmmd
#' @import stats
#' @examples
#' #Generate training dataset
#' set.seed(890)
#' nobs = 250
#' nts = 100
#' train_data <- ts(apply(matrix(ncol = nts, nrow = nobs), 2, function(nobs){10 + rnorm(nobs, 0, 3)}))
#' # Generate test stream with some outliying series
#' nobs = 15000
#' test_stream <- ts(apply(matrix(ncol = nts, nrow = nobs), 2, function(nobs){10 + rnorm(nobs, 0, 3)}))
#' test_stream[360:1060, 20:25] = test_stream[360:1060, 20:25] * 1.75
#' test_stream[2550:3550, 20:25] =  test_stream[2550:3550, 20:25] * 2
#' find_odd_streams(train_data, test_stream , trials = 100)

#'
#' # Considers the first window  of the data set as the training set and the remaining as
#' # the test stream
#' train_data <- anomalous_stream[1:100,]
#' test_stream <-anomalous_stream[101:1456,]
#' find_odd_streams(train_data, test_stream , trials = 100)
#'
#' @references Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate
#' extreme value statistics. Journal of signal processing systems, 65 (3),371-389.
#'
#' Duong, T., Goud, B. & Schauer, K. (2012) Closed-form density-based framework for automatic detection
#' of cellular morphology changes. PNAS, 109, 8382-8387.
#'
#' Talagala, P., Hyndman, R., Smith-Miles, K., Kandanaarachchi, S., & Munoz, M. (2018).
#' Anomaly detection in streaming nonstationary temporal data (No. 4/18).
#' Monash University, Department of Econometrics and Business Statistics.

find_odd_streams <- function(train_data, test_stream, update_threshold = TRUE, window_length = nrow(train_data),
                             window_skip = window_length, concept_drift = FALSE, trials = 500,
                             p_rate = 0.001, cd_alpha = 0.05) {

  # Calculate initial anomalous threshold
  train_features <- extract_tsfeatures(train_data)
  pc <- get_pc_space(train_features)
  t <- set_outlier_threshold(pc$pcnorm, p_rate, trials = trials)

  # Define windows
  start <- seq(1, nrow(test_stream), window_skip)
  end <- seq(window_length, nrow(test_stream), window_skip)

  X2 <- Series <- out_marix <- concept <- anom_threshold <- NULL
  i <- 2
  series <- 1:ncol(test_stream)

  while (i <= length(end)) {
    # Project test data to the two dimensional feature space
    window_data <- test_stream[start[i]:end[i], ]
    window_features <- extract_tsfeatures(window_data)
    pc_test <- scale(window_features, pc$center, pc$scale) %*% pc$rotation
    pctest <- pc_test[, 1:2]

    # Calculate densities of the test data points
    fhat_test <- ks::kde(x = pc$pcnorm, H = t$H_scv, compute.cont = TRUE, eval.points = pctest)

    # Identify anomalies
    outliers <- which(fhat_test$estimate < t$threshold_fnx)
    outlier_names <- paste("series", outliers, sep = " ")
    if (length(outliers) > 0) {
      cat("Outliers from: ", start[i], " to: ", end[i], ": ", outliers, "\n")
    } else {
      cat("Outliers from: ", start[i], " to: ", end[i], ": ", "NULL", "\n")
    }

    # Store results
    out_marix <- rbind(out_marix, t(ifelse(series %in% outliers, 1, 0)))

    # Update anomalous threshold for non-stationary environments (concept drift)
    if (concept_drift == TRUE) {
      new_t <- update_anom_threshold(outliers, series, pc, pctest, p_rate, trials, cd_alpha)
      concept <- c(concept, new_t$p_val)
      anom_threshold <- c(anom_threshold, new_t$anom_t)
    }

    i <- i + 1
  }

  return(list(out_marix = out_marix, p_value = concept, anom_threshold = anom_threshold))
}








## Function to update the anomalous threshold for nonstationarity
update_anom_threshold <- function(outliers, series, pc, pctest, p_rate, trials, cd_alpha) {
  out_n <- length(outliers)
  out_p <- out_n / length(series)

  if (out_n > 0 & out_p < 0.5) {
    ktest <- ks::kde.test(x1 = pc$pcnorm, x2 = pctest[-outliers, ])
  }

  if ((out_n == 0) || (out_n > 0 & out_p > 0.5)) {
    ktest <- ks::kde.test(x1 = pc$pcnorm, x2 = pctest)
  }

  if ((ktest$pvalue < cd_alpha) & (out_n > 0) & (out_p < 0.5)) {
    t <- set_outlier_threshold(pctest[-outliers, ], p_rate, trials = trials)
    pc$pcnorm <- pctest[-outliers, ]
  }

  if (((ktest$pvalue < cd_alpha) & (out_n == 0)) ||
    ((ktest$pvalue < cd_alpha) & (out_n > 0) & (out_p > 0.5))) {
    t <- set_outlier_threshold(pctest, p_rate, trials = trials)
    pc$pcnorm <- pctest
  }

  return(list(p_val = ktest$pvalue, anom_t = t$threshold_fnx))
}
