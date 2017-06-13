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
#' @param update_threshold_freq A numerical value to indicated how often the threshold should be updated.
#'  (After how many windows it need be updated)
#' @param plot_type if "line" multivariate time series plot,  If "pcplot"  two dimensional PC space or if
#' "mvtsplot" mvtsplot will be  produced on the current graphic device. For large complex data sets 'mvtsplot'
#' is recommended
#' @param concept_drift If TRUE, The outlying threshold will be updated after each window. The default is set
#' to FALSE
#' @param trials Input for \code{set_outlier_threshold} function. Default value is set to 500.
#' @return The indices of the outlying series in each window. For each window a plot is also produced on the current
#' graphic device
#' @seealso  \code{\link{extract_tsfeatures}}, \code{\link{get_pc_space}}, \code{\link{set_outlier_threshold}},
#' \code{\link{plotpc}}
#' @export
#' @importFrom ks kde
#' @importFrom ks Hscv
#' @importFrom plotly ggplotly
#' @importFrom ggplot2 ggplot
#' @importFrom mvtsplot mvtsplot
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
#' find_odd_streams(train_data, test_stream , plot_type = 'line', trials = 100)
#'
#' # To get the PCplot
#' #find_odd_streams(train_data, test_stream , plot_type = 'pcplot')
#'
#' # This example considers the first window  of \code{data1} as the training dataset and the remaining as
#' # the test stream
#' train_data <- data1[1:150,]
#' test_stream <-data1[151:1456,]
#' find_odd_streams(train_data, test_stream , plot_type = "mvtsplot", trials = 100)
#' @references Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate
#' extreme value statistics. Journal of signal processing systems, 65 (3),371-389.
#'
#'
find_odd_streams <- function(train_data, test_stream, update_threshold = TRUE, update_threshold_freq,
                             plot_type = c("mvtsplot", "line", "pcplot"), window_length = nrow(train_data),
                             window_skip = window_length, concept_drift = FALSE, trials = 500 ) {

    train_features <- extract_tsfeatures(train_data)
    pc <- get_pc_space(train_features)
    t <- set_outlier_threshold(pc$pcnorm, trials = trials )
    start <- seq(1, nrow(test_stream), window_skip)
    end <- seq(window_length, nrow(test_stream), window_skip)

    i <- 1
    while (i <= length(end)) {
        window_data <- test_stream[start[i]:end[i], ]

        window_features <- extract_tsfeatures(window_data)
        pc_test <- scale(window_features, pc$center, pc$scale) %*% pc$rotation
        pctest <- pc_test[, 1:2]
        fhat_test <- ks::kde(x = pc$pcnorm, H = t$H_scv, compute.cont = TRUE, eval.points = pctest)
        outliers <- which(fhat_test$estimate < t$threshold_fnx)


        if (plot_type == "line") {
            par(pty = "s")
            plot.ts(as.ts(window_data), plot.type = "single", main = paste("data from: ", start[i], " to: ", end[i]), ylim = c(0,
                range(train_data)[2] * 4), ylab = "Value")
            if (length(outliers) > 0) {
                f <- function(x) {
                  lines(window_data[, x], col = "red", lwd = 2)
                }
                lapply(outliers, f)
            }
        }
        if (plot_type == "pcplot") {
            par(pty = "s")
            plot(t$fhat2, drawpoints = FALSE, abs.cont = t$threshold_fnx, col = "red", add = F, xlim = range(t$fhat2$x[, 1]) *
                40, ylim = range(t$fhat2$x[, 2]) * 40, main = paste("data from: ", start[i], " to: ", end[i]))
            points(pctest[, 1], pctest[, 2], col = "grey", pch = 16)

            if (length(outliers) > 0) {
                points(pctest[outliers, 1], pctest[outliers, 2], col = "red", pch = 16)
                text(pctest[outliers, 1], pctest[outliers, 2], labels = outliers, pos = 1, cex = 0.8, col = "black")
            }

        }
        if (plot_type == "mvtsplot") {
           par(pty = "m")
           colnames(window_data) <- 1:ncol(window_data)
           mvtsplot::mvtsplot(window_data, levels=8, gcol=2, norm="global")
        }



        if (length(outliers) > 0) {
           cat("Outliers from: ", start[i], " to: ", end[i], ": ", outliers, "\n")
        } else {
           cat("Outliers from: ", start[i], " to: ", end[i], ": ", "NULL", "\n")
        }

        if (concept_drift == TRUE)
        {
          if (length(outliers) > 0) {
             train_features <- window_features[-outliers, ]
          } else {
             train_features <- window_features
          }

          pc <- get_pc_space(train_features)
          t <- set_outlier_threshold(pc$pcnorm, trials = trials)
        }

        i <- i + 1

    }
    dev.off()
}
