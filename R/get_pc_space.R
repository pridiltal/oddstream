#' Define a feature space using the PCA components of the feature matrix
#'
#' @description Define a two dimensional feature space using the first two principal components generated from
#' the fetures matrix returned by \code{extract_tsfeatures}
#' @param features Feature matrix returned by \code{\link{extract_tsfeatures}}
#' @param robust If TRUE, a robust PCA will be used on the feature matrix
#' @return It returns a list with class 'pcattributes' containing the following components:
#'    \item{pcnorm}{The scores of the firt two pricipal components}
#'    \item{center, scale}{The centering and scaling used}
#'    \item{rotation}{the matrix of variable loadings (i.e., a matrix whose columns contain the eigenvectors).
#'                    The function \code{princomp} returns this in the element loadings.}
#' @seealso  \code{\link[pcaPP]{PCAproj}}, \code{\link[stats]{prcomp}}, \code{\link{find_odd_streams}},
#' \code{\link{extract_tsfeatures}}, \code{\link{set_outlier_threshold}}, \code{\link{plotpc}}
#' @export
#' @importFrom pcaPP PCAproj
#' @importFrom stats prcomp
#' @examples
#' features <- extract_tsfeatures(anomalous_stream[1:100, 1:100])
#' pc <- get_pc_space(features)
#'
get_pc_space <- function(features, robust = TRUE) {

    if (robust) {
        pc <- pcaPP::PCAproj(features, ncol(features), scale = sd, center = mean)
        pcnorm <- pc$scores[, 1:2]
        colnames(pcnorm) <- c("PC1", "PC2")
        pc <- list(pcnorm = pcnorm, center = pc$center, scale = pc$scale, rotation = pc$loadings[, 1:ncol(features)])
    } else {
        pc <- stats::prcomp(features, center = TRUE, scale. = TRUE)
        pcnorm <- pc$x[, 1:2]
        colnames(pcnorm) <- c("PC1", "PC2")
        pc <- list(pcnorm = pcnorm, center = pc$center, scale = pc$scale, rotation = pc$rotation)
    }

    class(pc) <- "pcattributes"
    return(pc)

}



#' Plot a two dimensional feature space on the current graphics device.
#'
#' @description Plot a two dimensional feature space on the current graphics device using the first two
#' pricipal component returned by \code{\link{get_pc_space}}
#' @param pc_pcnorm The scores of the first two pricipal components returned by \code{\link{get_pc_space}}
#' @param colour The color of the point. Default is set to "blue"
#' @param alpha  The transparency of the point range from 0 to 1. (default: 0.8)
#' @param pc_boundary Expand the pc plot limits by this amount. Default value is set to 10
#' @return A graphical representation of the two dimensional feature space will be produced on the current graphic
#' device.
#' @seealso \code{\link{find_odd_streams}},  \code{\link{extract_tsfeatures}}, \code{\link{get_pc_space}},
#' \code{\link{set_outlier_threshold}}
#' @export
#' @import ggplot2
#' @importFrom tibble as_tibble
#' @examples
#' features <- extract_tsfeatures(anomalous_stream[1:100, 1:100])
#' pc <- get_pc_space(features)
#' plotpc(pc$pcnorm)
plotpc <- function(pc_pcnorm, colour = "cornflowerblue", alpha = 0.8, pc_boundary = 10) {
    data <- tibble::as_tibble(pc_pcnorm)
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
       stop("ggplot2 needed for this function to work. Please install it.", call. = FALSE)
    }
    pc_space <- ggplot2::ggplot(data) +
      geom_point(aes_string(x ="PC1", y = "PC2"), color = colour, size = 2, alpha = alpha) +
      theme(aspect.ratio = 1,) +
      expand_limits(y = c(-pc_boundary, pc_boundary),
                    x = c(-pc_boundary,pc_boundary))
    print(pc_space)
}



