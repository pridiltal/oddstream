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
#' @seealso \code{\link{extract_tsfeatures}}, \code{\link[pcaPP]{PCAproj}}, \code{\link[stats]{prcomp}}
#' @export
#' @importFrom pcaPP PCAproj
#' @importFrom stats prcomp
#' @examples
get_pc_space <- function(features, robust = TRUE) {
    
    if (robust) {
        pc <- pcaPP::PCAproj(f1, ncol(f1), scale = sd, center = mean)
        pcnorm <- pc$scores[, 1:2]
        colnames(pcnorm) <- c("PC1", "PC2")
        pc <- list(pcnorm = pcnorm, center = pc$center, scale = pc$scale, rotation = pc$loadings[, 1:ncol(f1)])
    } else {
        pc <- stats::prcomp(features, center = TRUE, scale. = TRUE)
        pcnorm <- pc$x[, 1:2]
        pc <- list(pcnorm = pcnorm, center = pc$center, scale = pc$scale, rotation = pc$rotation)
    }
    
    class(pc) <- "pcattributes"
    return(pc)
    
}


#' Plot a two dimensional feature space on the current graphics device.
#'
#' @description Plot a two dimensional feature space on the current graphics device using the first two
#' pricipal component returned by \code{\link{get_pc_space}}
#' @param pc_pcnorm The scores of the first two pricipal components returned by \code{get_pc_space}
#' @return A graphical representation of the two dimensional feature space will be produced on the current graphic
#' device.
#' @seealso \code{\link{get_pc_space}}
#' @export
#' @importFrom ggplot2 ggplot
#' @importFrom plotly ggplotly
#' @examples
plotpc <- function(pc_pcnorm) {
    data <- data.frame(cbind(pc_pcnorm, series = 1:nrow(pc_pcnorm)))
    colnames(data) <- c("PC1", "PC2", "series")
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
        stop("ggplot2 needed for this function to work. Please install it.", call. = FALSE)
    }
    pc_space <- ggplot2::ggplot(data, aes(x = PC1, y = PC2, label1 = series)) + geom_point()
    if (!requireNamespace("plotly", quietly = TRUE)) {
        stop("plotly needed for this function to work. Please install it.", call. = FALSE)
    }
    plotly::ggplotly(pcplot)
}



