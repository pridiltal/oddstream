#' Define a feature space using the PCA components of the feature matrix
#' @description Define a two dimensional space using the first two principal components generated from the fetures
#' returned by \code{extract_tsfeatures}
#' @param features Feature matrix returned by \code{extract_tsfeatures}
#' @param plot If TRUE, a graphical representation of the 2D feature space will be produced on the current graphic
#' device.
#' @param robust If TRUE, a robust PCA will be used on the feature matrix
#' @return A plot of two dimentional feature space is produces on the current graphics device. Further it returns
#' a list with class "pcattributes" containing the following components:
#'    \item{center, scale}{The centering and scaling used}
#'    \item{rotation}{}
#'
#'
get_pc_space <- function(features, plot= TRUE, robust = TRUE){

  if (robust) {
    pc <- pcaPP::PCAproj(f1, ncol(f1), scale = sd, center = mean)
    pcnorm <- pc$scores[,1:2]
    colnames(pcnorm) <- c("PC1", "PC2")
    pc <- list(pcnorm = pcnorm, center = pc$center, scale  = pc$scale, rotation = pc$loadings[,1:ncol(f1)])
  } else {
    pc <- stats::prcomp(features,center = TRUE, scale. = TRUE)
    pcnorm <- pc$x[,1:2]
    pc <- list(pcnorm = pcnorm, center = pc$center, scale  = pc$scale, rotation = pc$rotation)
  }

  if (plot) {
    pcplot <- ggplot2::ggplot(data.frame(cbind(pc$pcnorm, series=1:nrow(pc$pcnorm))), aes_string(x=PC1, y=PC2))+ geom_point()
    print("hi")
    plotly::ggplotly(pcplot)
    print("done")
  }


 class(pc) <- "pcattributes"
  return(pc)

}



