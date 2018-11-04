#' Define a feature space using the PCA components of the feature matrix
#'
#' @description Define a two dimensional feature space using the first two principal components generated from
#' the fetures matrix returned by \code{extract_tsfeatures}
#' @param features Feature matrix returned by \code{\link{extract_tsfeatures}}
#' @param robust If TRUE, a robust PCA will be used on the feature matrix.
#' @param kpc Desired number of components to return.
#' @return It returns a list with class 'pcattributes' containing the following components:
#'    \item{pcnorm}{The scores of the firt kpc pricipal components}
#'    \item{center, scale}{The centering and scaling used}
#'    \item{rotation}{the matrix of variable loadings (i.e., a matrix whose columns contain the eigenvectors).
#'                    The function \code{princomp} returns this in the element loadings.}
#' @seealso  \code{\link[pcaPP]{PCAproj}}, \code{\link[stats]{prcomp}}, \code{\link{find_odd_streams}},
#' \code{\link{extract_tsfeatures}}, \code{\link{set_outlier_threshold}}, \code{\link{gg_featurespace}}
#' @export
#' @importFrom pcaPP PCAproj
#' @importFrom stats prcomp
#' @examples
#' features <- extract_tsfeatures(anomalous_stream[1:100, 1:100])
#' pc <- get_pc_space(features)
#'
get_pc_space <- function(features, robust = TRUE, kpc = 2) {
  if (robust) {
    pc <- pcaPP::PCAproj(features, k = ncol(features), scale = sd, center = mean)
    pcnorm <- pc$scores[, 1:kpc]
    colnames(pcnorm) <- c("PC1", "PC2")
    pc <- list(
      pcnorm = pcnorm, center = pc$center, scale = pc$scale,
      rotation = pc$loadings[, 1:ncol(features)]
    )
  } else {
    pc <- stats::prcomp(features, center = TRUE, scale. = TRUE)
    pcnorm <- pc$x[, 1:kpc]
    colnames(pcnorm) <- c("PC1", "PC2")
    pc <- list(
      pcnorm = pcnorm, center = pc$center, scale = pc$scale,
      rotation = pc$rotation
    )
  }

  class(pc) <- "pcoddstream"
  return(pc)
}



#' Produces a ggplot object of two dimensional feature space.
#'
#' @description Create a ggplot object of two dimensional feature space  using the first two
#' pricipal component returned by \code{\link{get_pc_space}}.
#' @param object Object of class \dQuote{\code{pcoddstream}}.
#' @param ... Other plotting parameters to affect the plot.
#' @return A ggplot object of two dimensional feature space.
#' @export
#' @seealso \code{\link{find_odd_streams}}, \code{\link{extract_tsfeatures}}, \code{\link{get_pc_space}},
#' \code{\link{set_outlier_threshold}}
#' @import ggplot2
#' @importFrom tibble as_tibble
#' @examples
#' features <- extract_tsfeatures(anomalous_stream[1:100, 1:100])
#' pc <- get_pc_space(features)
#' p <- gg_featurespace(pc)
#' p + ggplot2::geom_density_2d()
gg_featurespace <- function(object, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is needed for this function to work. Install it via
         install.packages(\"ggplot2\")", call. = FALSE)
  }
  else {
    data <- tibble::as_tibble(object$pcnorm[, 1:2])

    # Initialise ggplot object
    p <- ggplot2::ggplot(
      data = data,
      ggplot2::aes_(x = ~PC1, y = ~PC2)
    )

    # Add data
    p <- p + ggplot2::geom_point(color = "cornflowerblue", size = 2, alpha = 0.8)

    # Add theme
    p <- p + ggplot2::theme(aspect.ratio = 1)

    # Add labels
    p <- p + ggplot2::labs(title = "Two dimensional feature space")

    return(p)
  }
}
