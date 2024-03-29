% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{innateDbPPI}
\alias{innateDbPPI}
\title{InnateDB PPI data}
\format{
A data frame (tibble) with 152,256 rows and 2 columns:
\describe{
\item{ensemblGeneA}{Ensembl gene ID for the first gene/protein in the
interaction}
\item{ensemblGeneB}{Ensembl gene ID for the second gene/protein in the
interaction}
}
}
\source{
For more details on the data sourced from InnateDB, please see
their website: \url{https://www.innatedb.com}
}
\usage{
data(innateDbPPI)
}
\value{
An object of class "tbl", "tbl.df", "data.frame"
}
\description{
A data frame containing human PPI data from InnateDB, from the
entry "All Experimentally Validated Interactions (updated weekly)" at
\url{https://innatedb.com/redirect.do?go=downloadImported}. A few important
steps have been taken to filter the data, namely the removal of duplicate
interactions, and removing interactions that have the same components but
are swapped between A and B.
}
\keyword{datasets}
