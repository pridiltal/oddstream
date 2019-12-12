#' Set a threshold for outlier detection
#'
#' @description This function forecasts a boundary for the typical behaviour using a representative sample
#' of the typical behaviour of a given system. An approach based on extreme value theory is used for this boundary
#' prediction process.
#' @param pc_pcnorm The scores of the first two pricipal components returned by \code{\link{get_pc_space}}
#' @param p_rate False positive rate. Default value is set to 0.001
#' @param trials Number of trials to generate the extreme value distirbution. Default value is set to 500.
#' @return Returns a threshold to determine outlying series in the next window  consists with a collection of
#' time series.
#' @seealso  \code{\link{find_odd_streams}},  \code{\link{extract_tsfeatures}}, \code{\link{get_pc_space}},
#' \code{\link{gg_featurespace}}
#' @export
#' @importFrom ks Hscv
#' @importFrom ks kde
#' @importFrom MASS mvrnorm
#' @references Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate extreme value statistics.
#' Journal of signal processing systems, 65 (3),371-389.
#'
#' Talagala, P., Hyndman, R., Smith-Miles, K., Kandanaarachchi, S., & Munoz, M. (2018).
#' Anomaly detection in streaming nonstationary temporal data (No. 4/18).
#' Monash University, Department of Econometrics and Business Statistics.
#'
#' @examples
#' \donttest{
#' #Generate training dataset
#' set.seed(123)
#' nobs = 500
#' nts = 50
#' train_data <- ts(apply(matrix(ncol = nts, nrow = nobs), 2, function(nobs){10 + rnorm(nobs, 0, 3)}))
#' features <- extract_tsfeatures(train_data)
#' pc <- get_pc_space(features)
#' threshold <- set_outlier_threshold(pc$pcnorm)
#' threshold$threshold_fnx
#' }
#'
set_outlier_threshold <- function(pc_pcnorm, p_rate = 0.001, trials = 500) {

  # Calculating the density region for typical data
  H_scv <- ks::Hscv(x = pc_pcnorm)
  fhat2 <- ks::kde(x = pc_pcnorm, H = H_scv, compute.cont = TRUE)

  # generating data to find the threshold value
  fun2 <- function(x) {
    return(MASS::mvrnorm(n = 1, mu = x, Sigma = H_scv))
  }
  m <- nrow(pc_pcnorm)
  xtreme_fx <- numeric(trials)
  f_extreme <- function(tempt) {
    s <- sample(1:m, size = m, replace = T)
    fhat <- ks::kde(
      x = pc_pcnorm, H = H_scv, compute.cont = TRUE,
      eval.points = t(apply(pc_pcnorm[s, ], 1, fun2))
    )
    return(tempt <- min(fhat$estimate))
  }
  xtreme_fx <- sapply(X = xtreme_fx, f_extreme)


  k <- 1 / (2 * pi)
  psi_trans <- ifelse(xtreme_fx < k, (-2 * log(xtreme_fx) - 2 * log(2 * pi))^0.5, 0)
  p <- sum(!(psi_trans == 0)) / length(psi_trans)
  y <- -log(-log(1 - p_rate * p))
  cm <- sqrt(2 * log(m)) - ((log(log(m)) + log(4 * pi)) / (2 * sqrt(2 * log(m))))
  dm <- 1 / (sqrt(2 * log(m)))
  t <- cm + y * dm
  threshold_fnx <- exp(-((t^2) + 2 * log(2 * pi)) / 2)

  return(list(threshold_fnx = threshold_fnx, fhat2 = fhat2, H_scv = H_scv))
}
