#' Detect outlying series within a collection of  sreaming time series
#'
#' @description This function detect outlying series within a collection of streaming time series. A sliding window
#' is used to handle straming data. In the precence of concept drift, the forecast boundary for the system's typical
#' behaviour can be updated periodically.
#' @param test_stream A multivariate streaming time series data set
#' @param pc The pricipal component attributes  returned by \code{\link{get_pc_space}}
#' @param threshold A threshold value to determine outlying series. A value returned by
#' \code{\link{set_outlier_threshold}}
#' @param update_threshold If TRUE, the threshold value to determine outlying series is updated.
#' The default value is set to TRUE
#' @param update_threshold A numerical value to indicated how often the threshold should be updated.
#'  (After how many windows
#' it should be updated)
#' @return The indices of the outlying series in each window. For each window a plot is also produced on the current
#' graphic device
#' @seealso \code{\link{get_pc_space}}, \code{\link{set_outlier_threshold}}
#' @export
#' @references
find_odd_streams <- function(test_stream, pc, threshold, update_threshold = TRUE, update_threshold_freq) {

    # function definition

    # input pc, test_stream , threshold, update_threshold, update_threshold_freq start moving window model for each window : w

    # extract_features(w)
    # project to same pc space using 'pc' input values
    # d<- calculate densities
    # check which[d<threshold]
    # if(update_threshold = TRUE)
    # new_w <- filter non-outliers
    # f_new <- extract_teatures(new_w)
    # pc <- get_pc_space(f_new)
    # t_new <- set_outlier_threshold


}
