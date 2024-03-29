% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pathnetFoundation.R
\name{pathnetFoundation}
\alias{pathnetFoundation}
\title{Create the foundation for pathway networks using pathway distances}
\usage{
pathnetFoundation(mat, maxDistance = NA, propToKeep = NA)
}
\arguments{
\item{mat}{Matrix of distances between pathways, i.e. 0 means two pathways
are identical. Should match the output from \code{getPathwayDistances}.}

\item{maxDistance}{Numeric distance cutoff (less than or equal) used to
determine if two pathways should share an edge. Pathway pairs with a
distance of 0 are always removed. One of \code{maxDistance} or
\code{propToKeep} must be provided.}

\item{propToKeep}{Top proportion of pathway pairs to keep as edges, ranked
based distance. One of \code{maxDistance} or \code{propToKeep} must be
provided.}
}
\value{
A "data.frame" (tibble) of interacting pathway pairs with the
following columns:
\item{pathwayName1}{Name of the first pathway in the pair}
\item{pathwayName2}{Name of the second pathway in the pair}
\item{distance}{Distance measure for the two pathways}
\item{pathway1}{Reactome ID for the first pathway in the pair}
\item{pathway2}{Reactome ID for the first pathway in the pair}
}
\description{
From a "n by n" distance matrix, generate a table of interacting
pathways to use in constructing a pathway network. The cutoff can be
adjusted to have more or fewer edges in the final network, depending on the
number of pathways involved, i.e. the number of enriched pathways you're
trying to visualize.

The desired cutoff will also vary based on the distance measure used, so
some trial-and-error may be needed to find an appropriate value.
}
\examples{
data("sigoraDatabase")

pathwayDistancesJaccard <- getPathwayDistances(
    pathwayData=dplyr::slice_head(
        dplyr::arrange(sigoraDatabase, pathwayId),
        prop=0.05
    ),
    distMethod="jaccard"
)

startingPathways <- pathnetFoundation(
    mat=pathwayDistancesJaccard,
    maxDistance=0.8
)

}
\references{
None.
}
\seealso{
\url{https://github.com/hancockinformatics/pathlinkR}
}
