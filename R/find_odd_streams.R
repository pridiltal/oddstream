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
#' "mvtsplot" mvtsplot will be  produced on the current graphic device. For large complex data sets 'mvtsplot' or
#'  'out_location_plot' are recommended
#' @param concept_drift If TRUE, The outlying threshold will be updated after each window. The default is set
#' to FALSE
#' @param trials Input for \code{set_outlier_threshold} function. Default value is set to 500.
#' @param pc_boundary Expand the pc plot limits by this amount. Default value is set to 50
#' @return The indices of the outlying series in each window. For each window a plot is also produced on the current
#' graphic device
#' @seealso  \code{\link{extract_tsfeatures}}, \code{\link{get_pc_space}}, \code{\link{set_outlier_threshold}},
#' \code{\link{plotpc}}
#' @export
#' @importFrom ks kde
#' @importFrom ks Hscv
#' @importFrom mvtsplot mvtsplot
#' @importFrom tibble as_tibble
#' @importFrom reshape melt
#' @importFrom dplyr mutate
#' @importFrom tidyr gather
#' @import graphics
#' @import stats
#' @import ggplot2
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
#' # Considers the first window  of the data set as the training set and the remaining as
#' # the test stream
#' train_data <- anomalous_stream[1:100,]
#' test_stream <-anomalous_stream[101:1456,]
#' find_odd_streams(train_data, test_stream , plot_type = "out_location_plot", trials = 100)
#' @references Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate
#' extreme value statistics. Journal of signal processing systems, 65 (3),371-389.
#'
#'
find_odd_streams <- function(train_data, test_stream, update_threshold = TRUE, update_threshold_freq,
                             plot_type = c("mvtsplot", "line", "pcplot", "out_location_plot"), window_length = nrow(train_data),
                             window_skip = window_length, concept_drift = FALSE, trials = 500, pc_boundary = 50) {

  train_features <- extract_tsfeatures(train_data)
  train_features <- scale(train_features, center = TRUE, scale = TRUE)
  pc <- get_pc_space(train_features)
  t <- set_outlier_threshold(pc$pcnorm, trials = trials )
  start <- seq(1, nrow(test_stream), window_skip)
  end <- seq(window_length, nrow(test_stream), window_skip)

  X2 = Series = NULL
  i <- 2
  while (i <= length(end)) {
    window_data <- test_stream[start[i]:end[i], ]

    window_features <- extract_tsfeatures(window_data)
    window_features <- scale(window_features, center = TRUE, scale = TRUE)
    pc_test <- scale(window_features, pc$center, pc$scale) %*% pc$rotation
    pctest <- pc_test[, 1:2]
    fhat_test <- ks::kde(x = pc$pcnorm, H = t$H_scv, compute.cont = TRUE, eval.points = pctest)
    outliers <- which(fhat_test$estimate < t$threshold_fnx)
    colnames(pctest) <- c("PC1", "PC2")
    pctest <- tibble::as_tibble(pctest)
    outlier_names <- paste("series", outliers, sep= " ")

    if (plot_type == "line") {

      if(!(is.matrix(window_data)))
      {
        row.names(window_data) <- NULL
        window_data <- data.matrix(window_data)
      }

      window_data_melt <- reshape::melt(as.matrix(window_data))
      window_data_melt <- dplyr::mutate(window_data_melt,
                                        type = ifelse(tolower(X2) %in% tolower(outlier_names),
                                                      "outlier" ,"normal"))
      line_plot <- ggplot(window_data_melt) +
        geom_line(aes_string(x="X1", y="value", group = "X2", color = "type"),
                  alpha=0.8, size = I(0.5))+
        scale_colour_manual(name="Type",
                            values = c("outlier"="red", "normal"="darkgray")) +
        xlab("Time") +
        ggtitle(paste("Data from: ", start[i], " to: ", end[i]))+
        expand_limits(y = c(-pc_boundary, pc_boundary))
      #ylim(-5,50)
      print(line_plot)
    }

    if (plot_type == "pcplot") {
      pc_norm <- tibble::as_tibble(pc$pcnorm)
      pc_norm <- dplyr::mutate(pc_norm, Series = 1:nrow(pc_norm))
      p1 <-  ggplot(pc_norm) +
        geom_point(aes_string(x="PC1", y= "PC2"),alpha = 0.5, color = "gray")+
        theme(aspect.ratio = 1) +
        expand_limits(y = c(-pc_boundary, pc_boundary),
                      x = c(-pc_boundary,pc_boundary))


      pc_test <- dplyr::mutate(pctest, Series = 1:nrow(pctest))
      pc_test <- dplyr::mutate(pc_test, type = ifelse(Series %in% outliers,
                                                      "outlier" ,"normal"))

      labeled.dat <- pc_test[pc_test$Series %in% outliers ,]
      p2 <-  p1 +
        geom_point(data = pc_test, alpha = 0.5,
                   aes_string(x="PC1", y= "PC2", colour = "type")) +
        scale_colour_manual(name="Type",
                            values = c("outlier"="red", "normal"="lightblue")) +
        ggtitle(paste("Data from: ", start[i], " to: ", end[i])) +
        geom_text( data = labeled.dat,aes_string(x="PC1", y= "PC2", label = "Series"), hjust = 2)
      print(p2)


    }
    if (plot_type == "out_location_plot") {

      pctest <- tibble::as_tibble(pctest)
      pc_test <- dplyr::mutate(pctest, Series = 1:nrow(pctest))
      pc_test <- dplyr::mutate(pc_test, type = ifelse(Series %in% outliers,
                                                      "outlier" ,"normal"))

      out_plot <- ggplot(pc_test, aes_string(x= "type", y= "Series", colour = "type")) +
        geom_point()+
        theme(aspect.ratio = 2) +
        scale_colour_manual(name="Type", values = c("outlier"="red",
                                                    "normal"="lightblue"))+
        ggtitle(paste("Data from: ", start[i], " to: ", end[i]))

      print(out_plot)
    }

    if (plot_type == "mvtsplot") {
      #par(pty = "m")
      #colnames(window_data) <- 1:ncol(window_data)
      #mvtsplot::mvtsplot(window_data, levels=8, gcol=2, norm="global")

      t <- nrow(window_data)
      f <- ncol(window_data)
      window_data <- tibble::as_tibble(window_data)
      g <- tidyr::gather(window_data)
      g <- dplyr::mutate(g, key= rep((1:f), each = t), Time = rep(1:t, f))
      colnames(g) <- c("TimeSeiresID", "Value", "Time")

      mvtsplot <- ggplot(g, aes_string(x = "TimeSeiresID",
                                       y = "Time", fill = "Value")) +
        geom_tile() +
        scale_fill_gradientn(colours = c("lightblue", "orangered1",
                                         "orangered2"),
                             values = c(0,.1,max(window_data)))+
        xlab("Time Series ID)") +
        ylab("Time") +
        theme(aspect.ratio = 1)

      print(mvtsplot)

    }



    if (length(outliers) > 0) {
      cat("Outliers from: ", start[i], " to: ", end[i], ": ", outliers, "\n")
    } else {
      cat("Outliers from: ", start[i], " to: ", end[i], ": ", "NULL", "\n")
    }

    if (concept_drift == TRUE)
    {
      if (length(outliers) > 0) {
        t <- set_outlier_threshold(pctest[-outliers,], trials = trials )
        pc$pcnorm <- pctest[-outliers,]
      } else {
        t <- set_outlier_threshold(pctest, trials = trials )
        pc$pcnorm <- pctest
      }
    }

    i <- i + 1

  }
  # dev.off()
}
